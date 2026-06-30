/*  AXI4 Formal Properties.
 *
 *  CL1-specialized OSS write response dependency checker.
 *
 *  This module is the CL1-profile OSS write-response dependency checker. It
 *  keeps the converted checker hierarchy and observable signals while removing
 *  AXI4 modes outside the CL1 profile:
 *  multi-outstanding, W-before-AW buffering, FIXED/WRAP bursts, wide data,
 *  and non-zero IDs.
 */
`default_nettype none

module amba_axi4_write_response_dependencies_cl1_oss #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 64,
   parameter int unsigned MAX_WR_BURSTS = 4,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAX_WR_LENGTH = 8,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE
) (
   input wire                         ACLK,
   input wire                         ARESETn,
   input wire [ID_WIDTH-1:0]          AWID,
   input wire [ID_WIDTH-1:0]          BID,
   input wire [ADDRESS_WIDTH-1:0]     AWADDR,
   input wire [7:0]                   AWLEN,
   input wire [2:0]                   AWSIZE,
   input wire [1:0]                   AWBURST,
   input wire [(DATA_WIDTH/8)-1:0]    WSTRB,
   input wire                         BVALID,
   input wire                         BREADY,
   input wire                         AWVALID,
   input wire                         AWREADY,
   input wire                         WVALID,
   input wire                         WREADY,
   input wire                         WLAST,
   output wire                        proof_aw_seen,
   output wire [ID_WIDTH-1:0]         proof_awid,
   output wire [ADDRESS_WIDTH-1:0]    proof_awaddr,
   output wire [7:0]                  proof_awlen,
   output wire [2:0]                  proof_awsize,
   output wire [1:0]                  proof_awburst,
   output wire [8:0]                  proof_w_count,
   output wire                        proof_w_seen,
   output wire                        proof_wlast_seen
);

   localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8;
   localparam int unsigned WR_MAX_BEATS = MAX_WR_LENGTH < 1 ? 1 :
                                          (MAX_WR_LENGTH > 256 ? 256 : MAX_WR_LENGTH);
   localparam int unsigned WR_CNTW = MAX_WR_BURSTS < 2 ? 1 : $clog2(MAX_WR_BURSTS);
   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [2:0] SIZE1B = amba_axi4_protocol_checker_pkg::SIZE1B;
   localparam logic [2:0] SIZE2B = amba_axi4_protocol_checker_pkg::SIZE2B;
   localparam logic [2:0] SIZE4B = amba_axi4_protocol_checker_pkg::SIZE4B;
   localparam int unsigned SOURCE = amba_axi4_protocol_checker_pkg::SOURCE;
   localparam int unsigned DESTINATION = amba_axi4_protocol_checker_pkg::DESTINATION;
   localparam int unsigned MONITOR = amba_axi4_protocol_checker_pkg::MONITOR;
   localparam int unsigned CONSTRAINT = amba_axi4_protocol_checker_pkg::CONSTRAINT;

   logic [WR_CNTW:0] outstandingAW;
   logic [WR_CNTW:0] outstandingW;

   logic aw_fire;
   logic w_fire;
   logic b_fire;

   logic b_aw_match;
   logic b_wlast_match;
   logic b_wstrb_error;
   logic wstrb_context_valid;
   logic wstrb_context_error;
   logic wdata_num_error;
   logic wdata_num_state_error;
   logic wdata_num_valid_error;

   logic aw_seen_q, aw_seen_d;
   logic [ID_WIDTH-1:0] awid_q, awid_d;
   logic [ADDRESS_WIDTH-1:0] awaddr_q, awaddr_d;
   logic [7:0] awlen_q, awlen_d;
   logic [2:0] awsize_q, awsize_d;
   logic [1:0] awburst_q, awburst_d;
   logic [8:0] w_count_q, w_count_d;
   logic w_seen_q, w_seen_d;
   logic wlast_seen_q, wlast_seen_d;
   logic wstrb_error_q, wstrb_error_d;

   assign aw_fire = AWVALID && AWREADY;
   assign w_fire  = WVALID && WREADY;
   assign b_fire  = BVALID && BREADY;

   assign outstandingAW = {{WR_CNTW{1'b0}}, aw_seen_q};
   assign outstandingW = {{WR_CNTW{1'b0}}, aw_seen_q || w_seen_q};
   assign proof_aw_seen = aw_seen_q;
   assign proof_awid = awid_q;
   assign proof_awaddr = awaddr_q;
   assign proof_awlen = awlen_q;
   assign proof_awsize = awsize_q;
   assign proof_awburst = awburst_q;
   assign proof_w_count = w_count_q;
   assign proof_w_seen = w_seen_q;
   assign proof_wlast_seen = wlast_seen_q;

   function automatic logic [STRB_WIDTH-1:0] legal_wstrb_mask_cl1
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [8:0] beat);
      logic [ADDRESS_WIDTH-1:0] beat_addr;
      logic [3:0] mask4;
      begin
         beat_addr = addr + ({{(ADDRESS_WIDTH-9){1'b0}}, beat} << size);
         mask4 = 4'h0;

         case(size)
           SIZE1B: mask4 = 4'b0001 << beat_addr[1:0];
           SIZE2B: mask4 = 4'b0011 << {beat_addr[1], 1'b0};
           SIZE4B: mask4 = 4'b1111;
         default: mask4 = 4'h0;
         endcase

         legal_wstrb_mask_cl1 = '0;
         for(int i = 0; i < STRB_WIDTH; i++) begin
            if(i < 4) begin
               legal_wstrb_mask_cl1[i] = mask4[i];
            end
         end
      end
   endfunction

   function automatic logic wstrb_has_illegal_lane_cl1
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [8:0] beat,
      input logic [STRB_WIDTH-1:0] strb);
      if((STRB_WIDTH == 4) && (burst == INCR) && (size <= SIZE4B) &&
         (beat < WR_MAX_BEATS)) begin
         wstrb_has_illegal_lane_cl1 =
           |(strb & ~legal_wstrb_mask_cl1(addr, size, beat));
      end
      else begin
         wstrb_has_illegal_lane_cl1 = 1'b1;
      end
   endfunction

   always_comb begin
      b_aw_match = aw_seen_q && (BID == awid_q);
      b_wlast_match = b_aw_match && wlast_seen_q;
      b_wstrb_error = b_aw_match && wstrb_error_q;
      wstrb_context_valid = aw_seen_q && w_seen_q;
      wstrb_context_error = wstrb_error_q;
   end

   always_comb begin
      wdata_num_valid_error = 1'b0;

      if(WVALID) begin
         if(wlast_seen_q) begin
            wdata_num_valid_error = 1'b1;
         end
         else if(aw_seen_q) begin
            wdata_num_valid_error = WLAST != (w_count_q == {1'b0, awlen_q});
         end
         else if(AWVALID) begin
            wdata_num_valid_error = WLAST != (9'h0 == {1'b0, AWLEN});
         end
         else begin
            wdata_num_valid_error = 1'b1;
         end
      end

      if(AWVALID && aw_seen_q && !(b_fire && b_aw_match && b_wlast_match)) begin
         wdata_num_valid_error = 1'b1;
      end
   end

   always_ff @(posedge ACLK or negedge ARESETn) begin
      if(!ARESETn) begin
         aw_seen_q <= 1'b0;
         awid_q <= '0;
         awaddr_q <= '0;
         awlen_q <= '0;
         awsize_q <= '0;
         awburst_q <= '0;
         w_count_q <= '0;
         w_seen_q <= 1'b0;
         wlast_seen_q <= 1'b0;
         wstrb_error_q <= 1'b0;
      end
      else begin
         aw_seen_q <= aw_seen_d;
         awid_q <= awid_d;
         awaddr_q <= awaddr_d;
         awlen_q <= awlen_d;
         awsize_q <= awsize_d;
         awburst_q <= awburst_d;
         w_count_q <= w_count_d;
         w_seen_q <= w_seen_d;
         wlast_seen_q <= wlast_seen_d;
         wstrb_error_q <= wstrb_error_d;
      end
   end

   always_comb begin
      aw_seen_d = aw_seen_q;
      awid_d = awid_q;
      awaddr_d = awaddr_q;
      awlen_d = awlen_q;
      awsize_d = awsize_q;
      awburst_d = awburst_q;
      w_count_d = w_count_q;
      w_seen_d = w_seen_q;
      wlast_seen_d = wlast_seen_q;
      wstrb_error_d = wstrb_error_q;
      wdata_num_state_error = 1'b0;

      if(b_fire && b_aw_match && b_wlast_match) begin
         aw_seen_d = 1'b0;
         awid_d = '0;
         awaddr_d = '0;
         awlen_d = '0;
         awsize_d = '0;
         awburst_d = '0;
         w_count_d = '0;
         w_seen_d = 1'b0;
         wlast_seen_d = 1'b0;
         wstrb_error_d = 1'b0;
      end

      if(aw_fire) begin
         if(aw_seen_d) begin
            wdata_num_state_error = 1'b1;
         end
         else begin
            aw_seen_d = 1'b1;
            awid_d = AWID;
            awaddr_d = AWADDR;
            awlen_d = AWLEN;
            awsize_d = AWSIZE;
            awburst_d = AWBURST;
            w_count_d = '0;
            w_seen_d = 1'b0;
            wlast_seen_d = 1'b0;
            wstrb_error_d = 1'b0;
         end
      end

      if(w_fire) begin
         if(!aw_seen_d || wlast_seen_d) begin
            wdata_num_state_error = 1'b1;
         end
         else begin
            if(w_count_d < WR_MAX_BEATS) begin
               wstrb_error_d =
                 wstrb_error_d ||
                 wstrb_has_illegal_lane_cl1(awaddr_d, awsize_d, awburst_d,
                                            w_count_d, WSTRB);
            end
            else begin
               wstrb_error_d = 1'b1;
            end

            if(WLAST) begin
               wdata_num_state_error =
                 wdata_num_state_error || (w_count_d != {1'b0, awlen_d});
               wlast_seen_d = 1'b1;
            end
            else begin
               wdata_num_state_error =
                 wdata_num_state_error || (w_count_d >= {1'b0, awlen_d});
               w_count_d = w_count_d + 1'b1;
            end

            w_seen_d = 1'b1;
         end
      end

      wdata_num_error = wdata_num_state_error || wdata_num_valid_error;
   end

   generate
      if(VERIFY_AGENT_TYPE == DESTINATION || VERIFY_AGENT_TYPE == MONITOR) begin: forward_progress_AW
         always @(posedge ACLK) begin
            if(ARESETn) begin
               ap_no_overflow: assert (!(AWVALID) ||
                                        (!aw_seen_q ||
                                         (b_fire && b_aw_match && b_wlast_match)));
            end
         end
      end
      else begin: forward_progress_AW
         always @(posedge ACLK) begin
            if(ARESETn) begin
               cp_no_overflow_no_dead_end:
                  assume (!(aw_seen_q && !(b_fire && b_aw_match && b_wlast_match)) ||
                          (!AWVALID));
            end
         end
      end
   endgenerate

   generate
      if(VERIFY_AGENT_TYPE == DESTINATION || VERIFY_AGENT_TYPE == MONITOR) begin: write_response_assertions
         always @(posedge ACLK) begin
            if(ARESETn) begin
               ap_BRESP_AW: assert (!(BVALID) || (b_aw_match));
               ap_BRESP_WLAST: assert (!(BVALID) ||
                                        (b_aw_match && b_wlast_match));
            end
         end
      end
      else begin: write_response_constraints
         always @(posedge ACLK) begin
            if(ARESETn) begin
               cp_BRESP_AW: assume (!(BVALID) || (b_aw_match));
               cp_BRESP_WLAST: assume (!(BVALID) ||
                                        (b_aw_match && b_wlast_match));
            end
         end
      end
   endgenerate

   generate
      if(VERIFY_AGENT_TYPE == SOURCE || VERIFY_AGENT_TYPE == MONITOR) begin: write_data_count_assertions
         always @(posedge ACLK) begin
            if(ARESETn) begin
               ap_WDATA_NUM: assert (!wdata_num_error);
            end
         end
      end
      else begin: write_data_count_constraints
         always @(posedge ACLK) begin
            if(ARESETn) begin
               cp_WDATA_NUM: assume (!wdata_num_error);
            end
         end
      end
   endgenerate

   generate
      if(VERIFY_AGENT_TYPE == SOURCE || VERIFY_AGENT_TYPE == MONITOR) begin: write_strobe_assertions
         always @(posedge ACLK) begin
            if(ARESETn) begin
               ap_WSTRB_MATCHES_AW_CONTEXT: assert (!(wstrb_context_valid) ||
                                                    (!wstrb_context_error));
            end
         end
      end
      else begin: write_strobe_constraints
         always @(posedge ACLK) begin
            if(ARESETn) begin
               cp_WSTRB_MATCHES_AW_CONTEXT: assume (!(wstrb_context_valid) ||
                                                    (!wstrb_context_error));
            end
	      end
	   end
	endgenerate

   always @(posedge ACLK) begin
      if(ARESETn) begin
         ap_cl1_write_dep_idle_state_clear:
            assert (aw_seen_q ||
                    (!w_seen_q && !wlast_seen_q && (w_count_q == '0) &&
                     !wstrb_error_q));
         ap_cl1_write_dep_w_seen_requires_aw:
            assert (!w_seen_q || aw_seen_q);
         ap_cl1_write_dep_wlast_requires_w_seen:
            assert (!wlast_seen_q || w_seen_q);
         ap_cl1_write_dep_wlast_count_matches_awlen:
            assert (!wlast_seen_q || (w_count_q == {1'b0, awlen_q}));
         ap_cl1_write_dep_count_within_awlen:
            assert (!aw_seen_q || (w_count_q <= {1'b0, awlen_q}));
         ap_cl1_write_dep_awlen_within_cl1_max:
            assert (!aw_seen_q || (awlen_q < WR_MAX_BEATS));
         ap_cl1_write_dep_no_wstrb_error:
            assert (!wstrb_error_q);
      end
   end

   wire unused_cl1_parameters = (MAX_RD_BURSTS == 0) ^ (PROTOCOL_TYPE == 0);
endmodule

`default_nettype wire
