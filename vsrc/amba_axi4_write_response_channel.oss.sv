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
module amba_axi4_write_response_channel #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned BUSER_WIDTH = 32,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit EXCLUSIVE_ACCESS = 1'b0
)
   (input wire                       ACLK,
    input wire 			     ARESETn,
    input wire [ID_WIDTH-1:0]    BID,
    input wire [1:0] 		     BRESP,
    input wire [BUSER_WIDTH-1:0] BUSER,
    input wire 			     BVALID,
    input wire 			     BREADY);

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
   logic  B_unsupported_sig;
   assign B_unsupported_sig = (/* Optional User-defined signal in the write address channel.
                                * Supported only in AXI4. */
                               BUSER   == {BUSER_WIDTH{1'b0}} &&
                               /* AXI4-Lite does not support AXI IDs. This means
                                * all transactions must be in order, and all
                                * accesses use a single fixed ID value. */
                               BID     == {ID_WIDTH{1'b0}});

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *            Section B1.1: Definition of AXI4-Lite                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4LITE) begin: axi4lite_defs
         // Configure the AXI4-Lite checker unsupported signals.
         `AMBA_AXI4L_ASSUME_UNSUPPORTED_SIG(cp_B_unsupported_axi4l, ACLK, ARESETn, B_unsupported_sig)

      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              BID                                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_B_STABLE_BID, ACLK, ARESETn, BVALID, BREADY, BID)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_B_BID_X, ACLK, ARESETn, BVALID, BID)

	    end
         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_B_STABLE_BID, ACLK, ARESETn, BVALID, BREADY, BID)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_B_BID_X, ACLK, ARESETn, BVALID, BID)

	    end
         end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             BRESP                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_B_STABLE_BRESP, ACLK, ARESETn, BVALID, BREADY, BRESP)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(cp_B_BRESP_X, ACLK, ARESETn, BVALID, BRESP)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_B_STABLE_BRESP, ACLK, ARESETn, BVALID, BREADY, BRESP)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_B_BRESP_X, ACLK, ARESETn, BVALID, BRESP)

	 end
      end
      if(PROTOCOL_TYPE == AXI4LITE || EXCLUSIVE_ACCESS == 1'b0) begin
	 if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4L_ASSERT_UNSUPPORTED_TRANSFER_STATUS(ap_B_UNSUPPORTED_RESPONSE, ACLK, ARESETn, BVALID, BRESP, EXOKAY)

	 end
	 else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4L_ASSUME_UNSUPPORTED_TRANSFER_STATUS(cp_B_UNSUPPORTED_RESPONSE, ACLK, ARESETn, BVALID, BRESP, EXOKAY)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             BUSER                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_B_STABLE_BUSER, ACLK, ARESETn, BVALID, BREADY, BUSER)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_B_BUSER_X, ACLK, ARESETn, BVALID, BUSER)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_B_STABLE_BUSER, ACLK, ARESETn, BVALID, BREADY, BUSER)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_B_BUSER_X, ACLK, ARESETn, BVALID, BUSER)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             BVALID                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(OPTIONAL_RESET == 1) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_EXIT_FROM_RESET(ap_B_EXIT_RESET, ACLK, ARESETn, BVALID)

         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_EXIT_FROM_RESET(cp_B_EXIT_RESET, ACLK, ARESETn, BVALID)

         end
      end
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(ap_B_BVALID_until_BREADY, ACLK, ARESETn, BVALID, BREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_B_BVALID_X, ACLK, ARESETn, ARESETn, BVALID)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(cp_B_BVALID_until_BREADY, ACLK, ARESETn, BVALID, BREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_B_BVALID_X, ACLK, ARESETn, ARESETn, BVALID)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             BREADY                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_B_BREADY_X, ACLK, ARESETn, ARESETn, BREADY)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_B_BREADY_X, ACLK, ARESETn, BVALID, BREADY)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                        AMBA Recommended                         *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(ARM_RECOMMENDED == 1) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT(ap_B_READY_MAXWAIT, ACLK, ARESETn, BVALID, BREADY, MAXWAIT)

         end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT(cp_B_READY_MAXWAIT, ACLK, ARESETn, BVALID, BREADY, MAXWAIT)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *              Covers To Maximise Debug Information               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   // Witnessing scenarios stated in the AMBA AXI4 spec
   generate
      if(ENABLE_COVER == 1) begin: witness
	 `AMBA_AXI4_COVER_VALID_BEFORE_READY(wp_BVALID_before_BREADY, ACLK, ARESETn, BVALID, BREADY)

	 `AMBA_AXI4_COVER_READY_BEFORE_VALID(wp_BREADY_before_BVALID, ACLK, ARESETn, BVALID, BREADY)

	 `AMBA_AXI4_COVER_VALID_WITH_READY(wp_BVALID_with_BREADY, ACLK, ARESETn, BVALID, BREADY)

	 if (PROTOCOL_TYPE != AXI4LITE) begin: exok_resp
	    `AMBA_AXI4_COVER_RDWR_RESPONSE_EXOKAY(wp_WRITE_RESP_EXOKAY, ACLK, ARESETn, BVALID, BREADY, BRESP)

	 end
	 `AMBA_AXI4_COVER_RDWR_RESPONSE_OKAY(wp_WRITE_RESP_OKAY, ACLK, ARESETn, BVALID, BREADY, BRESP)

	 `AMBA_AXI4_COVER_RDWR_RESPONSE_SLVERR(wp_WRITE_RESP_SLVERR, ACLK, ARESETn, BVALID, BREADY, BRESP)

	 `AMBA_AXI4_COVER_RDWR_RESPONSE_DECERR(wp_WRITE_RESP_DECERR, ACLK, ARESETn, BVALID, BREADY, BRESP)

      end
   endgenerate
endmodule // amba_axi4_write_response_channel
`default_nettype wire
