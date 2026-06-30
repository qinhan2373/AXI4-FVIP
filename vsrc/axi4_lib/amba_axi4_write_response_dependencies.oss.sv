/*  AXI4 Formal Properties.
 *
 *  Copyright (C) 2021  Diego Hernandez <diego@yosyshq.com>
 *  Copyright (C) 2021  Sandia Corporation
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN 1'b0 EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
`default_nettype none
module forward_progress_scoreboard #(
   parameter int unsigned SYMBOL_WIDTH = 8,
   parameter int unsigned MAX_PENDING = 16,
   parameter int unsigned LATENCY_CHECK = 1'b1,
   parameter int unsigned MAX_LATENCY = 16,
   parameter int unsigned OVERFLOW_CHECK = 1'b1,
   parameter int unsigned AG_FLOW = 1'b0,
   parameter int unsigned ORDER = 1'b1,
   parameter int unsigned COVERS = 1'b1,
   parameter int unsigned COVER_DATA_N = MAX_PENDING,
   localparam int unsigned CNTW = MAX_PENDING < 2 ? 1 : $clog2(MAX_PENDING)
) (
   input wire in_clk,
   input wire in_rstn,
   input wire in_handshake_valid,
   input wire in_handshake_ready,
   input wire out_handshake_valid,
   input wire out_handshake_ready,
   input wire [SYMBOL_WIDTH-1:0] in_data,
   input wire [SYMBOL_WIDTH-1:0] out_data,
   output logic [CNTW:0] pending_reads
);

   logic in_request;
   logic out_response;
   logic [CNTW:0] scoreboard_ps = '0;
   logic [CNTW:0] scoreboard_ns;
   logic [SYMBOL_WIDTH-1:0] data_ps [0:MAX_PENDING];
   logic [SYMBOL_WIDTH-1:0] data_ns [0:MAX_PENDING];
   logic [CNTW:0] index_value;

   always_ff @(posedge in_clk, negedge in_rstn) begin
      if (!in_rstn) begin
         scoreboard_ps <= '0;
         for (int i = 0; i <= MAX_PENDING; i++) begin
            data_ps[i] <= '0;
         end
      end
      else begin
         scoreboard_ps <= scoreboard_ns;
         for (int i = 0; i <= MAX_PENDING; i++) begin
            data_ps[i] <= data_ns[i];
         end
      end
   end

   always_comb begin
      in_request = in_handshake_valid && in_handshake_ready;
      out_response = out_handshake_valid && out_handshake_ready;
      scoreboard_ns = scoreboard_ps + in_request - out_response;
      index_value = scoreboard_ps;

      for (int i = 0; i <= MAX_PENDING; i++) begin
         data_ns[i] = data_ps[i];
         if ((i < scoreboard_ps) && (out_data == data_ps[i])) begin
            index_value = i;
         end
      end

      if (in_request && (scoreboard_ps <= MAX_PENDING)) begin
         data_ns[scoreboard_ps] = in_data;
      end

      if (out_response && (index_value < scoreboard_ps)) begin
         for (int i = 0; i < MAX_PENDING; i++) begin
            if (i >= index_value) begin
               data_ns[i] = data_ns[i+1];
            end
         end
      end

      pending_reads = scoreboard_ps;
   end

   generate
      if (AG_FLOW == 1'b0) begin: assumption
         always @(posedge in_clk) begin
            if (in_rstn) begin
               cp_no_overflow_no_dead_end: assume (!(scoreboard_ps == MAX_PENDING-1) || (!in_handshake_valid));
            end
         end

         if (ORDER == 1'b1) begin: out_of_order
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  cp_data_integrity_out_of_order: assume (!(out_handshake_valid) || (index_value < scoreboard_ps));
               end
            end
         end
         else begin: in_order
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  cp_data_integrity_in_order: assume (!(out_handshake_valid) || (index_value == '0));
               end
            end
         end

         if (LATENCY_CHECK == 1'b1) begin: bounded_progress
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  cp_making_progress_bounded: assume (scoreboard_ps <= MAX_LATENCY);
               end
            end
         end
         else begin: unbounded_progress
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  cp_making_progress_unbounded: assume (1'b1);
               end
            end
         end
      end
      else begin: guarantee
         always @(posedge in_clk) begin
            if (in_rstn) begin
               ap_no_overflow: assert (!(in_handshake_valid) || (scoreboard_ps < MAX_PENDING));
            end
         end

         if (ORDER == 1'b1) begin: out_of_order
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  ap_data_integrity_out_of_order: assert (!(out_handshake_valid) || (index_value < scoreboard_ps));
               end
            end
         end
         else begin: in_order
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  ap_data_integrity_in_order: assert (!(out_handshake_valid) || (index_value == '0));
               end
            end
         end

         if (LATENCY_CHECK == 1'b1) begin: bounded_progress
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  ap_making_progress_bounded: assert (scoreboard_ps <= MAX_LATENCY);
               end
            end
         end
         else begin: unbounded_progress
            always @(posedge in_clk) begin
               if (in_rstn) begin
                  ap_making_progress_unbounded: assert (1'b1);
               end
            end
         end
      end

      if (COVERS == 1'b1) begin: cover_scenarios
         for (genvar i = 1; i < MAX_PENDING-1; i++) begin: wp_symbol_in
            forward_progress_scoreboard__oss_cover__wp_symbol_in oss_cover_inst_wp_symbol_in (
               .in_clk(in_clk),
               .in_rstn(in_rstn),
               .cond(in_request && scoreboard_ns == i)
            );
         end
      end
   endgenerate
endmodule // forward_progress_scoreboard

module forward_progress_scoreboard__oss_cover__wp_symbol_in (
   input wire in_clk,
   input wire in_rstn,
   input wire cond
);
   always @(posedge in_clk) begin
      if (in_rstn) begin
         wp_symbol_in: cover (cond);
      end
   end
endmodule // forward_progress_scoreboard__oss_cover__wp_symbol_in

module amba_axi4_write_response_dependencies #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 64,
   parameter int unsigned MAX_WR_BURSTS = 4,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAX_WR_LENGTH = 8,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE
)
   (input wire ACLK, ARESETn,
    input wire [ID_WIDTH-1:0] AWID, BID,
    input wire [ADDRESS_WIDTH-1:0] AWADDR,
    input wire [7:0] AWLEN,
    input wire [2:0] AWSIZE,
    input wire [1:0] AWBURST,
    input wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input wire BVALID, BREADY,
    input wire AWVALID, AWREADY,
    input wire WVALID, WREADY, WLAST);

   localparam logic [1:0] OKAY = amba_axi4_protocol_checker_pkg::OKAY;
   localparam logic [1:0] EXOKAY = amba_axi4_protocol_checker_pkg::EXOKAY;
   localparam logic [1:0] SLVERR = amba_axi4_protocol_checker_pkg::SLVERR;
   localparam logic [1:0] DECERR = amba_axi4_protocol_checker_pkg::DECERR;
   localparam logic [0:0] NORMAL = amba_axi4_protocol_checker_pkg::NORMAL;
   localparam logic [0:0] EXCLUSIVE = amba_axi4_protocol_checker_pkg::EXCLUSIVE;
   localparam logic [3:0] BURSTLEN1 = amba_axi4_protocol_checker_pkg::BURSTLEN1;
   localparam logic [3:0] BURSTLEN2 = amba_axi4_protocol_checker_pkg::BURSTLEN2;
   localparam logic [3:0] BURSTLEN3 = amba_axi4_protocol_checker_pkg::BURSTLEN3;
   localparam logic [3:0] BURSTLEN4 = amba_axi4_protocol_checker_pkg::BURSTLEN4;
   localparam logic [3:0] BURSTLEN5 = amba_axi4_protocol_checker_pkg::BURSTLEN5;
   localparam logic [3:0] BURSTLEN6 = amba_axi4_protocol_checker_pkg::BURSTLEN6;
   localparam logic [3:0] BURSTLEN7 = amba_axi4_protocol_checker_pkg::BURSTLEN7;
   localparam logic [3:0] BURSTLEN8 = amba_axi4_protocol_checker_pkg::BURSTLEN8;
   localparam logic [3:0] BURSTLEN9 = amba_axi4_protocol_checker_pkg::BURSTLEN9;
   localparam logic [3:0] BURSTLEN10 = amba_axi4_protocol_checker_pkg::BURSTLEN10;
   localparam logic [3:0] BURSTLEN11 = amba_axi4_protocol_checker_pkg::BURSTLEN11;
   localparam logic [3:0] BURSTLEN12 = amba_axi4_protocol_checker_pkg::BURSTLEN12;
   localparam logic [3:0] BURSTLEN13 = amba_axi4_protocol_checker_pkg::BURSTLEN13;
   localparam logic [3:0] BURSTLEN14 = amba_axi4_protocol_checker_pkg::BURSTLEN14;
   localparam logic [3:0] BURSTLEN15 = amba_axi4_protocol_checker_pkg::BURSTLEN15;
   localparam logic [3:0] BURSTLEN16 = amba_axi4_protocol_checker_pkg::BURSTLEN16;
   localparam logic [1:0] FIXED = amba_axi4_protocol_checker_pkg::FIXED;
   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [1:0] WRAP = amba_axi4_protocol_checker_pkg::WRAP;
   localparam logic [1:0] RESERVED = amba_axi4_protocol_checker_pkg::RESERVED;
   localparam logic [2:0] SIZE1B = amba_axi4_protocol_checker_pkg::SIZE1B;
   localparam logic [2:0] SIZE2B = amba_axi4_protocol_checker_pkg::SIZE2B;
   localparam logic [2:0] SIZE4B = amba_axi4_protocol_checker_pkg::SIZE4B;
   localparam logic [2:0] SIZE8B = amba_axi4_protocol_checker_pkg::SIZE8B;
   localparam logic [2:0] SIZE16B = amba_axi4_protocol_checker_pkg::SIZE16B;
   localparam logic [2:0] SIZE32B = amba_axi4_protocol_checker_pkg::SIZE32B;
   localparam logic [2:0] SIZE64B = amba_axi4_protocol_checker_pkg::SIZE64B;
   localparam logic [2:0] SIZE128B = amba_axi4_protocol_checker_pkg::SIZE128B;
   localparam int unsigned SOURCE = amba_axi4_protocol_checker_pkg::SOURCE;
   localparam int unsigned DESTINATION = amba_axi4_protocol_checker_pkg::DESTINATION;
   localparam int unsigned MONITOR = amba_axi4_protocol_checker_pkg::MONITOR;
   localparam int unsigned CONSTRAINT = amba_axi4_protocol_checker_pkg::CONSTRAINT;
   localparam int unsigned AXI4LITE = amba_axi4_protocol_checker_pkg::AXI4LITE;
   localparam int unsigned AXI4FULL = amba_axi4_protocol_checker_pkg::AXI4FULL;


   localparam int unsigned WR_CAM_DEPTH = MAX_WR_BURSTS < 1 ? 1 : MAX_WR_BURSTS;
   localparam int unsigned WR_CNTW = WR_CAM_DEPTH < 2 ? 1 : $clog2(WR_CAM_DEPTH);
   localparam int unsigned STRB_WIDTH = DATA_WIDTH/8;
   localparam int unsigned WR_MAX_BEATS = MAX_WR_LENGTH < 1 ? 1 :
                                          (MAX_WR_LENGTH > 256 ? 256 : MAX_WR_LENGTH);
   localparam bit WR_SINGLE_OUTSTANDING = MAX_WR_BURSTS <= 1;

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

   assign aw_fire = AWVALID && AWREADY;
   assign w_fire  = WVALID && WREADY;
   assign b_fire  = BVALID && BREADY;

   localparam int unsigned RESOLUTION = (VERIFY_AGENT_TYPE  == MONITOR || VERIFY_AGENT_TYPE ==  DESTINATION) ? 1'b1 : 1'b0;


   function automatic logic [ADDRESS_WIDTH-1:0] aligned_addr
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size);
      aligned_addr = (addr >> size) << size;
   endfunction

   function automatic logic [ADDRESS_WIDTH-1:0] write_beat_addr
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [7:0] len,
      input int unsigned beat);
      int unsigned bytes_per_beat;
      int unsigned wrap_bytes;
      logic [ADDRESS_WIDTH-1:0] aligned_start;
      logic [ADDRESS_WIDTH-1:0] beat_offset;
      logic [ADDRESS_WIDTH-1:0] incr_addr;
      logic [ADDRESS_WIDTH-1:0] wrap_offset_mask;
      begin
         bytes_per_beat = 1 << size;
         aligned_start = aligned_addr(addr, size);
         beat_offset = beat * bytes_per_beat;
         incr_addr = aligned_start + beat_offset;
         wrap_bytes = bytes_per_beat * (int'(len) + 1);
         wrap_offset_mask = wrap_bytes - 1;

         case(burst)
           FIXED: write_beat_addr = addr;
           WRAP: begin
              if(beat == 0) begin
                 write_beat_addr = addr;
              end
              else begin
                 write_beat_addr = (addr & ~wrap_offset_mask) |
                                   (incr_addr & wrap_offset_mask);
              end
           end
           default: begin
              if(beat == 0) begin
                 write_beat_addr = addr;
              end
              else begin
                 write_beat_addr = incr_addr;
              end
           end
         endcase
      end
   endfunction

   function automatic logic [STRB_WIDTH-1:0] legal_wstrb_mask
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [7:0] len,
      input int unsigned beat);
      logic [ADDRESS_WIDTH-1:0] beat_addr;
      logic [STRB_WIDTH-1:0] base_mask;
      int unsigned bytes_per_beat;
      int unsigned unaligned_lanes;
      int unsigned lane_shift;
      begin
         bytes_per_beat = 1 << size;
         beat_addr = write_beat_addr(addr, size, burst, len, beat);
         base_mask = '0;

         for(int i = 0; i < STRB_WIDTH; i++) begin
            if(i < bytes_per_beat) begin
               base_mask[i] = 1'b1;
            end
         end

         unaligned_lanes = beat_addr & (bytes_per_beat - 1);
         base_mask = base_mask & (base_mask << unaligned_lanes);
         lane_shift = beat_addr & (((STRB_WIDTH - 1) << size) & (STRB_WIDTH - 1));
         legal_wstrb_mask = base_mask << lane_shift;
      end
   endfunction

   function automatic logic [STRB_WIDTH-1:0] legal_wstrb_mask_32b_incr
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input int unsigned beat);
      logic [ADDRESS_WIDTH-1:0] beat_addr;
      logic [ADDRESS_WIDTH-1:0] aligned_start;
      logic [3:0] mask4;
      begin
         aligned_start = aligned_addr(addr, size);
         beat_addr = (beat == 0) ? addr : aligned_start + (beat << size);
         mask4 = 4'h0;

         case(size)
           SIZE1B: mask4 = 4'b0001 << beat_addr[1:0];
           SIZE2B: begin
              mask4 = 4'b0011 & (4'b0011 << beat_addr[0]);
              mask4 = mask4 << {beat_addr[1], 1'b0};
           end
           SIZE4B: mask4 = 4'b1111 & (4'b1111 << beat_addr[1:0]);
           default: mask4 = 4'h0;
         endcase

         legal_wstrb_mask_32b_incr = mask4;
      end
   endfunction

   function automatic logic wstrb_has_illegal_lane
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [7:0] len,
      input int unsigned beat,
      input logic [STRB_WIDTH-1:0] strb);
      if((STRB_WIDTH == 4) && (burst == INCR) && (size <= SIZE4B)) begin
         wstrb_has_illegal_lane = |(strb & ~legal_wstrb_mask_32b_incr(addr, size, beat));
      end
      else begin
         wstrb_has_illegal_lane = |(strb & ~legal_wstrb_mask(addr, size, burst, len, beat));
      end
   endfunction

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                  AW/W/B dependency modeling                     *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(WR_SINGLE_OUTSTANDING) begin: single_outstanding_model
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
         logic [STRB_WIDTH-1:0] wstrb_q [WR_MAX_BEATS-1:0];
         logic [STRB_WIDTH-1:0] wstrb_d [WR_MAX_BEATS-1:0];
         logic valid_stage_aw_seen;
         logic [7:0] valid_stage_awlen;
         logic [8:0] valid_stage_w_count;
         logic valid_stage_wlast_seen;

         assign outstandingAW = {{WR_CNTW{1'b0}}, aw_seen_q};
         assign outstandingW = {{WR_CNTW{1'b0}}, aw_seen_q || w_seen_q};

         always_comb begin
            b_aw_match = aw_seen_q && (BID == awid_q);
            b_wlast_match = b_aw_match && wlast_seen_q;
            b_wstrb_error = b_aw_match && wstrb_error_q;
            wstrb_context_valid = aw_seen_q && w_seen_q;
            wstrb_context_error = wstrb_error_q;
         end

         always_comb begin
            valid_stage_aw_seen = aw_seen_q;
            valid_stage_awlen = awlen_q;
            valid_stage_w_count = w_count_q;
            valid_stage_wlast_seen = wlast_seen_q;
            wdata_num_valid_error = 1'b0;

            if(b_fire && b_aw_match && b_wlast_match) begin
               valid_stage_aw_seen = 1'b0;
               valid_stage_awlen = '0;
               valid_stage_w_count = '0;
               valid_stage_wlast_seen = 1'b0;
            end

            if(WVALID) begin
               if(valid_stage_wlast_seen) begin
                  wdata_num_valid_error = 1'b1;
               end
               else if(valid_stage_aw_seen) begin
                  wdata_num_valid_error =
                    wdata_num_valid_error ||
                    (WLAST && (valid_stage_w_count != {1'b0, valid_stage_awlen})) ||
                    (!WLAST && (valid_stage_w_count == {1'b0, valid_stage_awlen}));
               end
            end

            if(AWVALID) begin
               if(valid_stage_aw_seen) begin
                  wdata_num_valid_error = 1'b1;
               end
               else begin
                  wdata_num_valid_error =
                    wdata_num_valid_error ||
                    (valid_stage_wlast_seen &&
                     (valid_stage_w_count != ({1'b0, AWLEN} + 1'b1))) ||
                    (!valid_stage_wlast_seen &&
                     (valid_stage_w_count > {1'b0, AWLEN})) ||
                    (WVALID && WLAST &&
                     (valid_stage_w_count < {1'b0, AWLEN})) ||
                    (WVALID && !WLAST &&
                     (valid_stage_w_count == {1'b0, AWLEN}));
               end
            end
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
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
               for(int i = 0; i < WR_MAX_BEATS; i++) begin
                  wstrb_q[i] <= '0;
               end
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
               wstrb_q <= wstrb_d;
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
            wstrb_d = wstrb_q;
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
               for(int i = 0; i < WR_MAX_BEATS; i++) begin
                  wstrb_d[i] = '0;
               end
            end

            if(w_fire) begin
               if(wlast_seen_d) begin
                  wdata_num_state_error = 1'b1;
               end
               else begin
                  if(aw_seen_d) begin
                     if(w_count_d < WR_MAX_BEATS) begin
                        wstrb_error_d =
                          wstrb_error_d ||
                          wstrb_has_illegal_lane(awaddr_d, awsize_d, awburst_d,
                                                  awlen_d, w_count_d, WSTRB);
                     end
                     else begin
                        wstrb_error_d = 1'b1;
                     end

                     if(WLAST) begin
                        wdata_num_state_error =
                          (w_count_d != {1'b0, awlen_d});
                     end
                     else begin
                        wdata_num_state_error =
                          (w_count_d >= {1'b0, awlen_d});
                     end
                  end
                  else begin
                     if(w_count_d < WR_MAX_BEATS) begin
                        wstrb_d[w_count_d] = WSTRB;
                     end
                     else begin
                        wstrb_error_d = 1'b1;
                     end
                  end

                  w_seen_d = 1'b1;
                  w_count_d = w_count_d + 1'b1;
                  wlast_seen_d = WLAST;
               end
            end

            if(aw_fire) begin
               if(aw_seen_d) begin
                  wdata_num_state_error = wdata_num_state_error || 1'b1;
               end
               else begin
                  aw_seen_d = 1'b1;
                  awid_d = AWID;
                  awaddr_d = AWADDR;
                  awlen_d = AWLEN;
                  awsize_d = AWSIZE;
                  awburst_d = AWBURST;

                  for(int i = 0; i < WR_MAX_BEATS; i++) begin
                     if(i < w_count_d) begin
                        wstrb_error_d =
                          wstrb_error_d ||
                          wstrb_has_illegal_lane(AWADDR, AWSIZE, AWBURST,
                                                  AWLEN, i, wstrb_d[i]);
                     end
                  end

                  if(wlast_seen_d) begin
                     wdata_num_state_error =
                       wdata_num_state_error ||
                       (w_count_d != ({1'b0, AWLEN} + 1'b1));
                  end
                  else begin
                     wdata_num_state_error =
                       wdata_num_state_error ||
                       (w_count_d > {1'b0, AWLEN});
                  end
               end
            end

            wdata_num_error = wdata_num_state_error || wdata_num_valid_error;
         end

         if(RESOLUTION == 1'b0) begin: forward_progress_AW
            always @(posedge ACLK) begin
               cp_no_overflow_no_dead_end: assume (!(aw_seen_q && !(b_fire && b_aw_match && b_wlast_match)) || (!AWVALID));
            end

         end
         else begin: forward_progress_AW
            always @(posedge ACLK) begin
               ap_no_overflow: assert (!(AWVALID) || (!aw_seen_q || (b_fire && b_aw_match && b_wlast_match)));
            end

         end
      end
      else begin: multi_outstanding_model
         logic [WR_CNTW:0] write_cam_count_q, write_cam_count_d;
         logic [ID_WIDTH-1:0] write_id_q [WR_CAM_DEPTH-1:0];
         logic [ID_WIDTH-1:0] write_id_d [WR_CAM_DEPTH-1:0];
         logic [ADDRESS_WIDTH-1:0] write_addr_q [WR_CAM_DEPTH-1:0];
         logic [ADDRESS_WIDTH-1:0] write_addr_d [WR_CAM_DEPTH-1:0];
         logic [7:0] write_len_q [WR_CAM_DEPTH-1:0];
         logic [7:0] write_len_d [WR_CAM_DEPTH-1:0];
         logic [2:0] write_size_q [WR_CAM_DEPTH-1:0];
         logic [2:0] write_size_d [WR_CAM_DEPTH-1:0];
         logic [1:0] write_burst_q [WR_CAM_DEPTH-1:0];
         logic [1:0] write_burst_d [WR_CAM_DEPTH-1:0];
         logic [8:0] write_count_q [WR_CAM_DEPTH-1:0];
         logic [8:0] write_count_d [WR_CAM_DEPTH-1:0];
         logic [STRB_WIDTH-1:0] write_strb_q [WR_CAM_DEPTH-1:0][WR_MAX_BEATS-1:0];
         logic [STRB_WIDTH-1:0] write_strb_d [WR_CAM_DEPTH-1:0][WR_MAX_BEATS-1:0];
         logic write_wstrb_error_q [WR_CAM_DEPTH-1:0];
         logic write_wstrb_error_d [WR_CAM_DEPTH-1:0];
         logic aw_seen_q [WR_CAM_DEPTH-1:0];
         logic aw_seen_d [WR_CAM_DEPTH-1:0];
         logic wlast_seen_q [WR_CAM_DEPTH-1:0];
         logic wlast_seen_d [WR_CAM_DEPTH-1:0];
         logic [WR_CNTW:0] b_match_index;
         logic valid_stage_w_slot_found;
         logic [WR_CNTW:0] valid_stage_w_slot_index;
         logic valid_stage_aw_slot_found;
         logic [WR_CNTW:0] valid_stage_aw_slot_index;

         forward_progress_scoreboard
           #(.SYMBOL_WIDTH(ID_WIDTH),
             .MAX_PENDING(WR_CAM_DEPTH),
             .LATENCY_CHECK(1'b1),
             .MAX_LATENCY(16),
             .OVERFLOW_CHECK(1'b1),
             .AG_FLOW(RESOLUTION),
             .ORDER(1'b1))
         forward_progress_AW
           (.in_clk(ACLK),
            .in_rstn(ARESETn),
            .in_handshake_valid(AWVALID),
            .in_handshake_ready(AWREADY),
            .out_handshake_valid(BVALID),
            .out_handshake_ready(BREADY),
            .in_data(AWID),
            .out_data(BID),
            .pending_reads(outstandingAW));

         assign outstandingW = write_cam_count_q;

         always_comb begin
            b_aw_match = 1'b0;
            b_wlast_match = 1'b0;
            b_wstrb_error = 1'b0;
            wstrb_context_valid = 1'b0;
            wstrb_context_error = 1'b0;
            b_match_index = write_cam_count_q;

            for(int i = 0; i < WR_CAM_DEPTH; i++) begin
               if(!b_aw_match && (i < write_cam_count_q) && aw_seen_q[i] &&
                  (write_id_q[i] == BID)) begin
                  b_aw_match = 1'b1;
                  b_wlast_match = wlast_seen_q[i];
                  b_wstrb_error = write_wstrb_error_q[i];
                  b_match_index = i;
               end

               if((i < write_cam_count_q) && aw_seen_q[i] &&
                  (write_count_q[i] != '0)) begin
                  wstrb_context_valid = 1'b1;
                  wstrb_context_error =
                    wstrb_context_error || write_wstrb_error_q[i];
               end
            end
         end

         always_comb begin
            valid_stage_w_slot_found = 1'b0;
            valid_stage_w_slot_index = write_cam_count_q;
            valid_stage_aw_slot_found = 1'b0;
            valid_stage_aw_slot_index = write_cam_count_q;
            wdata_num_valid_error = 1'b0;

            for(int i = 0; i < WR_CAM_DEPTH; i++) begin
               if(!valid_stage_w_slot_found && (i < write_cam_count_q) &&
                  !wlast_seen_q[i]) begin
                  valid_stage_w_slot_found = 1'b1;
                  valid_stage_w_slot_index = i;
               end
               if(!valid_stage_aw_slot_found && (i < write_cam_count_q) &&
                  !aw_seen_q[i]) begin
                  valid_stage_aw_slot_found = 1'b1;
                  valid_stage_aw_slot_index = i;
               end
            end

            if(WVALID) begin
               if(valid_stage_w_slot_found) begin
                  if(aw_seen_q[valid_stage_w_slot_index]) begin
                     wdata_num_valid_error =
                       wdata_num_valid_error ||
                       (WLAST &&
                        (write_count_q[valid_stage_w_slot_index] !=
                         {1'b0, write_len_q[valid_stage_w_slot_index]})) ||
                       (!WLAST &&
                        (write_count_q[valid_stage_w_slot_index] ==
                         {1'b0, write_len_q[valid_stage_w_slot_index]}));
                  end
               end
               else if(write_cam_count_q >= WR_CAM_DEPTH) begin
                  wdata_num_valid_error = 1'b1;
               end
            end

            if(AWVALID) begin
               if(valid_stage_aw_slot_found) begin
                  wdata_num_valid_error =
                    wdata_num_valid_error ||
                    (wlast_seen_q[valid_stage_aw_slot_index] &&
                     (write_count_q[valid_stage_aw_slot_index] !=
                      ({1'b0, AWLEN} + 1'b1))) ||
                    (!wlast_seen_q[valid_stage_aw_slot_index] &&
                     (write_count_q[valid_stage_aw_slot_index] >
                      {1'b0, AWLEN})) ||
                    (WVALID &&
                     (valid_stage_aw_slot_index == valid_stage_w_slot_index) &&
                     WLAST &&
                     (write_count_q[valid_stage_aw_slot_index] <
                      {1'b0, AWLEN})) ||
                    (WVALID &&
                     (valid_stage_aw_slot_index == valid_stage_w_slot_index) &&
                     !WLAST &&
                     (write_count_q[valid_stage_aw_slot_index] ==
                      {1'b0, AWLEN}));
               end
               else if(write_cam_count_q >= WR_CAM_DEPTH) begin
                  wdata_num_valid_error = 1'b1;
               end
            end
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
            if(!ARESETn) begin
               write_cam_count_q <= '0;
               for(int i = 0; i < WR_CAM_DEPTH; i++) begin
                  write_id_q[i] <= '0;
                  write_addr_q[i] <= '0;
                  write_len_q[i] <= '0;
                  write_size_q[i] <= '0;
                  write_burst_q[i] <= '0;
                  write_count_q[i] <= '0;
                  write_wstrb_error_q[i] <= 1'b0;
                  aw_seen_q[i] <= 1'b0;
                  wlast_seen_q[i] <= 1'b0;
                  for(int j = 0; j < WR_MAX_BEATS; j++) begin
                     write_strb_q[i][j] <= '0;
                  end
               end
            end
            else begin
               write_cam_count_q <= write_cam_count_d;
               write_id_q <= write_id_d;
               write_addr_q <= write_addr_d;
               write_len_q <= write_len_d;
               write_size_q <= write_size_d;
               write_burst_q <= write_burst_d;
               write_count_q <= write_count_d;
               write_strb_q <= write_strb_d;
               write_wstrb_error_q <= write_wstrb_error_d;
               aw_seen_q <= aw_seen_d;
               wlast_seen_q <= wlast_seen_d;
            end
         end

         always_comb begin
            automatic logic aw_slot_found;
            automatic logic w_slot_found;
            automatic logic [WR_CNTW:0] aw_slot_index;
            automatic logic [WR_CNTW:0] w_slot_index;

            write_cam_count_d = write_cam_count_q;
            write_id_d = write_id_q;
            write_addr_d = write_addr_q;
            write_len_d = write_len_q;
            write_size_d = write_size_q;
            write_burst_d = write_burst_q;
            write_count_d = write_count_q;
            write_strb_d = write_strb_q;
            write_wstrb_error_d = write_wstrb_error_q;
            aw_seen_d = aw_seen_q;
            wlast_seen_d = wlast_seen_q;
            wdata_num_state_error = 1'b0;

            // A valid B handshake retires the oldest outstanding burst matching BID.
            if(b_fire && b_aw_match && b_wlast_match) begin
               for(int i = 0; i < WR_CAM_DEPTH; i++) begin
                  if((i >= b_match_index) && (i < (write_cam_count_q - 1))) begin
                     write_id_d[i] = write_id_q[i+1];
                     write_addr_d[i] = write_addr_q[i+1];
                     write_len_d[i] = write_len_q[i+1];
                     write_size_d[i] = write_size_q[i+1];
                     write_burst_d[i] = write_burst_q[i+1];
                     write_count_d[i] = write_count_q[i+1];
                     write_wstrb_error_d[i] = write_wstrb_error_q[i+1];
                     aw_seen_d[i] = aw_seen_q[i+1];
                     wlast_seen_d[i] = wlast_seen_q[i+1];
                     for(int j = 0; j < WR_MAX_BEATS; j++) begin
                        write_strb_d[i][j] = write_strb_q[i+1][j];
                     end
                  end
               end

               if(write_cam_count_q != '0) begin
                  write_cam_count_d = write_cam_count_q - 1'b1;
                  write_id_d[write_cam_count_q - 1'b1] = '0;
                  write_addr_d[write_cam_count_q - 1'b1] = '0;
                  write_len_d[write_cam_count_q - 1'b1] = '0;
                  write_size_d[write_cam_count_q - 1'b1] = '0;
                  write_burst_d[write_cam_count_q - 1'b1] = '0;
                  write_count_d[write_cam_count_q - 1'b1] = '0;
                  write_wstrb_error_d[write_cam_count_q - 1'b1] = 1'b0;
                  aw_seen_d[write_cam_count_q - 1'b1] = 1'b0;
                  wlast_seen_d[write_cam_count_q - 1'b1] = 1'b0;
                  for(int j = 0; j < WR_MAX_BEATS; j++) begin
                     write_strb_d[write_cam_count_q - 1'b1][j] = '0;
                  end
               end
            end

            // AXI4 has no WID, so write data bursts are matched in issue order.
            // A W burst may legally arrive before its AW burst, so W can allocate
            // an entry that a later AW handshake will fill.
            if(w_fire) begin
               w_slot_found = 1'b0;
               w_slot_index = write_cam_count_d;

               for(int i = 0; i < WR_CAM_DEPTH; i++) begin
                  if(!w_slot_found && (i < write_cam_count_d) && !wlast_seen_d[i]) begin
                     w_slot_found = 1'b1;
                     w_slot_index = i;
                  end
               end

               if(w_slot_found) begin
                  if(write_count_d[w_slot_index] < WR_MAX_BEATS) begin
                     if(aw_seen_d[w_slot_index]) begin
                        write_wstrb_error_d[w_slot_index] =
                          write_wstrb_error_d[w_slot_index] ||
                          wstrb_has_illegal_lane(write_addr_d[w_slot_index],
                                                  write_size_d[w_slot_index],
                                                  write_burst_d[w_slot_index],
                                                  write_len_d[w_slot_index],
                                                  write_count_d[w_slot_index],
                                                  WSTRB);
                     end
                     else begin
                        write_strb_d[w_slot_index][write_count_d[w_slot_index]] = WSTRB;
                     end
                  end
                  else begin
                     write_wstrb_error_d[w_slot_index] = 1'b1;
                  end

                  if(aw_seen_d[w_slot_index]) begin
                     if(WLAST) begin
                        wdata_num_state_error =
                          (write_count_d[w_slot_index] != {1'b0, write_len_d[w_slot_index]});
                     end
                     else begin
                        wdata_num_state_error =
                          (write_count_d[w_slot_index] >= {1'b0, write_len_d[w_slot_index]});
                     end
                  end

                  write_count_d[w_slot_index] = write_count_d[w_slot_index] + 1'b1;
                  wlast_seen_d[w_slot_index] = WLAST;
               end
               else if(write_cam_count_d < WR_CAM_DEPTH) begin
                  write_id_d[write_cam_count_d] = '0;
                  write_addr_d[write_cam_count_d] = '0;
                  write_len_d[write_cam_count_d] = '0;
                  write_size_d[write_cam_count_d] = '0;
                  write_burst_d[write_cam_count_d] = '0;
                  write_count_d[write_cam_count_d] = 9'd1;
                  write_strb_d[write_cam_count_d][0] = WSTRB;
                  for(int j = 1; j < WR_MAX_BEATS; j++) begin
                     write_strb_d[write_cam_count_d][j] = '0;
                  end
                  write_wstrb_error_d[write_cam_count_d] = 1'b0;
                  aw_seen_d[write_cam_count_d] = 1'b0;
                  wlast_seen_d[write_cam_count_d] = WLAST;
                  write_cam_count_d = write_cam_count_d + 1'b1;
               end
               else begin
                  wdata_num_state_error =
                    wdata_num_state_error || 1'b1;
               end
            end

            if(aw_fire) begin
               aw_slot_found = 1'b0;
               aw_slot_index = write_cam_count_d;

               for(int i = 0; i < WR_CAM_DEPTH; i++) begin
                  if(!aw_slot_found && (i < write_cam_count_d) && !aw_seen_d[i]) begin
                     aw_slot_found = 1'b1;
                     aw_slot_index = i;
                  end
               end

               if(aw_slot_found) begin
                  write_id_d[aw_slot_index] = AWID;
                  write_addr_d[aw_slot_index] = AWADDR;
                  write_len_d[aw_slot_index] = AWLEN;
                  write_size_d[aw_slot_index] = AWSIZE;
                  write_burst_d[aw_slot_index] = AWBURST;
                  aw_seen_d[aw_slot_index] = 1'b1;

                  for(int i = 0; i < WR_MAX_BEATS; i++) begin
                     if(i < write_count_d[aw_slot_index]) begin
                        write_wstrb_error_d[aw_slot_index] =
                          write_wstrb_error_d[aw_slot_index] ||
                          wstrb_has_illegal_lane(AWADDR, AWSIZE, AWBURST,
                                                  AWLEN, i,
                                                  write_strb_d[aw_slot_index][i]);
                     end
                  end

                  if(wlast_seen_d[aw_slot_index]) begin
                     wdata_num_state_error =
                       wdata_num_state_error ||
                       (write_count_d[aw_slot_index] != ({1'b0, AWLEN} + 1'b1));
                  end
                  else begin
                     wdata_num_state_error =
                       wdata_num_state_error ||
                       (write_count_d[aw_slot_index] > {1'b0, AWLEN});
                  end
               end
               else if(write_cam_count_d < WR_CAM_DEPTH) begin
                  write_id_d[write_cam_count_d] = AWID;
                  write_addr_d[write_cam_count_d] = AWADDR;
                  write_len_d[write_cam_count_d] = AWLEN;
                  write_size_d[write_cam_count_d] = AWSIZE;
                  write_burst_d[write_cam_count_d] = AWBURST;
                  write_count_d[write_cam_count_d] = '0;
                  write_wstrb_error_d[write_cam_count_d] = 1'b0;
                  for(int j = 0; j < WR_MAX_BEATS; j++) begin
                     write_strb_d[write_cam_count_d][j] = '0;
                  end
                  aw_seen_d[write_cam_count_d] = 1'b1;
                  wlast_seen_d[write_cam_count_d] = 1'b0;
                  write_cam_count_d = write_cam_count_d + 1'b1;
               end
               else begin
                  wdata_num_state_error =
                    wdata_num_state_error || 1'b1;
               end
            end

            wdata_num_error = wdata_num_state_error || wdata_num_valid_error;
         end
      end
   endgenerate

   /* ARM Axi4PC alignment:
   * - AXI4_ERRM_WDATA_NUM_PROP1..5
    * - AXI4_ERRM_WSTRB
    * - AXI4_ERRS_BRESP_AW
    * - AXI4_ERRS_BRESP_WLAST
    *
    * AXI4 requires WLAST to match the AWLEN-sized write burst, and a slave
    * must provide a write response only after the write address and final
    * write data transfer for that transaction have completed.
    * Each WSTRB bit that is asserted must also fall inside the byte lanes
    * addressed by AWADDR/AWSIZE/AWBURST for the corresponding data beat.
    * Ref: AMBA AXI4 write response dependency, A3.3.1, Figure A3-7,
    * write burst length encoding, A3.4.1, and write strobe signaling,
    * A3.4.3.
    */
   // OSS conversion inlined property bresp_after_aw

   // OSS conversion inlined property bresp_after_wlast

   // OSS conversion inlined property write_data_count_matches_awlen

   // OSS conversion inlined property write_strobes_match_aw_context

   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin: write_response_assertions
         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_BRESP_AW: assert (!(BVALID) || (b_aw_match));
            end
         end


         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_BRESP_WLAST: assert (!(BVALID) || (b_aw_match && b_wlast_match));
            end
         end

      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin: write_response_constraints
         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_BRESP_AW: assume (!(BVALID) || (b_aw_match));
            end
         end


         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_BRESP_WLAST: assume (!(BVALID) || (b_aw_match && b_wlast_match));
            end
         end

      end
   endgenerate

   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin: write_data_count_assertions
         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_WDATA_NUM: assert (!wdata_num_error);
            end
         end

      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin: write_data_count_constraints
         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_WDATA_NUM: assume (!wdata_num_error);
            end
         end

      end
   endgenerate

   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin: write_strobe_assertions
         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_WSTRB_MATCHES_AW_CONTEXT: assert (!(wstrb_context_valid) || (!wstrb_context_error));
            end
         end

      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin: write_strobe_constraints
         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_WSTRB_MATCHES_AW_CONTEXT: assume (!(wstrb_context_valid) || (!wstrb_context_error));
            end
         end

      end
   endgenerate
endmodule // amba_axi4_write_response_dependencies
`default_nettype wire
