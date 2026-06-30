// Clean AXI4-to-CacheBus bridge derived from the TVIP prototype.
// The bridge accepts one AXI transaction stream at a time and exposes
// explicit ports so it can be used directly in the FVIP/OSS flow.
// CacheBus has no slot for most AXI sidebands, so only id/addr/len/size/data/strobes
// are consumed by the translation logic below.
module Axi4ToCacheBus (
  input  logic        clock,
  input  logic        reset,
  output logic        io_in_aw_ready,
  input  logic        io_in_aw_valid,
  input  logic [1:0]  io_in_aw_bits_awid,
  input  logic [31:0] io_in_aw_bits_awaddr,
  input  logic [7:0]  io_in_aw_bits_awlen,
  input  logic [2:0]  io_in_aw_bits_awsize,
  input  logic [1:0]  io_in_aw_bits_awburst,
  input  logic        io_in_aw_bits_awlock,
  input  logic [3:0]  io_in_aw_bits_awcache,
  input  logic [2:0]  io_in_aw_bits_awprot,
  output logic        io_in_w_ready,
  input  logic        io_in_w_valid,
  input  logic [31:0] io_in_w_bits_wdata,
  input  logic [3:0]  io_in_w_bits_wstrb,
  input  logic        io_in_w_bits_wlast,
  input  logic        io_in_b_ready,
  output logic        io_in_b_valid,
  output logic [1:0]  io_in_b_bits_bid,
  output logic [1:0]  io_in_b_bits_bresp,
  output logic        io_in_ar_ready,
  input  logic        io_in_ar_valid,
  input  logic [1:0]  io_in_ar_bits_arid,
  input  logic [31:0] io_in_ar_bits_araddr,
  input  logic [7:0]  io_in_ar_bits_arlen,
  input  logic [2:0]  io_in_ar_bits_arsize,
  input  logic [1:0]  io_in_ar_bits_arburst,
  input  logic        io_in_ar_bits_arlock,
  input  logic [3:0]  io_in_ar_bits_arcache,
  input  logic [2:0]  io_in_ar_bits_arprot,
  input  logic        io_in_r_ready,
  output logic        io_in_r_valid,
  output logic [1:0]  io_in_r_bits_rid,
  output logic [31:0] io_in_r_bits_rdata,
  output logic [1:0]  io_in_r_bits_rresp,
  output logic        io_in_r_bits_rlast,
  input  logic        io_out_req_ready,
  output logic        io_out_req_valid,
  output logic [31:0] io_out_req_bits_addr,
  output logic [31:0] io_out_req_bits_data,
  output logic        io_out_req_bits_wen,
  output logic        io_out_req_bits_burst,
  output logic [3:0]  io_out_req_bits_mask,
  output logic [3:0]  io_out_req_bits_len,
  output logic [1:0]  io_out_req_bits_size,
  output logic        io_out_req_bits_last,
  output logic        io_out_rsp_ready,
  input  logic        io_out_rsp_valid,
  input  logic [31:0] io_out_rsp_bits_data,
  input  logic        io_out_rsp_bits_last,
  input  logic        io_out_rsp_bits_err,
  output logic [2:0]  proof_state,
  output logic        proof_aw_pending,
  output logic [7:0]  proof_aw_len,
  output logic [7:0]  proof_write_index,
  output logic        proof_w_buf_valid,
  output logic        proof_w_buf_last,
  output logic        proof_ar_pending,
  output logic [7:0]  proof_ar_len,
  output logic        proof_rsp_last
);

  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
  localparam logic [2:0] AXI_SIZE_4_BYTES = 3'b010;

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_WRITE_WAIT_W,
    ST_WRITE_SEND_REQ,
    ST_WRITE_WAIT_B,
    ST_WRITE_SEND_B,
    ST_READ_SEND_REQ,
    ST_READ_WAIT_RSP,
    ST_READ_SEND_R
  } state_t;

  state_t             state;

  logic               aw_pending;
  logic [1:0]         aw_id;
  logic [31:0]        aw_addr;
  logic [7:0]         aw_len;
  logic [2:0]         aw_size;

  logic               w_buf_valid;
  logic [31:0]        w_buf_data;
  logic [3:0]         w_buf_strb;
  logic               w_buf_last;
  logic [7:0]         write_index;

  logic               ar_pending;
  logic [1:0]         ar_id;
  logic [31:0]        ar_addr;
  logic [7:0]         ar_len;
  logic [2:0]         ar_size;

  logic [1:0]         rsp_id;
  logic [31:0]        rsp_data;
  logic [1:0]         rsp_resp;
  logic               rsp_last;

  logic               aw_fire;
  logic               w_fire;
  logic               ar_fire;
  logic               cb_req_fire;
  logic               cb_rsp_fire;
  logic               b_fire;
  logic               r_fire;
  logic [31:0]        write_addr_offset;

  assign write_addr_offset = {{24{1'b0}}, write_index} << aw_size;

  assign io_in_aw_ready = (state == ST_IDLE) && !aw_pending && !ar_pending;
  assign io_in_w_ready  = (state == ST_WRITE_WAIT_W) && !w_buf_valid && io_out_req_ready;
  assign io_in_ar_ready = (state == ST_IDLE) && !aw_pending && !ar_pending && !io_in_aw_valid;

  assign io_in_b_valid      = (state == ST_WRITE_SEND_B);
  assign io_in_b_bits_bid   = rsp_id;
  assign io_in_b_bits_bresp = rsp_resp;

  assign io_in_r_valid      = (state == ST_READ_SEND_R);
  assign io_in_r_bits_rid   = rsp_id;
  assign io_in_r_bits_rdata = rsp_data;
  assign io_in_r_bits_rresp = rsp_resp;
  assign io_in_r_bits_rlast = rsp_last;

  assign io_out_req_valid      = (state == ST_WRITE_SEND_REQ) || (state == ST_READ_SEND_REQ);
  assign io_out_req_bits_addr  = (state == ST_WRITE_SEND_REQ) ? (aw_addr + write_addr_offset) : ar_addr;
  assign io_out_req_bits_data  = w_buf_data;
  assign io_out_req_bits_wen   = (state == ST_WRITE_SEND_REQ);
  assign io_out_req_bits_burst = ((state == ST_WRITE_SEND_REQ) && (aw_len != 8'h00)) ||
                                 ((state == ST_READ_SEND_REQ)  && (ar_len != 8'h00));
  assign io_out_req_bits_mask  = (state == ST_WRITE_SEND_REQ) ? w_buf_strb : 4'h0;
  assign io_out_req_bits_len   = (state == ST_WRITE_SEND_REQ) ? aw_len[3:0] : ar_len[3:0];
  assign io_out_req_bits_size  = (state == ST_WRITE_SEND_REQ) ? aw_size[1:0] : ar_size[1:0];
  assign io_out_req_bits_last  = (state == ST_WRITE_SEND_REQ) ? w_buf_last : 1'b1;
  assign io_out_rsp_ready      = (state == ST_WRITE_WAIT_B) || (state == ST_READ_WAIT_RSP);

  assign aw_fire     = io_in_aw_valid  && io_in_aw_ready;
  assign w_fire      = io_in_w_valid   && io_in_w_ready;
  assign ar_fire     = io_in_ar_valid  && io_in_ar_ready;
  assign cb_req_fire = io_out_req_valid && io_out_req_ready;
  assign cb_rsp_fire = io_out_rsp_valid && io_out_rsp_ready;
  assign b_fire      = io_in_b_valid   && io_in_b_ready;
  assign r_fire      = io_in_r_valid   && io_in_r_ready;

  always_ff @(posedge clock) begin
    if (reset) begin
      state       <= ST_IDLE;
      aw_pending  <= 1'b0;
      aw_id       <= '0;
      aw_addr     <= '0;
      aw_len      <= '0;
      aw_size     <= AXI_SIZE_4_BYTES;
      w_buf_valid <= 1'b0;
      w_buf_data  <= '0;
      w_buf_strb  <= '0;
      w_buf_last  <= 1'b0;
      write_index <= '0;
      ar_pending  <= 1'b0;
      ar_id       <= '0;
      ar_addr     <= '0;
      ar_len      <= '0;
      ar_size     <= AXI_SIZE_4_BYTES;
      rsp_id      <= '0;
      rsp_data    <= '0;
      rsp_resp    <= AXI_RESP_OKAY;
      rsp_last    <= 1'b0;
    end
    else begin
      if (aw_fire) begin
        aw_pending <= 1'b1;
        aw_id      <= io_in_aw_bits_awid;
        aw_addr    <= io_in_aw_bits_awaddr;
        aw_len     <= io_in_aw_bits_awlen;
        aw_size    <= io_in_aw_bits_awsize;
      end

      if (w_fire && !w_buf_valid) begin
        w_buf_valid <= 1'b1;
        w_buf_data  <= io_in_w_bits_wdata;
        w_buf_strb  <= io_in_w_bits_wstrb;
        w_buf_last  <= io_in_w_bits_wlast;
      end

      if (ar_fire) begin
        ar_pending <= 1'b1;
        ar_id      <= io_in_ar_bits_arid;
        ar_addr    <= io_in_ar_bits_araddr;
        ar_len     <= io_in_ar_bits_arlen;
        ar_size    <= io_in_ar_bits_arsize;
      end

      case (state)
        ST_IDLE: begin
          write_index <= '0;
          if (aw_fire) begin
            state <= ST_WRITE_WAIT_W;
          end
          else if (ar_fire) begin
            state <= ST_READ_SEND_REQ;
          end
        end

        ST_WRITE_WAIT_W: begin
          if (w_buf_valid || w_fire) begin
            state <= ST_WRITE_SEND_REQ;
          end
        end

        ST_WRITE_SEND_REQ: begin
          if (cb_req_fire) begin
            w_buf_valid <= 1'b0;
            if (w_buf_last) begin
              state <= ST_WRITE_WAIT_B;
            end
            else begin
              state <= ST_WRITE_WAIT_W;
            end
          end
          // Only advance write_index when actually completing the transfer
          if (cb_req_fire && !w_buf_last) begin
            write_index <= write_index + 8'h01;
          end
        end

        ST_WRITE_WAIT_B: begin
          if (cb_rsp_fire) begin
            rsp_id      <= aw_id;
            rsp_resp    <= io_out_rsp_bits_err ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
            rsp_last    <= 1'b1;
            aw_pending  <= 1'b0;
            write_index <= '0;
            state       <= ST_WRITE_SEND_B;
          end
        end

        ST_WRITE_SEND_B: begin
          if (b_fire) begin
            state <= ST_IDLE;
          end
        end

        ST_READ_SEND_REQ: begin
          if (cb_req_fire) begin
            state <= ST_READ_WAIT_RSP;
          end
        end

        ST_READ_WAIT_RSP: begin
          if (cb_rsp_fire) begin
            rsp_id   <= ar_id;
            rsp_data <= io_out_rsp_bits_data;
            rsp_resp <= io_out_rsp_bits_err ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
            rsp_last <= io_out_rsp_bits_last;
            state    <= ST_READ_SEND_R;
          end
        end

        ST_READ_SEND_R: begin
          if (r_fire) begin
            if (rsp_last) begin
              ar_pending <= 1'b0;
              state      <= ST_IDLE;
            end
            else begin
              state <= ST_READ_WAIT_RSP;
            end
          end
        end

        default: begin
          state <= ST_IDLE;
        end
      endcase
    end
  end

  assign proof_state = state;
  assign proof_aw_pending = aw_pending;
  assign proof_aw_len = aw_len;
  assign proof_write_index = write_index;
  assign proof_w_buf_valid = w_buf_valid;
  assign proof_w_buf_last = w_buf_last;
  assign proof_ar_pending = ar_pending;
  assign proof_ar_len = ar_len;
  assign proof_rsp_last = rsp_last;

endmodule
