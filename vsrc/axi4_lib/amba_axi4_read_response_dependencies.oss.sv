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
 */
`default_nettype none

module amba_axi4_read_response_dependencies #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAX_RD_LENGTH = 8,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   localparam int unsigned RD_CAM_DEPTH = MAX_RD_BURSTS < 1 ? 1 : MAX_RD_BURSTS,
     localparam int unsigned RD_CNTW = RD_CAM_DEPTH < 2 ? 1 : $clog2(RD_CAM_DEPTH)
)
   (input wire ACLK, ARESETn,
    input wire [ID_WIDTH-1:0] ARID, RID,
    input wire [7:0] ARLEN,
    input wire ARVALID, ARREADY,
    input wire RVALID, RREADY, RLAST,
    output logic proof_ar_seen,
    output logic [ID_WIDTH-1:0] proof_arid,
    output logic [7:0] proof_arlen,
    output logic [8:0] proof_r_count);

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

   localparam bit RD_SINGLE_OUTSTANDING = MAX_RD_BURSTS <= 1;
   localparam int unsigned RD_MAX_BEATS = MAX_RD_LENGTH < 1 ? 1 :
                                          (MAX_RD_LENGTH > 256 ? 256 : MAX_RD_LENGTH);

   logic ar_fire;
   logic r_fire;

   logic rid_match;
   logic [RD_CNTW:0] rid_match_index;
   logic [7:0] arlen_pending;
   logic [8:0] rcount_pending;

   assign ar_fire = ARVALID && ARREADY;
   assign r_fire = RVALID && RREADY;

   generate
      if(RD_SINGLE_OUTSTANDING) begin: single_outstanding_model
         logic ar_seen_q, ar_seen_d;
         logic [ID_WIDTH-1:0] arid_q, arid_d;
         logic [7:0] arlen_q, arlen_d;
         logic [8:0] r_count_q, r_count_d;

         always_comb begin
            rid_match = ar_seen_q && (RID == arid_q);
            rid_match_index = '0;
            arlen_pending = arlen_q;
            rcount_pending = r_count_q;
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
            if(!ARESETn) begin
               ar_seen_q <= 1'b0;
               arid_q <= '0;
               arlen_q <= '0;
               r_count_q <= '0;
            end
            else begin
               ar_seen_q <= ar_seen_d;
               arid_q <= arid_d;
               arlen_q <= arlen_d;
               r_count_q <= r_count_d;
            end
         end

	         always_comb begin
	            ar_seen_d = ar_seen_q;
	            arid_d = arid_q;
	            arlen_d = arlen_q;
	            r_count_d = r_count_q;

            if(r_fire && rid_match) begin
               if(RLAST) begin
                  ar_seen_d = 1'b0;
                  arid_d = '0;
                  arlen_d = '0;
                  r_count_d = '0;
               end
               else begin
                  r_count_d = r_count_q + 1'b1;
               end
            end

            if(ar_fire) begin
               ar_seen_d = 1'b1;
               arid_d = ARID;
               arlen_d = ARLEN;
	               r_count_d = '0;
	            end
	         end

         always_comb begin
            proof_ar_seen = ar_seen_q;
            proof_arid = arid_q;
            proof_arlen = arlen_q;
            proof_r_count = r_count_q;
         end

         always @(posedge ACLK) begin
            if(ARESETn) begin
               ap_cl1_read_dep_idle_state_clear:
                  assert (ar_seen_q || ((arid_q == '0) && (arlen_q == '0) &&
                                        (r_count_q == '0)));
               ap_cl1_read_dep_count_within_arlen:
                  assert (!ar_seen_q || (r_count_q <= {1'b0, arlen_q}));
               ap_cl1_read_dep_arlen_within_cl1_max:
                  assert (!ar_seen_q || (arlen_q < RD_MAX_BEATS));
            end
         end
	      end
	      else begin: multi_outstanding_model
         logic [RD_CNTW:0] read_cam_count_q, read_cam_count_d;
         logic [ID_WIDTH-1:0] read_id_q [RD_CAM_DEPTH-1:0];
         logic [ID_WIDTH-1:0] read_id_d [RD_CAM_DEPTH-1:0];
         logic [7:0] read_len_q [RD_CAM_DEPTH-1:0];
         logic [7:0] read_len_d [RD_CAM_DEPTH-1:0];
         logic [8:0] read_count_q [RD_CAM_DEPTH-1:0];
         logic [8:0] read_count_d [RD_CAM_DEPTH-1:0];

         always_comb begin
            rid_match = 1'b0;
            rid_match_index = read_cam_count_q;
            arlen_pending = '0;
            rcount_pending = '0;

            for(int i = 0; i < RD_CAM_DEPTH; i++) begin
               if(!rid_match && (i < read_cam_count_q) && (read_id_q[i] == RID)) begin
                  rid_match = 1'b1;
                  rid_match_index = i;
                  arlen_pending = read_len_q[i];
                  rcount_pending = read_count_q[i];
               end
            end
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
            if(!ARESETn) begin
               read_cam_count_q <= '0;
               for(int i = 0; i < RD_CAM_DEPTH; i++) begin
                  read_id_q[i] <= '0;
                  read_len_q[i] <= '0;
                  read_count_q[i] <= '0;
               end
            end
            else begin
               read_cam_count_q <= read_cam_count_d;
               read_id_q <= read_id_d;
               read_len_q <= read_len_d;
               read_count_q <= read_count_d;
            end
         end

         always_comb begin
            read_cam_count_d = read_cam_count_q;
            read_id_d = read_id_q;
            read_len_d = read_len_q;
            read_count_d = read_count_q;

            // A read data handshake consumes the oldest outstanding read burst that
            // matches RID. The entry is retired only on the RLAST beat.
            if(r_fire && rid_match) begin
               if(RLAST) begin
                  for(int i = 0; i < RD_CAM_DEPTH; i++) begin
                     if((i >= rid_match_index) && (i < (read_cam_count_q - 1))) begin
                        read_id_d[i] = read_id_q[i+1];
                        read_len_d[i] = read_len_q[i+1];
                        read_count_d[i] = read_count_q[i+1];
                     end
                  end

                  if(read_cam_count_q != '0) begin
                     read_cam_count_d = read_cam_count_q - 1'b1;
                     read_id_d[read_cam_count_q - 1'b1] = '0;
                     read_len_d[read_cam_count_q - 1'b1] = '0;
                     read_count_d[read_cam_count_q - 1'b1] = '0;
                  end
               end
               else begin
                  read_count_d[rid_match_index] = read_count_q[rid_match_index] + 1'b1;
               end
            end

            if(ar_fire && (read_cam_count_d < RD_CAM_DEPTH)) begin
               read_id_d[read_cam_count_d] = ARID;
               read_len_d[read_cam_count_d] = ARLEN;
               read_count_d[read_cam_count_d] = '0;
               read_cam_count_d = read_cam_count_d + 1'b1;
            end
         end

         always_comb begin
            proof_ar_seen = read_cam_count_q != '0;
            proof_arid = read_id_q[0];
            proof_arlen = read_len_q[0];
            proof_r_count = read_count_q[0];
         end
      end
   endgenerate


   /* ARM Axi4PC alignment:
    * - AXI4_ERRS_RID
    * - AXI4_ERRS_RDATA_NUM
    *
    * Read data must be returned only for an outstanding AR transaction, and
    * RLAST must identify exactly the final data transfer of the ARLEN-sized
    * burst. Ref: AMBA AXI4 read data dependency, A3.3.1, Figure A3-6.
    */
   // OSS conversion inlined property rdata_after_ar

   // OSS conversion inlined property rdata_num_matches_arlen

   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin: read_response_assertions
         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_RID: assert (!(RVALID) || (rid_match));
            end
         end


         always @(posedge ACLK) begin
            if (ARESETn) begin
               ap_RDATA_NUM: assert (!(RVALID && rid_match) || (RLAST == (rcount_pending == {1'b0, arlen_pending})));
            end
         end

      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin: read_response_constraints
         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_RID: assume (!(RVALID) || (rid_match));
            end
         end


         always @(posedge ACLK) begin
            if (ARESETn) begin
               cp_RDATA_NUM: assume (!(RVALID && rid_match) || (RLAST == (rcount_pending == {1'b0, arlen_pending})));
            end
         end

      end
   endgenerate
endmodule // amba_axi4_read_response_dependencies
`default_nettype wire
