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
module amba_axi4_write_data_channel #(
   parameter int unsigned DATA_WIDTH = 32,
   parameter int unsigned WUSER_WIDTH = 32,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_WSTRB = 1'b1,
   parameter bit FULL_WR_STRB = 1'b1,
   parameter bit OPTIONAL_RESET = 1'b1,
   localparam STRB_WIDTH = DATA_WIDTH/8
)
   (input wire                       ACLK,
    input wire 			     ARESETn,
    input wire [DATA_WIDTH-1:0]  WDATA,
    input wire [STRB_WIDTH-1:0]      WSTRB,
    input wire 			     WLAST,
    input wire [WUSER_WIDTH-1:0] WUSER,
    input wire 			     WVALID,
    input wire 			     WREADY);

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



   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                          Helper logic                           *
    *            ><><><><><><><><><><><><><><><><><><><><             */

   // Configure unsupported AXI4-Lite signals
   logic  W_unsupported_sig;
   assign W_unsupported_sig = (/* All bursts are defined to be of length 1,
                                * equivalent to a WLAST or RLAST value of 1. */
                               WLAST  == 1'b1 &&
                               /* Optional User-defined signal in the write address channel.
                                * Supported only in AXI4. */
                               WUSER   == {WUSER_WIDTH{1'b0}});

   /* There is one write strobe for each eight bits of the write data
    * bus, therefore WSTRB[n] corresponds to WDATA[(8n)+7: (8n)].
    * (Section A3.4.3 Data read and write structure, pA3-52). */
   logic [DATA_WIDTH-1:0] mask_wdata;
   logic full_wstrb;
   logic masked_wstrb;
   for (genvar n = 0; n < STRB_WIDTH; n++) begin: mask_valid_byte_lanes
      assign mask_wdata[(8*n)+7:(8*n)] = {8{WSTRB[n]}};
   end
   always_comb begin
      full_wstrb = (WSTRB=={STRB_WIDTH{1'b1}});
      masked_wstrb = (WSTRB!={STRB_WIDTH{1'b1}});
   end

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *            Section B1.1: Definition of AXI4-Lite                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4LITE) begin: axi4lite_defs
	 // Configure the AXI4-Lite checker unsupported signals.
         `AMBA_AXI4L_ASSUME_UNSUPPORTED_SIG(cp_W_unsupported_axi4l, ACLK, ARESETn, W_unsupported_sig)

         if(CHECK_PARAMETERS == 1) begin: check_dataw
            `AMBA_AXI4L_ASSERT_DATABUS_WIDTH(ap_W_AXI4LITE_DATAWIDTH, ACLK, DATA_WIDTH)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             WDATA                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_W_STABLE_WDATA, ACLK, ARESETn, WVALID, WREADY, (WDATA & mask_wdata))

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WDATA_X, ACLK, ARESETn, WVALID, WDATA)

         end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_W_STABLE_WDATA, ACLK, ARESETn, WVALID, WREADY, (WDATA & mask_wdata))

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_W_WDATA_X, ACLK, ARESETn, WVALID, WDATA)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             WSTRB                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_W_STABLE_WSTRB, ACLK, ARESETn, WVALID, WREADY, WSTRB)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WSTRB_X, ACLK, ARESETn, WVALID, WSTRB)

	 end
	 if(OPTIONAL_WSTRB == 1) begin // TODO: Rename the parameter, is not very descriptive
            `AMBA_AXI4_ASSERT_FULL_DATA_TRANSACTION(ap_W_FULL_TRANSACTION_OPTIONAL_WSTRB, ACLK, ARESETn, WVALID, full_wstrb)

         end
      end // if (((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR)))
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_W_STABLE_WSTRB, ACLK, ARESETn, WVALID, WREADY, WSTRB)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_W_WSTRB_X, ACLK, ARESETn, WVALID, WSTRB)

	 end
	 if(OPTIONAL_WSTRB == 1) begin
            `AMBA_AXI4_ASSUME_FULL_DATA_TRANSACTION(cp_W_FULL_TRANSACTION_OPTIONAL_WSTRB, ACLK, ARESETn, WVALID, full_wstrb)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             WLAST                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_W_STABLE_WLAST, ACLK, ARESETn, WVALID, WREADY, WLAST)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WLAST_X, ACLK, ARESETn, WVALID, WLAST)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_W_STABLE_WLAST, ACLK, ARESETn, WVALID, WREADY, WLAST)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_W_WLAST_X, ACLK, ARESETn, WVALID, WLAST)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             WUSER                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_W_STABLE_WUSER, ACLK, ARESETn, WVALID, WREADY, WUSER)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WUSER_X, ACLK, ARESETn, WVALID, WUSER)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_W_STABLE_WUSER, ACLK, ARESETn, WVALID, WREADY, WUSER)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_W_WUSER_X, ACLK, ARESETn, WVALID, WUSER)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             WVALID                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(OPTIONAL_RESET == 1) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_EXIT_FROM_RESET(ap_W_EXIT_RESET, ACLK, ARESETn, WVALID)

         end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_EXIT_FROM_RESET(cp_W_EXIT_RESET, ACLK, ARESETn, WVALID)

         end
      end
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(ap_W_AWVALID_until_AWREADY, ACLK, ARESETn, WVALID, WREADY)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WVALID_X, ACLK, ARESETn, ARESETn, WVALID)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(cp_W_AWVALID_until_AWREADY, ACLK, ARESETn, WVALID, WREADY)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_W_WVALID_X, ACLK, ARESETn, ARESETn, WVALID)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              WREADY                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_W_WREADY_X, ACLK, ARESETn, ARESETn, WREADY)

         end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_W_WREADY_X, ACLK, ARESETn, ARESETn, WREADY)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                        AMBA Recommended                         *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(ARM_RECOMMENDED == 1) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT(ap_W_READY_MAXWAIT, ACLK, ARESETn, WVALID, WREADY, MAXWAIT)

         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT(cp_W_READY_MAXWAIT, ACLK, ARESETn, WVALID, WREADY, MAXWAIT)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *              Covers To Maximise Debug Information               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   // Witnessing scenarios stated in the AMBA AXI4 spec
   generate
      if(ENABLE_COVER == 1) begin: witness
	 `AMBA_AXI4_COVER_VALID_BEFORE_READY(wp_WVALID_before_WREADY, ACLK, ARESETn, WVALID, WREADY)

         `AMBA_AXI4_COVER_READY_BEFORE_VALID(wp_WREADY_before_WVALID, ACLK, ARESETn, WVALID, WREADY)

         `AMBA_AXI4_COVER_VALID_WITH_READY(wp_WVALID_with_WREADY, ACLK, ARESETn, WVALID, WREADY)

	 always @(posedge ACLK) begin
	    if (ARESETn) begin
	       wp_WVALID_WVALID_LAST_BURST: cover (WVALID && WREADY && WLAST);
	    end
	 end

	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    // Unmasked transaction
            always @(posedge ACLK) begin
               if (ARESETn) begin
                  wp_WSTRB_UNMASKED: cover (WVALID && WREADY && (full_wstrb));
               end
            end

	    if(FULL_WR_STRB == 0) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_WSTRB_MASKED: cover (WVALID && WREADY && (masked_wstrb));
	          end
	       end

	    end
	 end
      end // block: witness
   endgenerate
endmodule // amba_axi4_write_data_channel
`default_nettype wire
