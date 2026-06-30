`default_nettype none

module cl1_axi_source_driver #(
   parameter bit          READ_ONLY  = 1'b0,
   parameter int unsigned FIXED_WRITE_LEN = 16'hffff,
   parameter int unsigned FIXED_READ_LEN  = 16'hffff,
   parameter logic [31:0] WRITE_ADDR = 32'h0000_1000,
   parameter logic [31:0] READ_ADDR  = 32'h0000_2000
) (
   input wire        clock,
   input wire        reset,
   input wire        start,
   output wire       done,

   input wire        aw_ready,
   output wire       aw_valid,
   output wire [1:0] aw_id,
   output wire [31:0] aw_addr,
   output wire [7:0] aw_len,
   output wire [2:0] aw_size,
   output wire [1:0] aw_burst,
   output wire       aw_lock,
   output wire [3:0] aw_cache,
   output wire [2:0] aw_prot,

   input wire        w_ready,
   output wire       w_valid,
   output wire [31:0] w_data,
   output wire [3:0] w_strb,
   output wire       w_last,

   input wire        b_valid,
   input wire [1:0]  b_id,
   input wire [1:0]  b_resp,
   output wire       b_ready,

   input wire        ar_ready,
   output wire       ar_valid,
   output wire [1:0] ar_id,
   output wire [31:0] ar_addr,
   output wire [7:0] ar_len,
   output wire [2:0] ar_size,
   output wire [1:0] ar_burst,
   output wire       ar_lock,
   output wire [3:0] ar_cache,
   output wire [2:0] ar_prot,

   input wire        r_valid,
   input wire [1:0]  r_id,
   input wire [31:0] r_data,
   input wire [1:0]  r_resp,
   input wire        r_last,
   output wire       r_ready,

   output wire       traffic_started,
   output wire [1:0] phase,
   output wire       write_aw_done,
   output wire [3:0] write_req_beat,
   output wire [3:0] read_rsp_beat,
   output wire [3:0] write_burst_len,
   output wire [3:0] read_burst_len,
   output wire [1:0] write_axi_burst,
   output wire [1:0] read_axi_burst,
   output wire [1:0] write_axi_id,
   output wire [1:0] read_axi_id,
   output wire [3:0] write_axi_cache,
   output wire [3:0] read_axi_cache,
   output wire [2:0] write_axi_prot,
   output wire [2:0] read_axi_prot
);

   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
   localparam logic [1:0] PH_READ_REQ  = 2'd2;
   localparam logic [1:0] PH_READ_RSP  = 2'd3;

   (* anyseq *) wire [2:0] f_next_write_burst_len;
   (* anyseq *) wire [2:0] f_next_read_burst_len;

   reg       started_q = 1'b0;
   reg       done_q = 1'b0;
   reg [1:0] phase_q = READ_ONLY ? PH_READ_REQ : PH_WRITE_REQ;
   reg       write_aw_done_q = 1'b0;
   reg [3:0] write_req_beat_q = 4'd0;
   reg [3:0] read_rsp_beat_q = 4'd0;
   reg [3:0] write_burst_len_q = 4'd0;
   reg [3:0] read_burst_len_q = 4'd0;

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire  = w_valid && w_ready;
   wire b_fire  = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire  = r_valid && r_ready;

   assign done = done_q;
   assign traffic_started = started_q;
   assign phase = phase_q;
   assign write_aw_done = write_aw_done_q;
   assign write_req_beat = write_req_beat_q;
   assign read_rsp_beat = read_rsp_beat_q;
   assign write_burst_len = write_burst_len_q;
   assign read_burst_len = read_burst_len_q;
   assign write_axi_burst = INCR;
   assign read_axi_burst = INCR;
   assign write_axi_id = 2'd0;
   assign read_axi_id = 2'd0;
   assign write_axi_cache = 4'd0;
   assign read_axi_cache = 4'd0;
   assign write_axi_prot = 3'd0;
   assign read_axi_prot = 3'd0;

   assign aw_valid = !READ_ONLY && started_q && !done_q &&
                     (phase_q == PH_WRITE_REQ) && !write_aw_done_q;
   assign aw_id = write_axi_id;
   assign aw_addr = WRITE_ADDR;
   assign aw_len = {4'h0, write_burst_len_q};
   assign aw_size = 3'b010;
   assign aw_burst = write_axi_burst;
   assign aw_lock = 1'b0;
   assign aw_cache = write_axi_cache;
   assign aw_prot = write_axi_prot;

   assign w_valid = !READ_ONLY && started_q && !done_q &&
                    (phase_q == PH_WRITE_REQ) && write_aw_done_q;
   assign w_data = WRITE_ADDR ^ {28'h0, write_req_beat_q};
   assign w_strb = 4'hf;
   assign w_last = write_req_beat_q == write_burst_len_q;

   assign b_ready = !READ_ONLY && !reset;

   assign ar_valid = started_q && !done_q && (phase_q == PH_READ_REQ);
   assign ar_id = read_axi_id;
   assign ar_addr = READ_ADDR;
   assign ar_len = {4'h0, read_burst_len_q};
   assign ar_size = 3'b010;
   assign ar_burst = read_axi_burst;
   assign ar_lock = 1'b0;
   assign ar_cache = read_axi_cache;
   assign ar_prot = read_axi_prot;

   assign r_ready = !reset;

   always @(posedge clock) begin
      if (reset) begin
         started_q <= 1'b0;
         done_q <= 1'b0;
         phase_q <= READ_ONLY ? PH_READ_REQ : PH_WRITE_REQ;
         write_aw_done_q <= 1'b0;
         write_req_beat_q <= 4'd0;
         read_rsp_beat_q <= 4'd0;
         write_burst_len_q <= READ_ONLY ? 4'd0 :
                              (FIXED_WRITE_LEN == 16'hffff ? {1'b0, f_next_write_burst_len}
                                                           : FIXED_WRITE_LEN[3:0]);
         read_burst_len_q <= (FIXED_READ_LEN == 16'hffff ? {1'b0, f_next_read_burst_len}
                                                         : FIXED_READ_LEN[3:0]);
      end
      else begin
         if (!started_q && start)
            started_q <= 1'b1;

         if (aw_fire)
            write_aw_done_q <= 1'b1;

         case (phase_q)
            PH_WRITE_REQ:
               if (w_fire) begin
                  if (w_last)
                     phase_q <= PH_WRITE_RSP;
                  else
                     write_req_beat_q <= write_req_beat_q + 4'd1;
               end
            PH_WRITE_RSP:
               if (b_fire) begin
                  phase_q <= PH_READ_REQ;
                  write_aw_done_q <= 1'b0;
                  write_req_beat_q <= 4'd0;
               end
            PH_READ_REQ:
               if (ar_fire) begin
                  read_rsp_beat_q <= 4'd0;
                  phase_q <= PH_READ_RSP;
               end
            PH_READ_RSP:
               if (r_fire && r_last)
                  done_q <= 1'b1;
               else if (r_fire)
                  read_rsp_beat_q <= read_rsp_beat_q + 4'd1;
            default:
               phase_q <= READ_ONLY ? PH_READ_REQ : PH_WRITE_REQ;
         endcase
      end
   end

`ifdef CL1_CROSSBAR_EXTRA_SANITY
   always @(posedge clock) begin
      if (!reset) begin
         ap_cl1_source_b_id_zero: assert (!b_valid || (b_id == 2'd0));
         ap_cl1_source_b_no_exokay: assert (!b_valid || (b_resp != amba_axi4_protocol_checker_pkg::EXOKAY));
         ap_cl1_source_r_id_zero: assert (!r_valid || (r_id == 2'd0));
         ap_cl1_source_r_no_exokay: assert (!r_valid || (r_resp != amba_axi4_protocol_checker_pkg::EXOKAY));
      end
   end
`endif
endmodule

module cl1_crossbar_checker_tb (
   input wire clock,
   input wire reset
);

   localparam int unsigned SOURCE = amba_axi4_protocol_checker_pkg::SOURCE;
   localparam int unsigned DESTINATION = amba_axi4_protocol_checker_pkg::DESTINATION;
   localparam int unsigned AXI4FULL = amba_axi4_protocol_checker_pkg::AXI4FULL;

   reg f_past_valid = 1'b0;
   always @(posedge clock) begin
      f_past_valid <= 1'b1;
      if (!f_past_valid)
         assume(reset);
      else
         assume(!reset);
   end

   wire p0_done, p1_done;

   wire        p0_aw_ready, p0_aw_valid;
   wire [1:0]  p0_aw_id;
   wire [31:0] p0_aw_addr;
   wire [7:0]  p0_aw_len;
   wire [2:0]  p0_aw_size;
   wire [1:0]  p0_aw_burst;
   wire        p0_aw_lock;
   wire [3:0]  p0_aw_cache;
   wire [2:0]  p0_aw_prot;
   wire        p0_w_ready, p0_w_valid;
   wire [31:0] p0_w_data;
   wire [3:0]  p0_w_strb;
   wire        p0_w_last;
   wire        p0_b_valid, p0_b_ready;
   wire [1:0]  p0_b_id, p0_b_resp;
   wire        p0_ar_ready, p0_ar_valid;
   wire [1:0]  p0_ar_id;
   wire [31:0] p0_ar_addr;
   wire [7:0]  p0_ar_len;
   wire [2:0]  p0_ar_size;
   wire [1:0]  p0_ar_burst;
   wire        p0_ar_lock;
   wire [3:0]  p0_ar_cache;
   wire [2:0]  p0_ar_prot;
   wire        p0_r_valid, p0_r_ready;
   wire [1:0]  p0_r_id, p0_r_resp;
   wire [31:0] p0_r_data;
   wire        p0_r_last;

   wire        p1_aw_ready, p1_aw_valid;
   wire [1:0]  p1_aw_id;
   wire [31:0] p1_aw_addr;
   wire [7:0]  p1_aw_len;
   wire [2:0]  p1_aw_size;
   wire [1:0]  p1_aw_burst;
   wire        p1_aw_lock;
   wire [3:0]  p1_aw_cache;
   wire [2:0]  p1_aw_prot;
   wire        p1_w_ready, p1_w_valid;
   wire [31:0] p1_w_data;
   wire [3:0]  p1_w_strb;
   wire        p1_w_last;
   wire        p1_b_valid, p1_b_ready;
   wire [1:0]  p1_b_id, p1_b_resp;
   wire        p1_ar_ready, p1_ar_valid;
   wire [1:0]  p1_ar_id;
   wire [31:0] p1_ar_addr;
   wire [7:0]  p1_ar_len;
   wire [2:0]  p1_ar_size;
   wire [1:0]  p1_ar_burst;
   wire        p1_ar_lock;
   wire [3:0]  p1_ar_cache;
   wire [2:0]  p1_ar_prot;
   wire        p1_r_valid, p1_r_ready;
   wire [1:0]  p1_r_id, p1_r_resp;
   wire [31:0] p1_r_data;
   wire        p1_r_last;

   wire        p0_traffic_started;
   wire [1:0]  p0_phase;
   wire        p0_write_aw_done;
   wire [3:0]  p0_write_req_beat;
   wire [3:0]  p0_read_rsp_beat;
   wire [3:0]  p0_write_burst_len, p0_read_burst_len;
   wire [1:0]  p0_write_axi_burst, p0_read_axi_burst;
   wire [1:0]  p0_write_axi_id, p0_read_axi_id;
   wire [3:0]  p0_write_axi_cache, p0_read_axi_cache;
   wire [2:0]  p0_write_axi_prot, p0_read_axi_prot;
   wire [2:0]  p0_axi2cb_state;
   wire        p0_axi2cb_aw_pending;
   wire [31:0] p0_axi2cb_aw_addr;
   wire [7:0]  p0_axi2cb_aw_len;
   wire [7:0]  p0_axi2cb_write_index;
   wire [31:0] p0_axi2cb_req_addr;
   wire        p0_axi2cb_w_buf_valid;
   wire        p0_axi2cb_w_buf_last;
   wire        p0_axi2cb_ar_pending;
   wire [7:0]  p0_axi2cb_ar_len;
   wire        p0_axi2cb_rsp_last;

   wire        p1_traffic_started;
   wire [1:0]  p1_phase;
   wire        p1_write_aw_done;
   wire [3:0]  p1_write_req_beat;
   wire [3:0]  p1_read_rsp_beat;
   wire [3:0]  p1_write_burst_len, p1_read_burst_len;
   wire [1:0]  p1_write_axi_burst, p1_read_axi_burst;
   wire [1:0]  p1_write_axi_id, p1_read_axi_id;
   wire [3:0]  p1_write_axi_cache, p1_read_axi_cache;
   wire [2:0]  p1_write_axi_prot, p1_read_axi_prot;
   wire [2:0]  p1_axi2cb_state;
   wire        p1_axi2cb_aw_pending;
   wire [31:0] p1_axi2cb_aw_addr;
   wire [7:0]  p1_axi2cb_aw_len;
   wire [7:0]  p1_axi2cb_write_index;
   wire [31:0] p1_axi2cb_req_addr;
   wire        p1_axi2cb_w_buf_valid;
   wire        p1_axi2cb_w_buf_last;
   wire        p1_axi2cb_ar_pending;
   wire [7:0]  p1_axi2cb_ar_len;
   wire        p1_axi2cb_rsp_last;

   cl1_axi_source_driver #(
      .READ_ONLY(1'b1),
      .FIXED_READ_LEN(16'd0),
      .WRITE_ADDR(32'h0000_1000),
      .READ_ADDR(32'h0000_2000)
   ) source0 (
      .clock(clock),
      .reset(reset),
      .start(1'b0),
      .done(p0_done),
      .aw_ready(p0_aw_ready),
      .aw_valid(p0_aw_valid),
      .aw_id(p0_aw_id),
      .aw_addr(p0_aw_addr),
      .aw_len(p0_aw_len),
      .aw_size(p0_aw_size),
      .aw_burst(p0_aw_burst),
      .aw_lock(p0_aw_lock),
      .aw_cache(p0_aw_cache),
      .aw_prot(p0_aw_prot),
      .w_ready(p0_w_ready),
      .w_valid(p0_w_valid),
      .w_data(p0_w_data),
      .w_strb(p0_w_strb),
      .w_last(p0_w_last),
      .b_valid(p0_b_valid),
      .b_id(p0_b_id),
      .b_resp(p0_b_resp),
      .b_ready(p0_b_ready),
      .ar_ready(p0_ar_ready),
      .ar_valid(p0_ar_valid),
      .ar_id(p0_ar_id),
      .ar_addr(p0_ar_addr),
      .ar_len(p0_ar_len),
      .ar_size(p0_ar_size),
      .ar_burst(p0_ar_burst),
      .ar_lock(p0_ar_lock),
      .ar_cache(p0_ar_cache),
      .ar_prot(p0_ar_prot),
      .r_valid(p0_r_valid),
      .r_id(p0_r_id),
      .r_data(p0_r_data),
      .r_resp(p0_r_resp),
      .r_last(p0_r_last),
      .r_ready(p0_r_ready),
      .traffic_started(p0_traffic_started),
      .phase(p0_phase),
      .write_aw_done(p0_write_aw_done),
      .write_req_beat(p0_write_req_beat),
      .read_rsp_beat(p0_read_rsp_beat),
      .write_burst_len(p0_write_burst_len),
      .read_burst_len(p0_read_burst_len),
      .write_axi_burst(p0_write_axi_burst),
      .read_axi_burst(p0_read_axi_burst),
      .write_axi_id(p0_write_axi_id),
      .read_axi_id(p0_read_axi_id),
      .write_axi_cache(p0_write_axi_cache),
      .read_axi_cache(p0_read_axi_cache),
      .write_axi_prot(p0_write_axi_prot),
      .read_axi_prot(p0_read_axi_prot)
   );

   cl1_axi_source_driver #(
      .READ_ONLY(1'b1),
      .FIXED_READ_LEN(16'd0),
      .WRITE_ADDR(32'h0000_3000),
      .READ_ADDR(32'h0000_4000)
   ) source1 (
      .clock(clock),
      .reset(reset),
      .start(!reset),
      .done(p1_done),
      .aw_ready(p1_aw_ready),
      .aw_valid(p1_aw_valid),
      .aw_id(p1_aw_id),
      .aw_addr(p1_aw_addr),
      .aw_len(p1_aw_len),
      .aw_size(p1_aw_size),
      .aw_burst(p1_aw_burst),
      .aw_lock(p1_aw_lock),
      .aw_cache(p1_aw_cache),
      .aw_prot(p1_aw_prot),
      .w_ready(p1_w_ready),
      .w_valid(p1_w_valid),
      .w_data(p1_w_data),
      .w_strb(p1_w_strb),
      .w_last(p1_w_last),
      .b_valid(p1_b_valid),
      .b_id(p1_b_id),
      .b_resp(p1_b_resp),
      .b_ready(p1_b_ready),
      .ar_ready(p1_ar_ready),
      .ar_valid(p1_ar_valid),
      .ar_id(p1_ar_id),
      .ar_addr(p1_ar_addr),
      .ar_len(p1_ar_len),
      .ar_size(p1_ar_size),
      .ar_burst(p1_ar_burst),
      .ar_lock(p1_ar_lock),
      .ar_cache(p1_ar_cache),
      .ar_prot(p1_ar_prot),
      .r_valid(p1_r_valid),
      .r_id(p1_r_id),
      .r_data(p1_r_data),
      .r_resp(p1_r_resp),
      .r_last(p1_r_last),
      .r_ready(p1_r_ready),
      .traffic_started(p1_traffic_started),
      .phase(p1_phase),
      .write_aw_done(p1_write_aw_done),
      .write_req_beat(p1_write_req_beat),
      .read_rsp_beat(p1_read_rsp_beat),
      .write_burst_len(p1_write_burst_len),
      .read_burst_len(p1_read_burst_len),
      .write_axi_burst(p1_write_axi_burst),
      .read_axi_burst(p1_read_axi_burst),
      .write_axi_id(p1_write_axi_id),
      .read_axi_id(p1_read_axi_id),
      .write_axi_cache(p1_write_axi_cache),
      .read_axi_cache(p1_read_axi_cache),
      .write_axi_prot(p1_write_axi_prot),
      .read_axi_prot(p1_read_axi_prot)
   );

   wire        cb0_req_ready, cb0_req_valid;
   wire [31:0] cb0_req_addr, cb0_req_data;
   wire        cb0_req_wen, cb0_req_burst;
   wire [3:0]  cb0_req_mask, cb0_req_len;
   wire [1:0]  cb0_req_size;
   wire        cb0_req_last;
   wire        cb0_rsp_ready, cb0_rsp_valid;
   wire [31:0] cb0_rsp_data;
   wire        cb0_rsp_last, cb0_rsp_err;

   wire        cb1_req_ready, cb1_req_valid;
   wire [31:0] cb1_req_addr, cb1_req_data;
   wire        cb1_req_wen, cb1_req_burst;
   wire [3:0]  cb1_req_mask, cb1_req_len;
   wire [1:0]  cb1_req_size;
   wire        cb1_req_last;
   wire        cb1_rsp_ready, cb1_rsp_valid;
   wire [31:0] cb1_rsp_data;
   wire        cb1_rsp_last, cb1_rsp_err;

   Axi4ToCacheBus axi4_to_cachebus0 (
      .clock(clock),
      .reset(reset),
      .io_in_aw_ready(p0_aw_ready),
      .io_in_aw_valid(p0_aw_valid),
      .io_in_aw_bits_awid(p0_aw_id),
      .io_in_aw_bits_awaddr(p0_aw_addr),
      .io_in_aw_bits_awlen(p0_aw_len),
      .io_in_aw_bits_awsize(p0_aw_size),
      .io_in_aw_bits_awburst(p0_aw_burst),
      .io_in_aw_bits_awlock(p0_aw_lock),
      .io_in_aw_bits_awcache(p0_aw_cache),
      .io_in_aw_bits_awprot(p0_aw_prot),
      .io_in_w_ready(p0_w_ready),
      .io_in_w_valid(p0_w_valid),
      .io_in_w_bits_wdata(p0_w_data),
      .io_in_w_bits_wstrb(p0_w_strb),
      .io_in_w_bits_wlast(p0_w_last),
      .io_in_b_ready(p0_b_ready),
      .io_in_b_valid(p0_b_valid),
      .io_in_b_bits_bid(p0_b_id),
      .io_in_b_bits_bresp(p0_b_resp),
      .io_in_ar_ready(p0_ar_ready),
      .io_in_ar_valid(p0_ar_valid),
      .io_in_ar_bits_arid(p0_ar_id),
      .io_in_ar_bits_araddr(p0_ar_addr),
      .io_in_ar_bits_arlen(p0_ar_len),
      .io_in_ar_bits_arsize(p0_ar_size),
      .io_in_ar_bits_arburst(p0_ar_burst),
      .io_in_ar_bits_arlock(p0_ar_lock),
      .io_in_ar_bits_arcache(p0_ar_cache),
      .io_in_ar_bits_arprot(p0_ar_prot),
      .io_in_r_ready(p0_r_ready),
      .io_in_r_valid(p0_r_valid),
      .io_in_r_bits_rid(p0_r_id),
      .io_in_r_bits_rdata(p0_r_data),
      .io_in_r_bits_rresp(p0_r_resp),
      .io_in_r_bits_rlast(p0_r_last),
      .io_out_req_ready(cb0_req_ready),
      .io_out_req_valid(cb0_req_valid),
      .io_out_req_bits_addr(cb0_req_addr),
      .io_out_req_bits_data(cb0_req_data),
      .io_out_req_bits_wen(cb0_req_wen),
      .io_out_req_bits_burst(cb0_req_burst),
      .io_out_req_bits_mask(cb0_req_mask),
      .io_out_req_bits_len(cb0_req_len),
      .io_out_req_bits_size(cb0_req_size),
      .io_out_req_bits_last(cb0_req_last),
      .io_out_rsp_ready(cb0_rsp_ready),
      .io_out_rsp_valid(cb0_rsp_valid),
      .io_out_rsp_bits_data(cb0_rsp_data),
      .io_out_rsp_bits_last(cb0_rsp_last),
      .io_out_rsp_bits_err(cb0_rsp_err),
      .proof_state(p0_axi2cb_state),
      .proof_aw_pending(p0_axi2cb_aw_pending),
      .proof_aw_addr(p0_axi2cb_aw_addr),
      .proof_aw_len(p0_axi2cb_aw_len),
      .proof_write_index(p0_axi2cb_write_index),
      .proof_req_addr(p0_axi2cb_req_addr),
      .proof_w_buf_valid(p0_axi2cb_w_buf_valid),
      .proof_w_buf_last(p0_axi2cb_w_buf_last),
      .proof_ar_pending(p0_axi2cb_ar_pending),
      .proof_ar_len(p0_axi2cb_ar_len),
      .proof_rsp_last(p0_axi2cb_rsp_last)
   );

   Axi4ToCacheBus axi4_to_cachebus1 (
      .clock(clock),
      .reset(reset),
      .io_in_aw_ready(p1_aw_ready),
      .io_in_aw_valid(p1_aw_valid),
      .io_in_aw_bits_awid(p1_aw_id),
      .io_in_aw_bits_awaddr(p1_aw_addr),
      .io_in_aw_bits_awlen(p1_aw_len),
      .io_in_aw_bits_awsize(p1_aw_size),
      .io_in_aw_bits_awburst(p1_aw_burst),
      .io_in_aw_bits_awlock(p1_aw_lock),
      .io_in_aw_bits_awcache(p1_aw_cache),
      .io_in_aw_bits_awprot(p1_aw_prot),
      .io_in_w_ready(p1_w_ready),
      .io_in_w_valid(p1_w_valid),
      .io_in_w_bits_wdata(p1_w_data),
      .io_in_w_bits_wstrb(p1_w_strb),
      .io_in_w_bits_wlast(p1_w_last),
      .io_in_b_ready(p1_b_ready),
      .io_in_b_valid(p1_b_valid),
      .io_in_b_bits_bid(p1_b_id),
      .io_in_b_bits_bresp(p1_b_resp),
      .io_in_ar_ready(p1_ar_ready),
      .io_in_ar_valid(p1_ar_valid),
      .io_in_ar_bits_arid(p1_ar_id),
      .io_in_ar_bits_araddr(p1_ar_addr),
      .io_in_ar_bits_arlen(p1_ar_len),
      .io_in_ar_bits_arsize(p1_ar_size),
      .io_in_ar_bits_arburst(p1_ar_burst),
      .io_in_ar_bits_arlock(p1_ar_lock),
      .io_in_ar_bits_arcache(p1_ar_cache),
      .io_in_ar_bits_arprot(p1_ar_prot),
      .io_in_r_ready(p1_r_ready),
      .io_in_r_valid(p1_r_valid),
      .io_in_r_bits_rid(p1_r_id),
      .io_in_r_bits_rdata(p1_r_data),
      .io_in_r_bits_rresp(p1_r_resp),
      .io_in_r_bits_rlast(p1_r_last),
      .io_out_req_ready(cb1_req_ready),
      .io_out_req_valid(cb1_req_valid),
      .io_out_req_bits_addr(cb1_req_addr),
      .io_out_req_bits_data(cb1_req_data),
      .io_out_req_bits_wen(cb1_req_wen),
      .io_out_req_bits_burst(cb1_req_burst),
      .io_out_req_bits_mask(cb1_req_mask),
      .io_out_req_bits_len(cb1_req_len),
      .io_out_req_bits_size(cb1_req_size),
      .io_out_req_bits_last(cb1_req_last),
      .io_out_rsp_ready(cb1_rsp_ready),
      .io_out_rsp_valid(cb1_rsp_valid),
      .io_out_rsp_bits_data(cb1_rsp_data),
      .io_out_rsp_bits_last(cb1_rsp_last),
      .io_out_rsp_bits_err(cb1_rsp_err),
      .proof_state(p1_axi2cb_state),
      .proof_aw_pending(p1_axi2cb_aw_pending),
      .proof_aw_addr(p1_axi2cb_aw_addr),
      .proof_aw_len(p1_axi2cb_aw_len),
      .proof_write_index(p1_axi2cb_write_index),
      .proof_req_addr(p1_axi2cb_req_addr),
      .proof_w_buf_valid(p1_axi2cb_w_buf_valid),
      .proof_w_buf_last(p1_axi2cb_w_buf_last),
      .proof_ar_pending(p1_axi2cb_ar_pending),
      .proof_ar_len(p1_axi2cb_ar_len),
      .proof_rsp_last(p1_axi2cb_rsp_last)
   );

   wire        dn_aw_valid, dn_aw_ready;
   wire [31:0] dn_aw_addr;
   wire [1:0]  dn_aw_id;
   wire [7:0]  dn_aw_len;
   wire [2:0]  dn_aw_size;
   wire [1:0]  dn_aw_burst;
   wire        dn_aw_lock;
   wire [3:0]  dn_aw_cache;
   wire [2:0]  dn_aw_prot;
   wire        dn_w_valid, dn_w_ready;
   wire [31:0] dn_w_data;
   wire [3:0]  dn_w_strb;
   wire        dn_w_last;
   wire        dn_b_ready;
   wire        dn_ar_valid, dn_ar_ready;
   wire [31:0] dn_ar_addr;
   wire [1:0]  dn_ar_id;
   wire [7:0]  dn_ar_len;
   wire [2:0]  dn_ar_size;
   wire [1:0]  dn_ar_burst;
   wire        dn_ar_lock;
   wire [3:0]  dn_ar_cache;
   wire [2:0]  dn_ar_prot;
   wire        dn_r_ready;

   reg         dn_aw_ready_q = 1'b0;
   reg         dn_w_ready_q = 1'b0;
   reg         dn_b_valid_q = 1'b0;
   reg [1:0]  dn_b_resp_q = 2'b00;
   reg [1:0]  dn_b_id_q = 2'b00;
   reg         dn_ar_ready_q = 1'b0;
   reg         dn_r_valid_q = 1'b0;
   reg [1:0]  dn_r_resp_q = 2'b00;
   reg [31:0] dn_r_data_q = 32'h1234_5678;
   reg         dn_r_last_q = 1'b0;
   reg [1:0]  dn_r_id_q = 2'b00;

   assign dn_aw_ready = dn_aw_ready_q;
   assign dn_w_ready = dn_w_ready_q;
   assign dn_ar_ready = dn_ar_ready_q;
   wire dn_b_valid = dn_b_valid_q;
   wire [1:0] dn_b_resp = dn_b_resp_q;
   wire [1:0] dn_b_id = dn_b_id_q;
   wire dn_r_valid = dn_r_valid_q;
   wire [1:0] dn_r_resp = dn_r_resp_q;
   wire [31:0] dn_r_data = dn_r_data_q;
   wire dn_r_last = dn_r_last_q;
   wire [1:0] dn_r_id = dn_r_id_q;
   wire [3:0] crossbar_arbiter_req_len;
   wire [3:0] crossbar_arbiter_req_mask;
   wire [1:0] crossbar_arbiter_req_size;
   wire       crossbar_arbiter_req_wen;
   wire       crossbar_arbiter_req_valid;
   wire [3:0] crossbar_buscut_buffer_len;
   wire [3:0] crossbar_buscut_buffer_mask;
   wire [1:0] crossbar_buscut_buffer_size;
   wire       crossbar_buscut_buffer_wen;
   wire       crossbar_buscut_buffer_last;
   wire       crossbar_buscut_buffer_valid;
   wire       crossbar_buscut_rsp_buffer_last;
   wire       crossbar_buscut_rsp_buffer_valid;
   wire [3:0] crossbar_buscut_out_req_len;
   wire [3:0] crossbar_buscut_out_req_mask;
   wire [1:0] crossbar_buscut_out_req_size;
   wire       crossbar_buscut_out_req_wen;
   wire       crossbar_buscut_out_req_last;
   wire       crossbar_buscut_out_req_valid;
   wire       crossbar_buscut_out_req_ready;
   wire [3:0] crossbar_bridge_reqbuf_len;
   wire [3:0] crossbar_bridge_reqbuf_mask;
   wire [1:0] crossbar_bridge_reqbuf_size;
   wire       crossbar_bridge_reqbuf_wen;
   wire       crossbar_bridge_reqbuf_valid;
   wire       crossbar_bridge_reqbuf_last;
   wire       crossbar_bridge_pend_aw;
   wire       crossbar_bridge_pend_w;
   wire       crossbar_bridge_pend_ar;
   wire [1:0] crossbar_arbiter_state;
   wire       crossbar_arbiter_input_sel_0;
   wire       crossbar_arbiter_input_sel_1;
   wire       crossbar_bridge_write_burst_active;

   CrossbarCacheTop dut (
      .clock(clock),
      .reset(reset),
      .io_in_0_req_ready(cb0_req_ready),
      .io_in_0_req_valid(cb0_req_valid),
      .io_in_0_req_bits_addr(cb0_req_addr),
      .io_in_0_req_bits_data(cb0_req_data),
      .io_in_0_req_bits_wen(cb0_req_wen),
      .io_in_0_req_bits_burst(cb0_req_burst),
      .io_in_0_req_bits_mask(cb0_req_mask),
      .io_in_0_req_bits_len(cb0_req_len),
      .io_in_0_req_bits_size(cb0_req_size),
      .io_in_0_req_bits_last(cb0_req_last),
      .io_in_0_rsp_ready(cb0_rsp_ready),
      .io_in_0_rsp_valid(cb0_rsp_valid),
      .io_in_0_rsp_bits_data(cb0_rsp_data),
      .io_in_0_rsp_bits_last(cb0_rsp_last),
      .io_in_0_rsp_bits_err(cb0_rsp_err),
      .io_in_1_req_ready(cb1_req_ready),
      .io_in_1_req_valid(cb1_req_valid),
      .io_in_1_req_bits_addr(cb1_req_addr),
      .io_in_1_req_bits_data(cb1_req_data),
      .io_in_1_req_bits_wen(cb1_req_wen),
      .io_in_1_req_bits_burst(cb1_req_burst),
      .io_in_1_req_bits_mask(cb1_req_mask),
      .io_in_1_req_bits_len(cb1_req_len),
      .io_in_1_req_bits_size(cb1_req_size),
      .io_in_1_req_bits_last(cb1_req_last),
      .io_in_1_rsp_ready(cb1_rsp_ready),
      .io_in_1_rsp_valid(cb1_rsp_valid),
      .io_in_1_rsp_bits_data(cb1_rsp_data),
      .io_in_1_rsp_bits_last(cb1_rsp_last),
      .io_in_1_rsp_bits_err(cb1_rsp_err),
      .io_out_aw_ready(dn_aw_ready),
      .io_out_aw_valid(dn_aw_valid),
      .io_out_aw_bits_awaddr(dn_aw_addr),
      .io_out_aw_bits_awid(dn_aw_id),
      .io_out_aw_bits_awlen(dn_aw_len),
      .io_out_aw_bits_awsize(dn_aw_size),
      .io_out_aw_bits_awburst(dn_aw_burst),
      .io_out_aw_bits_awlock(dn_aw_lock),
      .io_out_aw_bits_awcache(dn_aw_cache),
      .io_out_aw_bits_awprot(dn_aw_prot),
      .io_out_w_ready(dn_w_ready),
      .io_out_w_valid(dn_w_valid),
      .io_out_w_bits_wdata(dn_w_data),
      .io_out_w_bits_wstrb(dn_w_strb),
      .io_out_w_bits_wlast(dn_w_last),
      .io_out_b_ready(dn_b_ready),
      .io_out_b_valid(dn_b_valid),
      .io_out_b_bits_bresp(dn_b_resp),
      .io_out_b_bits_bid(dn_b_id),
      .io_out_ar_ready(dn_ar_ready),
      .io_out_ar_valid(dn_ar_valid),
      .io_out_ar_bits_araddr(dn_ar_addr),
      .io_out_ar_bits_arid(dn_ar_id),
      .io_out_ar_bits_arlen(dn_ar_len),
      .io_out_ar_bits_arsize(dn_ar_size),
      .io_out_ar_bits_arburst(dn_ar_burst),
      .io_out_ar_bits_arlock(dn_ar_lock),
      .io_out_ar_bits_arcache(dn_ar_cache),
      .io_out_ar_bits_arprot(dn_ar_prot),
      .io_out_r_ready(dn_r_ready),
      .io_out_r_valid(dn_r_valid),
      .io_out_r_bits_rresp(dn_r_resp),
      .io_out_r_bits_rdata(dn_r_data),
      .io_out_r_bits_rlast(dn_r_last),
      .io_out_r_bits_rid(dn_r_id),
      .proof_arbiter_state(crossbar_arbiter_state),
      .proof_arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .proof_arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .proof_arbiter_req_len(crossbar_arbiter_req_len),
      .proof_arbiter_req_mask(crossbar_arbiter_req_mask),
      .proof_arbiter_req_size(crossbar_arbiter_req_size),
      .proof_arbiter_req_wen(crossbar_arbiter_req_wen),
      .proof_arbiter_req_valid(crossbar_arbiter_req_valid),
      .proof_buscut_buffer_len(crossbar_buscut_buffer_len),
      .proof_buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .proof_buscut_buffer_size(crossbar_buscut_buffer_size),
      .proof_buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .proof_buscut_buffer_last(crossbar_buscut_buffer_last),
      .proof_buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .proof_buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .proof_buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .proof_buscut_out_req_len(crossbar_buscut_out_req_len),
      .proof_buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .proof_buscut_out_req_size(crossbar_buscut_out_req_size),
      .proof_buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .proof_buscut_out_req_last(crossbar_buscut_out_req_last),
      .proof_buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .proof_buscut_out_req_ready(crossbar_buscut_out_req_ready),
      .proof_bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .proof_bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .proof_bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .proof_bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .proof_bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .proof_bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .proof_bridge_pend_aw(crossbar_bridge_pend_aw),
      .proof_bridge_pend_w(crossbar_bridge_pend_w),
      .proof_bridge_pend_ar(crossbar_bridge_pend_ar),
      .proof_bridge_write_burst_active(crossbar_bridge_write_burst_active)
   );

   wire dn_aw_fire = dn_aw_valid && dn_aw_ready;
   wire dn_w_fire = dn_w_valid && dn_w_ready;
   wire dn_b_fire = dn_b_valid && dn_b_ready;
   wire dn_ar_fire = dn_ar_valid && dn_ar_ready;
   wire dn_r_fire = dn_r_valid && dn_r_ready;

   reg        slave_seen_aw = 1'b0;
   reg        slave_seen_w = 1'b0;
   reg        slave_seen_wlast = 1'b0;
   reg        slave_seen_ar = 1'b0;
   reg [1:0]  saved_aw_id = 2'b00;
   reg [1:0]  saved_ar_id = 2'b00;
   reg [31:0] saved_aw_addr = 32'h0;
   reg [7:0]  saved_aw_len = 8'h00;
   reg [2:0]  saved_aw_size = 3'b000;
   reg [1:0]  saved_aw_burst = 2'b00;
   reg [8:0]  slave_write_beat_count = 9'h000;
   reg [7:0]  read_beats_left = 8'h00;
   wire       slave_read_busy = slave_seen_ar || dn_r_valid;

   always @(posedge clock) begin
      if (reset) begin
         dn_aw_ready_q <= 1'b0;
         dn_w_ready_q <= 1'b0;
         dn_b_valid_q <= 1'b0;
         dn_b_resp_q <= 2'b00;
         dn_b_id_q <= 2'b00;
         dn_ar_ready_q <= 1'b0;
         dn_r_valid_q <= 1'b0;
         dn_r_resp_q <= 2'b00;
         dn_r_data_q <= 32'h1234_5678;
         dn_r_last_q <= 1'b0;
         dn_r_id_q <= 2'b00;
         slave_seen_aw <= 1'b0;
         slave_seen_w <= 1'b0;
         slave_seen_wlast <= 1'b0;
         slave_seen_ar <= 1'b0;
         saved_aw_id <= 2'b00;
         saved_ar_id <= 2'b00;
         saved_aw_addr <= 32'h0;
         saved_aw_len <= 8'h00;
         saved_aw_size <= 3'b000;
         saved_aw_burst <= 2'b00;
         slave_write_beat_count <= 9'h000;
         read_beats_left <= 8'h00;
      end
      else begin
         if (dn_aw_ready_q && dn_aw_valid)
            dn_aw_ready_q <= 1'b0;
         else if (!dn_aw_ready_q && dn_aw_valid)
            dn_aw_ready_q <= 1'b1;
         else
            dn_aw_ready_q <= 1'b0;

         if (dn_w_ready_q && dn_w_valid)
            dn_w_ready_q <= 1'b0;
         else if (!dn_w_ready_q && dn_w_valid)
            dn_w_ready_q <= 1'b1;
         else
            dn_w_ready_q <= 1'b0;

         if (dn_ar_ready_q && dn_ar_valid)
            dn_ar_ready_q <= 1'b0;
         else if (!dn_ar_ready_q && dn_ar_valid && !slave_read_busy)
            dn_ar_ready_q <= 1'b1;
         else
            dn_ar_ready_q <= 1'b0;

         if (dn_aw_fire) begin
            slave_seen_aw <= 1'b1;
            saved_aw_id <= dn_aw_id;
            saved_aw_addr <= dn_aw_addr;
            saved_aw_len <= dn_aw_len;
            saved_aw_size <= dn_aw_size;
            saved_aw_burst <= dn_aw_burst;
         end
         if (dn_w_fire) begin
            slave_seen_w <= 1'b1;
            if (dn_w_last)
               slave_seen_wlast <= 1'b1;
            else
               slave_write_beat_count <= slave_write_beat_count + 9'h001;
         end
         if (dn_ar_fire) begin
            slave_seen_ar <= 1'b1;
            saved_ar_id <= dn_ar_id;
         end

         if (!dn_b_valid_q && ((slave_seen_aw || dn_aw_fire) &&
             (slave_seen_wlast || (dn_w_fire && dn_w_last)))) begin
            dn_b_valid_q <= 1'b1;
            dn_b_resp_q <= 2'b00;
            dn_b_id_q <= dn_aw_fire ? dn_aw_id : saved_aw_id;
         end
         else if (dn_b_fire) begin
            dn_b_valid_q <= 1'b0;
            slave_seen_aw <= 1'b0;
            slave_seen_w <= 1'b0;
            slave_seen_wlast <= 1'b0;
            slave_write_beat_count <= 9'h000;
         end

         if (!dn_r_valid_q && (slave_seen_ar || dn_ar_fire)) begin
            dn_r_valid_q <= 1'b1;
            dn_r_resp_q <= 2'b00;
            dn_r_data_q <= 32'h1234_5678;
            dn_r_last_q <= (dn_ar_fire ? dn_ar_len : read_beats_left) == 8'h00;
            dn_r_id_q <= dn_ar_fire ? dn_ar_id : saved_ar_id;
            read_beats_left <= dn_ar_fire ? dn_ar_len : read_beats_left;
         end
         else if (dn_r_fire && read_beats_left == 8'h00) begin
            dn_r_valid_q <= 1'b0;
            dn_r_last_q <= 1'b0;
            slave_seen_ar <= 1'b0;
         end
         else if (dn_r_fire) begin
            read_beats_left <= read_beats_left - 8'h01;
            dn_r_data_q <= dn_r_data_q + 32'h1;
            dn_r_last_q <= read_beats_left == 8'h01;
         end
      end
   end

   wire        m0_write_dep_aw_seen;
   wire [1:0]  m0_write_dep_awid;
   wire [31:0] m0_write_dep_awaddr;
   wire [7:0]  m0_write_dep_awlen;
   wire [2:0]  m0_write_dep_awsize;
   wire [1:0]  m0_write_dep_awburst;
   wire [8:0]  m0_write_dep_w_count;
   wire        m0_write_dep_w_seen;
   wire        m0_write_dep_wlast_seen;
   wire        m0_read_dep_ar_seen;
   wire [1:0]  m0_read_dep_arid;
   wire [7:0]  m0_read_dep_arlen;
   wire [8:0]  m0_read_dep_r_count;
   wire        m1_write_dep_aw_seen;
   wire [1:0]  m1_write_dep_awid;
   wire [31:0] m1_write_dep_awaddr;
   wire [7:0]  m1_write_dep_awlen;
   wire [2:0]  m1_write_dep_awsize;
   wire [1:0]  m1_write_dep_awburst;
   wire [8:0]  m1_write_dep_w_count;
   wire        m1_write_dep_w_seen;
   wire        m1_write_dep_wlast_seen;
   wire        m1_read_dep_ar_seen;
   wire [1:0]  m1_read_dep_arid;
   wire [7:0]  m1_read_dep_arlen;
   wire [8:0]  m1_read_dep_r_count;
   wire        s_write_dep_aw_seen;
   wire [1:0]  s_write_dep_awid;
   wire [31:0] s_write_dep_awaddr;
   wire [7:0]  s_write_dep_awlen;
   wire [2:0]  s_write_dep_awsize;
   wire [1:0]  s_write_dep_awburst;
   wire [8:0]  s_write_dep_w_count;
   wire        s_write_dep_w_seen;
   wire        s_write_dep_wlast_seen;
   wire        s_read_dep_ar_seen;
   wire [1:0]  s_read_dep_arid;
   wire [7:0]  s_read_dep_arlen;
   wire [8:0]  s_read_dep_r_count;

`define CL1_OSS_CHECKER_PARAMS(AGENT) \
      .ID_WIDTH(2), \
      .ADDRESS_WIDTH(32), \
      .DATA_WIDTH(32), \
      .AWUSER_WIDTH(1), \
      .WUSER_WIDTH(1), \
      .BUSER_WIDTH(1), \
      .ARUSER_WIDTH(1), \
      .RUSER_WIDTH(1), \
      .MAX_WR_BURSTS(1), \
      .MAX_RD_BURSTS(1), \
      .MAX_WR_LENGTH(8), \
      .MAX_RD_LENGTH(8), \
      .MAXWAIT(8), \
      .VERIFY_AGENT_TYPE(AGENT), \
      .PROTOCOL_TYPE(AXI4FULL), \
      .ENABLE_COVER(1'b1), \
      .ENABLE_XPROP(1'b0), \
      .ARM_RECOMMENDED(1'b1), \
      .CHECK_PARAMETERS(1'b1), \
      .OPTIONAL_WSTRB(1'b1), \
      .FULL_WR_STRB(1'b0), \
      .OPTIONAL_RESET(1'b1), \
      .EXCLUSIVE_ACCESS(1'b0)

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_CHECKER_PARAMS(DESTINATION)
   ) master0_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(p0_aw_id), .AWADDR(p0_aw_addr), .AWLEN(p0_aw_len), .AWSIZE(p0_aw_size),
      .AWBURST(p0_aw_burst), .AWLOCK(p0_aw_lock), .AWCACHE(p0_aw_cache),
      .AWPROT(p0_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(p0_aw_valid), .AWREADY(p0_aw_ready),
      .WDATA(p0_w_data), .WSTRB(p0_w_strb), .WLAST(p0_w_last), .WUSER(1'b0),
      .WVALID(p0_w_valid), .WREADY(p0_w_ready),
      .BID(p0_b_id), .BRESP(p0_b_resp), .BUSER(1'b0), .BVALID(p0_b_valid), .BREADY(p0_b_ready),
      .ARID(p0_ar_id), .ARADDR(p0_ar_addr), .ARLEN(p0_ar_len), .ARSIZE(p0_ar_size),
      .ARBURST(p0_ar_burst), .ARLOCK(p0_ar_lock), .ARCACHE(p0_ar_cache),
      .ARPROT(p0_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(p0_ar_valid), .ARREADY(p0_ar_ready),
      .RID(p0_r_id), .RDATA(p0_r_data), .RRESP(p0_r_resp), .RLAST(p0_r_last),
      .RUSER(1'b0), .RVALID(p0_r_valid), .RREADY(p0_r_ready),
      .CSYSREQ(1'b0), .CSYSACK(1'b0), .CACTIVE(1'b0),
      .proof_write_dep_aw_seen(m0_write_dep_aw_seen),
      .proof_write_dep_awid(m0_write_dep_awid),
      .proof_write_dep_awaddr(m0_write_dep_awaddr),
      .proof_write_dep_awlen(m0_write_dep_awlen),
      .proof_write_dep_awsize(m0_write_dep_awsize),
      .proof_write_dep_awburst(m0_write_dep_awburst),
      .proof_write_dep_w_count(m0_write_dep_w_count),
      .proof_write_dep_w_seen(m0_write_dep_w_seen),
      .proof_write_dep_wlast_seen(m0_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(m0_read_dep_ar_seen),
      .proof_read_dep_arid(m0_read_dep_arid),
      .proof_read_dep_arlen(m0_read_dep_arlen),
      .proof_read_dep_r_count(m0_read_dep_r_count)
   );

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_CHECKER_PARAMS(DESTINATION)
   ) master1_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(p1_aw_id), .AWADDR(p1_aw_addr), .AWLEN(p1_aw_len), .AWSIZE(p1_aw_size),
      .AWBURST(p1_aw_burst), .AWLOCK(p1_aw_lock), .AWCACHE(p1_aw_cache),
      .AWPROT(p1_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(p1_aw_valid), .AWREADY(p1_aw_ready),
      .WDATA(p1_w_data), .WSTRB(p1_w_strb), .WLAST(p1_w_last), .WUSER(1'b0),
      .WVALID(p1_w_valid), .WREADY(p1_w_ready),
      .BID(p1_b_id), .BRESP(p1_b_resp), .BUSER(1'b0), .BVALID(p1_b_valid), .BREADY(p1_b_ready),
      .ARID(p1_ar_id), .ARADDR(p1_ar_addr), .ARLEN(p1_ar_len), .ARSIZE(p1_ar_size),
      .ARBURST(p1_ar_burst), .ARLOCK(p1_ar_lock), .ARCACHE(p1_ar_cache),
      .ARPROT(p1_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(p1_ar_valid), .ARREADY(p1_ar_ready),
      .RID(p1_r_id), .RDATA(p1_r_data), .RRESP(p1_r_resp), .RLAST(p1_r_last),
      .RUSER(1'b0), .RVALID(p1_r_valid), .RREADY(p1_r_ready),
      .CSYSREQ(1'b0), .CSYSACK(1'b0), .CACTIVE(1'b0),
      .proof_write_dep_aw_seen(m1_write_dep_aw_seen),
      .proof_write_dep_awid(m1_write_dep_awid),
      .proof_write_dep_awaddr(m1_write_dep_awaddr),
      .proof_write_dep_awlen(m1_write_dep_awlen),
      .proof_write_dep_awsize(m1_write_dep_awsize),
      .proof_write_dep_awburst(m1_write_dep_awburst),
      .proof_write_dep_w_count(m1_write_dep_w_count),
      .proof_write_dep_w_seen(m1_write_dep_w_seen),
      .proof_write_dep_wlast_seen(m1_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(m1_read_dep_ar_seen),
      .proof_read_dep_arid(m1_read_dep_arid),
      .proof_read_dep_arlen(m1_read_dep_arlen),
      .proof_read_dep_r_count(m1_read_dep_r_count)
   );

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_CHECKER_PARAMS(SOURCE)
   ) slave_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(dn_aw_id), .AWADDR(dn_aw_addr), .AWLEN(dn_aw_len), .AWSIZE(dn_aw_size),
      .AWBURST(dn_aw_burst), .AWLOCK(dn_aw_lock), .AWCACHE(dn_aw_cache),
      .AWPROT(dn_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(dn_aw_valid), .AWREADY(dn_aw_ready),
      .WDATA(dn_w_data), .WSTRB(dn_w_strb), .WLAST(dn_w_last), .WUSER(1'b0),
      .WVALID(dn_w_valid), .WREADY(dn_w_ready),
      .BID(dn_b_id), .BRESP(dn_b_resp), .BUSER(1'b0), .BVALID(dn_b_valid), .BREADY(dn_b_ready),
      .ARID(dn_ar_id), .ARADDR(dn_ar_addr), .ARLEN(dn_ar_len), .ARSIZE(dn_ar_size),
      .ARBURST(dn_ar_burst), .ARLOCK(dn_ar_lock), .ARCACHE(dn_ar_cache),
      .ARPROT(dn_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(dn_ar_valid), .ARREADY(dn_ar_ready),
      .RID(dn_r_id), .RDATA(dn_r_data), .RRESP(dn_r_resp), .RLAST(dn_r_last),
      .RUSER(1'b0), .RVALID(dn_r_valid), .RREADY(dn_r_ready),
      .CSYSREQ(1'b0), .CSYSACK(1'b0), .CACTIVE(1'b0),
      .proof_write_dep_aw_seen(s_write_dep_aw_seen),
      .proof_write_dep_awid(s_write_dep_awid),
      .proof_write_dep_awaddr(s_write_dep_awaddr),
      .proof_write_dep_awlen(s_write_dep_awlen),
      .proof_write_dep_awsize(s_write_dep_awsize),
      .proof_write_dep_awburst(s_write_dep_awburst),
      .proof_write_dep_w_count(s_write_dep_w_count),
      .proof_write_dep_w_seen(s_write_dep_w_seen),
      .proof_write_dep_wlast_seen(s_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(s_read_dep_ar_seen),
      .proof_read_dep_arid(s_read_dep_arid),
      .proof_read_dep_arlen(s_read_dep_arlen),
      .proof_read_dep_r_count(s_read_dep_r_count)
   );

`undef CL1_OSS_CHECKER_PARAMS

   cl1_oss_source_driver_unreachable_invariants #(
      .ID_WIDTH(2),
      .ADDRESS_WIDTH(32),
      .READ_ONLY(1'b1),
      .NEVER_START(1'b1)
   ) source0_invariants (
      .clock(clock), .reset(reset), .traffic_started(p0_traffic_started),
      .done(p0_done),
      .phase(p0_phase), .write_aw_done(p0_write_aw_done),
      .write_req_beat(p0_write_req_beat), .read_rsp_beat(p0_read_rsp_beat),
      .write_burst_len(p0_write_burst_len),
      .read_burst_len(p0_read_burst_len), .write_axi_burst(p0_write_axi_burst),
      .read_axi_burst(p0_read_axi_burst), .write_axi_id(p0_write_axi_id),
      .read_axi_id(p0_read_axi_id), .write_axi_cache(p0_write_axi_cache),
      .read_axi_cache(p0_read_axi_cache), .write_axi_prot(p0_write_axi_prot),
      .read_axi_prot(p0_read_axi_prot), .up_aw_addr(p0_aw_addr),
      .up_aw_len(p0_aw_len), .up_aw_size(p0_aw_size),
      .m_write_dep_awid(m0_write_dep_awid), .m_write_dep_aw_seen(m0_write_dep_aw_seen),
      .m_write_dep_awaddr(m0_write_dep_awaddr), .m_write_dep_awlen(m0_write_dep_awlen),
      .m_write_dep_awsize(m0_write_dep_awsize), .m_write_dep_awburst(m0_write_dep_awburst),
      .m_write_dep_w_count(m0_write_dep_w_count), .m_write_dep_w_seen(m0_write_dep_w_seen),
      .m_write_dep_wlast_seen(m0_write_dep_wlast_seen),
      .m_read_dep_ar_seen(m0_read_dep_ar_seen),
      .m_read_dep_arid(m0_read_dep_arid),
      .m_read_dep_arlen(m0_read_dep_arlen),
      .m_read_dep_r_count(m0_read_dep_r_count),
      .b_valid(p0_b_valid),
      .b_id(p0_b_id),
      .b_resp(p0_b_resp),
      .r_valid(p0_r_valid),
      .r_id(p0_r_id),
      .r_resp(p0_r_resp)
   );

   cl1_oss_source_driver_unreachable_invariants #(
      .ID_WIDTH(2),
      .ADDRESS_WIDTH(32),
      .READ_ONLY(1'b1),
      .NEVER_START(1'b0)
   ) source1_invariants (
      .clock(clock), .reset(reset), .traffic_started(p1_traffic_started),
      .done(p1_done),
      .phase(p1_phase), .write_aw_done(p1_write_aw_done),
      .write_req_beat(p1_write_req_beat), .read_rsp_beat(p1_read_rsp_beat),
      .write_burst_len(p1_write_burst_len),
      .read_burst_len(p1_read_burst_len), .write_axi_burst(p1_write_axi_burst),
      .read_axi_burst(p1_read_axi_burst), .write_axi_id(p1_write_axi_id),
      .read_axi_id(p1_read_axi_id), .write_axi_cache(p1_write_axi_cache),
      .read_axi_cache(p1_read_axi_cache), .write_axi_prot(p1_write_axi_prot),
      .read_axi_prot(p1_read_axi_prot), .up_aw_addr(p1_aw_addr),
      .up_aw_len(p1_aw_len), .up_aw_size(p1_aw_size),
      .m_write_dep_awid(m1_write_dep_awid), .m_write_dep_aw_seen(m1_write_dep_aw_seen),
      .m_write_dep_awaddr(m1_write_dep_awaddr), .m_write_dep_awlen(m1_write_dep_awlen),
      .m_write_dep_awsize(m1_write_dep_awsize), .m_write_dep_awburst(m1_write_dep_awburst),
      .m_write_dep_w_count(m1_write_dep_w_count), .m_write_dep_w_seen(m1_write_dep_w_seen),
      .m_write_dep_wlast_seen(m1_write_dep_wlast_seen),
      .m_read_dep_ar_seen(m1_read_dep_ar_seen),
      .m_read_dep_arid(m1_read_dep_arid),
      .m_read_dep_arlen(m1_read_dep_arlen),
      .m_read_dep_r_count(m1_read_dep_r_count),
      .b_valid(p1_b_valid),
      .b_id(p1_b_id),
      .b_resp(p1_b_resp),
      .r_valid(p1_r_valid),
      .r_id(p1_r_id),
      .r_resp(p1_r_resp)
   );

   cl1_oss_slave_model_unreachable_invariants #(
      .ID_WIDTH(2)
   ) slave_model_invariants (
      .clock(clock), .reset(reset), .no_slave_read_expected(p1_done),
      .slave_seen_aw(slave_seen_aw), .slave_seen_w(slave_seen_w),
      .slave_seen_wlast(slave_seen_wlast),
      .slave_seen_ar(slave_seen_ar), .saved_aw_id(saved_aw_id),
      .saved_ar_id(saved_ar_id),
      .saved_aw_addr(saved_aw_addr), .saved_aw_len(saved_aw_len),
      .saved_aw_size(saved_aw_size), .saved_aw_burst(saved_aw_burst),
      .slave_write_beat_count(slave_write_beat_count),
      .read_beats_left(read_beats_left),
      .dn_aw_len(dn_aw_len),
      .dn_w_valid(dn_w_valid),
      .dn_w_last(dn_w_last),
      .dn_b_valid(dn_b_valid),
      .dn_b_id(dn_b_id), .dn_ar_valid(dn_ar_valid),
      .dn_ar_ready(dn_ar_ready), .dn_r_valid(dn_r_valid),
      .dn_r_last(dn_r_last), .slave_read_busy(slave_read_busy),
      .s_write_dep_aw_seen(s_write_dep_aw_seen), .s_write_dep_awid(s_write_dep_awid),
      .s_write_dep_awaddr(s_write_dep_awaddr),
      .s_write_dep_awlen(s_write_dep_awlen), .s_write_dep_awsize(s_write_dep_awsize),
      .s_write_dep_awburst(s_write_dep_awburst),
      .s_write_dep_w_count(s_write_dep_w_count),
      .s_write_dep_w_seen(s_write_dep_w_seen),
      .s_write_dep_wlast_seen(s_write_dep_wlast_seen),
      .s_read_dep_ar_seen(s_read_dep_ar_seen),
      .s_read_dep_arid(s_read_dep_arid),
      .s_read_dep_arlen(s_read_dep_arlen),
      .s_read_dep_r_count(s_read_dep_r_count)
   );

   cl1_oss_cachebus_len_unreachable_invariants cachebus_len_invariants (
      .clock(clock),
      .reset(reset),
      .source0_req_valid(cb0_req_valid),
      .source0_req_len(cb0_req_len),
      .source0_req_size(cb0_req_size),
      .source1_req_valid(cb1_req_valid),
      .source1_req_len(cb1_req_len),
      .source1_req_size(cb1_req_size),
      .arbiter_state(crossbar_arbiter_state),
      .arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .arbiter_req_valid(crossbar_arbiter_req_valid),
      .arbiter_req_len(crossbar_arbiter_req_len),
      .arbiter_req_mask(crossbar_arbiter_req_mask),
      .arbiter_req_size(crossbar_arbiter_req_size),
      .arbiter_req_wen(crossbar_arbiter_req_wen),
      .buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .buscut_buffer_len(crossbar_buscut_buffer_len),
      .buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .buscut_buffer_size(crossbar_buscut_buffer_size),
      .buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .buscut_buffer_last(crossbar_buscut_buffer_last),
      .buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .buscut_out_req_len(crossbar_buscut_out_req_len),
      .buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .buscut_out_req_size(crossbar_buscut_out_req_size),
      .buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .buscut_out_req_last(crossbar_buscut_out_req_last),
      .bridge_write_burst_active(crossbar_bridge_write_burst_active),
      .bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .bridge_pend_aw(crossbar_bridge_pend_aw),
      .bridge_pend_w(crossbar_bridge_pend_w),
      .bridge_pend_ar(crossbar_bridge_pend_ar),
      .slave_seen_ar(slave_seen_ar)
   );

   cl1_oss_axi4_to_cachebus_source_unreachable_invariants axi2cb0_invariants (
      .clock(clock),
      .reset(reset),
      .source_phase(p0_phase),
      .source_write_aw_done(p0_write_aw_done),
      .source_write_req_beat(p0_write_req_beat),
      .source_read_rsp_beat(p0_read_rsp_beat),
      .source_write_burst_len(p0_write_burst_len),
      .source_read_burst_len(p0_read_burst_len),
      .up_aw_addr(p0_aw_addr),
      .source_up_aw_size(p0_aw_size),
      .bridge_state(p0_axi2cb_state),
      .bridge_aw_pending(p0_axi2cb_aw_pending),
      .bridge_aw_addr(p0_axi2cb_aw_addr),
      .bridge_aw_len(p0_axi2cb_aw_len),
      .bridge_write_index(p0_axi2cb_write_index),
      .bridge_req_addr(p0_axi2cb_req_addr),
      .bridge_w_buf_valid(p0_axi2cb_w_buf_valid),
      .bridge_w_buf_last(p0_axi2cb_w_buf_last),
      .bridge_ar_pending(p0_axi2cb_ar_pending),
      .bridge_ar_len(p0_axi2cb_ar_len),
      .bridge_rsp_last(p0_axi2cb_rsp_last),
      .bridge_in_rsp_valid(cb0_rsp_valid),
      .bridge_in_rsp_last(cb0_rsp_last),
      .m_read_dep_ar_seen(m0_read_dep_ar_seen),
      .m_read_dep_arlen(m0_read_dep_arlen),
      .m_read_dep_r_count(m0_read_dep_r_count)
   );

   cl1_oss_axi4_to_cachebus_source_unreachable_invariants axi2cb1_invariants (
      .clock(clock),
      .reset(reset),
      .source_phase(p1_phase),
      .source_write_aw_done(p1_write_aw_done),
      .source_write_req_beat(p1_write_req_beat),
      .source_read_rsp_beat(p1_read_rsp_beat),
      .source_write_burst_len(p1_write_burst_len),
      .source_read_burst_len(p1_read_burst_len),
      .up_aw_addr(p1_aw_addr),
      .source_up_aw_size(p1_aw_size),
      .bridge_state(p1_axi2cb_state),
      .bridge_aw_pending(p1_axi2cb_aw_pending),
      .bridge_aw_addr(p1_axi2cb_aw_addr),
      .bridge_aw_len(p1_axi2cb_aw_len),
      .bridge_write_index(p1_axi2cb_write_index),
      .bridge_req_addr(p1_axi2cb_req_addr),
      .bridge_w_buf_valid(p1_axi2cb_w_buf_valid),
      .bridge_w_buf_last(p1_axi2cb_w_buf_last),
      .bridge_ar_pending(p1_axi2cb_ar_pending),
      .bridge_ar_len(p1_axi2cb_ar_len),
      .bridge_rsp_last(p1_axi2cb_rsp_last),
      .bridge_in_rsp_valid(cb1_rsp_valid),
      .bridge_in_rsp_last(cb1_rsp_last),
      .m_read_dep_ar_seen(m1_read_dep_ar_seen),
      .m_read_dep_arlen(m1_read_dep_arlen),
      .m_read_dep_r_count(m1_read_dep_r_count)
   );

   cl1_oss_crossbar_read_pipeline_unreachable_invariants crossbar_read_pipeline_invariants (
      .clock(clock),
      .reset(reset),
      .source0_r_valid(p0_r_valid),
      .source0_r_ready(p0_r_ready),
      .source0_r_last(p0_r_last),
      .source0_read_rsp_beat(p0_read_rsp_beat),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_last(p1_r_last),
      .source1_read_rsp_beat(p1_read_rsp_beat),
      .cb0_rsp_valid(cb0_rsp_valid),
      .cb0_rsp_last(cb0_rsp_last),
      .cb1_rsp_valid(cb1_rsp_valid),
      .cb1_rsp_last(cb1_rsp_last),
      .buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .dn_r_valid(dn_r_valid),
      .dn_r_ready(dn_r_ready),
      .dn_r_last(dn_r_last),
      .slave_seen_ar(slave_seen_ar),
      .s_read_dep_ar_seen(s_read_dep_ar_seen),
      .s_read_dep_r_count(s_read_dep_r_count)
   );

   always @(posedge clock) begin
      if (!reset) begin
         cv_source0_aw_fire: cover(p0_aw_valid && p0_aw_ready);
         cv_source1_aw_fire: cover(p1_aw_valid && p1_aw_ready);
         cv_source0_done: cover(p0_done);
         cv_source1_done: cover(p1_done);
         cv_crossbar_output_aw_fire: cover(dn_aw_fire);
         cv_crossbar_output_ar_fire: cover(dn_ar_fire);
         cv_crossbar_output_r_last: cover(dn_r_fire && dn_r_last);
      end
   end
endmodule

`default_nettype wire
