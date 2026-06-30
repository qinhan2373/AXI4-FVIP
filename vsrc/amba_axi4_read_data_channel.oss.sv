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
module amba_axi4_read_data_channel #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 32,
   parameter int unsigned RUSER_WIDTH = 32,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit EXCLUSIVE_ACCESS = 1'b0
)
   (input wire                       ACLK,
    input wire 			     ARESETn,
    input wire [ID_WIDTH-1:0]    ARID,
    input wire [ADDRESS_WIDTH-1:0] ARADDR,
    input wire [7:0] 		     ARLEN,
    input wire [2:0] 		     ARSIZE,
    input wire [1:0] 		     ARBURST,
    input wire 			     ARVALID,
    input wire 			     ARREADY,
    input wire [ID_WIDTH-1:0]    RID,
    input wire [DATA_WIDTH-1:0]  RDATA,
    input wire [1:0] 		     RRESP,
    input wire 			     RLAST,
    input wire [RUSER_WIDTH-1:0] RUSER,
    input wire 			     RVALID,
    input wire 			     RREADY);

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



   localparam int unsigned STRB_WIDTH = DATA_WIDTH/8;
   localparam int unsigned RD_CAM_DEPTH = MAX_RD_BURSTS < 1 ? 1 : MAX_RD_BURSTS;
   localparam int unsigned RD_CNTW = RD_CAM_DEPTH < 2 ? 1 : $clog2(RD_CAM_DEPTH);
   localparam bit RD_SINGLE_OUTSTANDING = MAX_RD_BURSTS <= 1;

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                          Helper logic                           *
    *            ><><><><><><><><><><><><><><><><><><><><             */

   logic ar_fire;
   logic r_fire;

   logic rdata_context_valid;
   logic [ADDRESS_WIDTH-1:0] rdata_context_addr;
   logic [7:0] rdata_context_len;
   logic [2:0] rdata_context_size;
   logic [1:0] rdata_context_burst;
   logic [8:0] rdata_context_count;
   logic [STRB_WIDTH-1:0] rdata_lane_mask;
   logic [DATA_WIDTH-1:0] mask_rdata;

   assign ar_fire = ARVALID && ARREADY;
   assign r_fire = RVALID && RREADY;

   function automatic logic [STRB_WIDTH-1:0] read_data_valid_lanes
     (input logic [ADDRESS_WIDTH-1:0] addr,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [7:0] len,
      input logic [8:0] beat);
      int unsigned bus_data_bytes;
      int unsigned bytes_per_beat;
      int unsigned length;
      int unsigned unaligned_byte_shift;
      int unsigned beat_addr_inc;
      int unsigned addr_trans_bus;
      int unsigned addr_trans_bus_inc;
      int unsigned wrap_point;
      int unsigned transfer_byte_shift;
      int unsigned byte_shift;
      int unsigned byte_count;
      begin
         bus_data_bytes = STRB_WIDTH;
         bytes_per_beat = 1 << size;
         length = int'(len) + 1;
         unaligned_byte_shift = addr & (bytes_per_beat - 1);
         beat_addr_inc = (burst == FIXED) ? 0 : beat;
         addr_trans_bus = (addr & (bus_data_bytes - 1)) >> size;
         addr_trans_bus_inc = addr_trans_bus + beat_addr_inc;

         if(burst == WRAP) begin
            wrap_point = length + (addr_trans_bus & ~(length - 1));
            if(addr_trans_bus_inc >= wrap_point) begin
               addr_trans_bus_inc = addr_trans_bus_inc - length;
            end
         end

         addr_trans_bus_inc = addr_trans_bus_inc & ((bus_data_bytes - 1) >> size);
         transfer_byte_shift = bytes_per_beat * addr_trans_bus_inc;

         if((burst == FIXED) || ((burst == INCR) && (beat == 0))) begin
            byte_shift = transfer_byte_shift + unaligned_byte_shift;
         end
         else begin
            byte_shift = transfer_byte_shift;
         end

         byte_count = bytes_per_beat;
         if((burst == FIXED) || (beat == 0)) begin
            byte_count = byte_count - unaligned_byte_shift;
         end

         read_data_valid_lanes = '0;
         for(int i = 0; i < STRB_WIDTH; i++) begin
            if((i >= byte_shift) && (i < (byte_shift + byte_count))) begin
               read_data_valid_lanes[i] = 1'b1;
            end
         end
      end
   endfunction

   generate
      if(RD_SINGLE_OUTSTANDING) begin: rdata_single_outstanding_model
         logic ar_seen_q, ar_seen_d;
         logic [ID_WIDTH-1:0] arid_q, arid_d;
         logic [ADDRESS_WIDTH-1:0] araddr_q, araddr_d;
         logic [7:0] arlen_q, arlen_d;
         logic [2:0] arsize_q, arsize_d;
         logic [1:0] arburst_q, arburst_d;
         logic [8:0] r_count_q, r_count_d;

         always_comb begin
            rdata_context_valid = ar_seen_q && (RID == arid_q);
            rdata_context_addr = araddr_q;
            rdata_context_len = arlen_q;
            rdata_context_size = arsize_q;
            rdata_context_burst = arburst_q;
            rdata_context_count = r_count_q;
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
            if(!ARESETn) begin
               ar_seen_q <= 1'b0;
               arid_q <= '0;
               araddr_q <= '0;
               arlen_q <= '0;
               arsize_q <= '0;
               arburst_q <= '0;
               r_count_q <= '0;
            end
            else begin
               ar_seen_q <= ar_seen_d;
               arid_q <= arid_d;
               araddr_q <= araddr_d;
               arlen_q <= arlen_d;
               arsize_q <= arsize_d;
               arburst_q <= arburst_d;
               r_count_q <= r_count_d;
            end
         end

         always_comb begin
            ar_seen_d = ar_seen_q;
            arid_d = arid_q;
            araddr_d = araddr_q;
            arlen_d = arlen_q;
            arsize_d = arsize_q;
            arburst_d = arburst_q;
            r_count_d = r_count_q;

            if(r_fire && rdata_context_valid) begin
               if(RLAST) begin
                  ar_seen_d = 1'b0;
                  arid_d = '0;
                  araddr_d = '0;
                  arlen_d = '0;
                  arsize_d = '0;
                  arburst_d = '0;
                  r_count_d = '0;
               end
               else begin
                  r_count_d = r_count_q + 1'b1;
               end
            end

            if(ar_fire) begin
               ar_seen_d = 1'b1;
               arid_d = ARID;
               araddr_d = ARADDR;
               arlen_d = ARLEN;
               arsize_d = ARSIZE;
               arburst_d = ARBURST;
               r_count_d = '0;
            end
         end
      end
      else begin: rdata_multi_outstanding_model
         logic [RD_CNTW:0] read_cam_count_q, read_cam_count_d;
         logic [ID_WIDTH-1:0] read_id_q [RD_CAM_DEPTH-1:0];
         logic [ID_WIDTH-1:0] read_id_d [RD_CAM_DEPTH-1:0];
         logic [ADDRESS_WIDTH-1:0] read_addr_q [RD_CAM_DEPTH-1:0];
         logic [ADDRESS_WIDTH-1:0] read_addr_d [RD_CAM_DEPTH-1:0];
         logic [7:0] read_len_q [RD_CAM_DEPTH-1:0];
         logic [7:0] read_len_d [RD_CAM_DEPTH-1:0];
         logic [2:0] read_size_q [RD_CAM_DEPTH-1:0];
         logic [2:0] read_size_d [RD_CAM_DEPTH-1:0];
         logic [1:0] read_burst_q [RD_CAM_DEPTH-1:0];
         logic [1:0] read_burst_d [RD_CAM_DEPTH-1:0];
         logic [8:0] read_count_q [RD_CAM_DEPTH-1:0];
         logic [8:0] read_count_d [RD_CAM_DEPTH-1:0];
         logic [RD_CNTW:0] r_match_index;

         always_comb begin
            rdata_context_valid = 1'b0;
            r_match_index = read_cam_count_q;
            rdata_context_addr = '0;
            rdata_context_len = '0;
            rdata_context_size = '0;
            rdata_context_burst = '0;
            rdata_context_count = '0;

            for(int i = 0; i < RD_CAM_DEPTH; i++) begin
               if(!rdata_context_valid && (i < read_cam_count_q) &&
                  (read_id_q[i] == RID)) begin
                  rdata_context_valid = 1'b1;
                  r_match_index = i;
                  rdata_context_addr = read_addr_q[i];
                  rdata_context_len = read_len_q[i];
                  rdata_context_size = read_size_q[i];
                  rdata_context_burst = read_burst_q[i];
                  rdata_context_count = read_count_q[i];
               end
            end
         end

         always_ff @(posedge ACLK, negedge ARESETn) begin
            if(!ARESETn) begin
               read_cam_count_q <= '0;
               for(int i = 0; i < RD_CAM_DEPTH; i++) begin
                  read_id_q[i] <= '0;
                  read_addr_q[i] <= '0;
                  read_len_q[i] <= '0;
                  read_size_q[i] <= '0;
                  read_burst_q[i] <= '0;
                  read_count_q[i] <= '0;
               end
            end
            else begin
               read_cam_count_q <= read_cam_count_d;
               read_id_q <= read_id_d;
               read_addr_q <= read_addr_d;
               read_len_q <= read_len_d;
               read_size_q <= read_size_d;
               read_burst_q <= read_burst_d;
               read_count_q <= read_count_d;
            end
         end

         always_comb begin
            read_cam_count_d = read_cam_count_q;
            read_id_d = read_id_q;
            read_addr_d = read_addr_q;
            read_len_d = read_len_q;
            read_size_d = read_size_q;
            read_burst_d = read_burst_q;
            read_count_d = read_count_q;

            if(r_fire && rdata_context_valid) begin
               if(RLAST) begin
                  for(int i = 0; i < RD_CAM_DEPTH; i++) begin
                     if((i >= r_match_index) && (i < (read_cam_count_q - 1))) begin
                        read_id_d[i] = read_id_q[i+1];
                        read_addr_d[i] = read_addr_q[i+1];
                        read_len_d[i] = read_len_q[i+1];
                        read_size_d[i] = read_size_q[i+1];
                        read_burst_d[i] = read_burst_q[i+1];
                        read_count_d[i] = read_count_q[i+1];
                     end
                  end

                  if(read_cam_count_q != '0) begin
                     read_cam_count_d = read_cam_count_q - 1'b1;
                     read_id_d[read_cam_count_q - 1'b1] = '0;
                     read_addr_d[read_cam_count_q - 1'b1] = '0;
                     read_len_d[read_cam_count_q - 1'b1] = '0;
                     read_size_d[read_cam_count_q - 1'b1] = '0;
                     read_burst_d[read_cam_count_q - 1'b1] = '0;
                     read_count_d[read_cam_count_q - 1'b1] = '0;
                  end
               end
               else begin
                  read_count_d[r_match_index] = read_count_q[r_match_index] + 1'b1;
               end
            end

            if(ar_fire && (read_cam_count_d < RD_CAM_DEPTH)) begin
               read_id_d[read_cam_count_d] = ARID;
               read_addr_d[read_cam_count_d] = ARADDR;
               read_len_d[read_cam_count_d] = ARLEN;
               read_size_d[read_cam_count_d] = ARSIZE;
               read_burst_d[read_cam_count_d] = ARBURST;
               read_count_d[read_cam_count_d] = '0;
               read_cam_count_d = read_cam_count_d + 1'b1;
            end
         end
      end
   endgenerate

   always_comb begin
      if((PROTOCOL_TYPE == AXI4FULL) && rdata_context_valid) begin
         rdata_lane_mask = read_data_valid_lanes(rdata_context_addr,
                                                 rdata_context_size,
                                                 rdata_context_burst,
                                                 rdata_context_len,
                                                 rdata_context_count);
      end
      else begin
         rdata_lane_mask = {STRB_WIDTH{1'b1}};
      end
   end

   for (genvar n = 0; n < STRB_WIDTH; n++) begin: mask_valid_byte_lanes
      assign mask_rdata[(8*n)+7:(8*n)] = {8{rdata_lane_mask[n]}};
   end

   // Now configure unsupported AXI4-Lite signals
   logic 			     R_unsupported_sig;
   assign R_unsupported_sig = (/* All bursts are defined to be of length 1,
				* equivalent to a WLAST or RLAST value of 1. */
			       RLAST == 1'b1 &&
			       /* Optional User-defined signal in the write address channel.
				* Supported only in AXI4. */
			       RUSER == {RUSER_WIDTH{1'b0}} &&
			       /* AXI4-Lite does not support AXI IDs. This means
	                        * all transactions must be in order, and all
	                        * accesses use a single fixed ID value. */
			       RID == {ID_WIDTH{1'b0}});

   /*		 ><><><><><><><><><><><><><><><><><><><><             *
    *		 Section B1.1: Definition of AXI4-Lite                *
    *		 ><><><><><><><><><><><><><><><><><><><><	      */
   generate
      if(PROTOCOL_TYPE == AXI4LITE) begin: axi4lite_defs
	 if(CHECK_PARAMETERS == 1) begin: check_dataw
	    `AMBA_AXI4L_ASSERT_DATABUS_WIDTH(ap_R_AXI4LITE_DATAWIDTH, ACLK, DATA_WIDTH)

	 end
         // Configure the AXI4-Lite checker unsupported signals.
	 `AMBA_AXI4L_ASSUME_UNSUPPORTED_SIG(cp_R_unsupported_axi4l, ACLK, ARESETn, R_unsupported_sig)

      end // block: axi4lite_defs
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              RID                                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_R_STABLE_RID, ACLK, ARESETn, RVALID, RREADY, RID)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RID_X, ACLK, ARESETn, RVALID, RID)

	    end
	    // TODO: Define the limitation of read interleave not supported
         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_R_STABLE_RID, ACLK, ARESETn, RVALID, RREADY, RID)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_R_RID_X, ACLK, ARESETn, RVALID, RID)

	    end
	    // TODO: Define the limitation of read interleave not supported
         end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RDATA                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_R_STABLE_RDATA, ACLK, ARESETn, RVALID, RREADY, (RDATA | ~mask_rdata))

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RDATA_X, ACLK, ARESETn, RVALID, (RDATA | ~mask_rdata))

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_R_STABLE_RDATA, ACLK, ARESETn, RVALID, RREADY, (RDATA | ~mask_rdata))

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_R_RDATA_X, ACLK, ARESETn, RVALID, (RDATA | ~mask_rdata))

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RRESP                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_R_STABLE_RRESP, ACLK, ARESETn, RVALID, RREADY, RRESP)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RRESP_X, ACLK, ARESETn, RVALID, RRESP)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_R_STABLE_RRESP, ACLK, ARESETn, RVALID, RREADY, RRESP)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_R_RRESP_X, ACLK, ARESETn, RVALID, RRESP)

	 end
      end
      if(PROTOCOL_TYPE == AXI4LITE || EXCLUSIVE_ACCESS == 1'b0) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4L_ASSERT_UNSUPPORTED_TRANSFER_STATUS(ap_R_UNSUPPORTED_RESPONSE, ACLK, ARESETn, RVALID, RRESP, EXOKAY)

         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4L_ASSUME_UNSUPPORTED_TRANSFER_STATUS(cp_R_UNSUPPORTED_RESPONSE, ACLK, ARESETn, RVALID, RRESP, EXOKAY)

         end
      end

   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RLAST                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_R_STABLE_RLAST, ACLK, ARESETn, RVALID, RREADY, RLAST)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RLAST_X, ACLK, ARESETn, RVALID, RLAST)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_R_STABLE_RLAST, ACLK, ARESETn, RVALID, RREADY, RLAST)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_R_RLAST_X, ACLK, ARESETn, RVALID, RLAST)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RUSER                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_R_STABLE_RUSER, ACLK, ARESETn, RVALID, RREADY, RUSER)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RUSER_X, ACLK, ARESETn, RVALID, RUSER)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_R_STABLE_RUSER, ACLK, ARESETn, RVALID, RREADY, RUSER)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_R_RUSER_X, ACLK, ARESETn, RVALID, RUSER)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RVALID                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(OPTIONAL_RESET == 1) begin
	 if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_EXIT_FROM_RESET(ap_R_EXIT_RESET, ACLK, ARESETn, RVALID)

	 end
	 else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_EXIT_FROM_RESET(cp_R_EXIT_RESET, ACLK, ARESETn, RVALID)

	 end
      end
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(ap_R_RVALID_until_RREADY, ACLK, ARESETn, RVALID, RREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RVALID_X, ACLK, ARESETn, ARESETn, RVALID)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(cp_R_RVALID_until_RREADY, ACLK, ARESETn, RVALID, RREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_R_RVALID_X, ACLK, ARESETn, ARESETn, RVALID)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             RREADY                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_R_RREADY_X, ACLK, ARESETn, ARESETn, RREADY)

         end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_R_RREADY_X, ACLK, ARESETn, ARESETn, RREADY)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                        AMBA Recommended                         *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   // AMBA Recommended property for potential deadlock detection
   generate
      if(ARM_RECOMMENDED)
        if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin: deadlock_check
           `AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT_R(ap_R_READY_MAXWAIT, ACLK, ARESETn, RVALID, RREADY, MAXWAIT)

        end
        else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin: deadlock_cons
           `AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT_R(cp_R_READY_MAXWAIT, ACLK, ARESETn, RVALID, RREADY, MAXWAIT)

        end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *              Covers To Maximise Debug Information               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   // Witnessing scenarios stated in the AMBA AXI4 spec
   generate
      if (ENABLE_COVER == 1) begin: witness
	 `AMBA_AXI4_COVER_VALID_BEFORE_READY(wp_RVALID_before_RREADY, ACLK, ARESETn, RVALID, RREADY)

	 `AMBA_AXI4_COVER_READY_BEFORE_VALID(wp_RREADY_before_RVALID, ACLK, ARESETn, RVALID, RREADY)

	 `AMBA_AXI4_COVER_VALID_WITH_READY(wp_RVALID_with_RREADY, ACLK, ARESETn, RVALID, RREADY)


	 if (PROTOCOL_TYPE != AXI4LITE) begin: exok_resp
	    `AMBA_AXI4_COVER_RDWR_RESPONSE_EXOKAY(wp_READ_RESP_EXOKAY, ACLK, ARESETn, RVALID, RREADY, RRESP)

	 end
	 `AMBA_AXI4_COVER_RDWR_RESPONSE_OKAY(wp_READ_RESP_OKAY, ACLK, ARESETn, RVALID, RREADY, RRESP)

	 `AMBA_AXI4_COVER_RDWR_RESPONSE_SLVERR(wp_READ_RESP_SLVERR, ACLK, ARESETn, RVALID, RREADY, RRESP)

	 `AMBA_AXI4_COVER_RDWR_RESPONSE_DECERR(wp_READ_RESP_DECERR, ACLK, ARESETn, RVALID, RREADY, RRESP)

      end
   endgenerate
endmodule // amba_axi4_read_data_channel
`default_nettype wire
