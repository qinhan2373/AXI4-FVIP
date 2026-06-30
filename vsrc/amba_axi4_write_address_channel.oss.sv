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
module amba_axi4_write_address_channel #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 32,
   parameter int unsigned AWUSER_WIDTH = 32,
   parameter int unsigned MAX_WR_BURSTS = 2,
   parameter int unsigned MAX_WR_LENGTH = 8,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit INTERFACE_REQS = 1'b1,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_WSTRB = 1'b0,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit EXCLUSIVE_ACCESS = 1'b1,
   // Read only
     localparam unsigned STRB_WIDTH = DATA_WIDTH/8,
     localparam unsigned BURST_SIZE_MAX = $clog2(STRB_WIDTH),
     localparam unsigned WRITE_BURST_MAX = 256
)
   (input wire                         ACLK,
    input wire 			       ARESETn,
    input wire [ID_WIDTH-1:0]      AWID,
    input wire [ADDRESS_WIDTH-1:0] AWADDR,
    input wire [7:0] 		       AWLEN,
    input wire [2:0] 		       AWSIZE,
    input wire [1:0] 		       AWBURST,
    input wire 			       AWLOCK,
    input wire [3:0] 		       AWCACHE,
    input wire [2:0] 		       AWPROT,
    input wire [3:0] 		       AWQOS,
    input wire [3:0] 		       AWREGION,
    input wire [AWUSER_WIDTH-1:0]  AWUSER,
    input wire 			       AWVALID,
    input wire 			       AWREADY);

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



   /*		 ><><><><><><><><><><><><><><><><><><><><             *
    *		               Helper logic                           *
    *		 ><><><><><><><><><><><><><><><><><><><><	      */

   // Configure unsupported AXI4-Lite signals
   bit AW_unsupported_sig;
   // "all transactions are of burst length 1".
   // "all data accesses use the full width of the data bus".
   // "AXI4-Lite supports a data bus width of 32-bit or 64-bit". (B1.1, pB1-126).
   // AXI4-Lite can have a burst size of either 4 (AWSIZE=3'b010) or 8 (AWSIZE=3'b011).
   // which is log2(STRB_WIDTH) [if WDATA = 32, STRB=32/8=4, log2(4)=2=AWSIZE of 3'b010.
   localparam MAX_SIZE = $clog2(STRB_WIDTH);
   assign AW_unsupported_sig = (/* The burst length is defined to be 1,
                                 * equivalent to an AxLEN value of zero. */
                                AWLEN    == 8'b00000000 &&
                                /* All accesses are defined to be the width
                                 * of the data bus. */
                                AWSIZE   == MAX_SIZE &&
                                /* The burst type has no meaning because the burst
                                 * length is 1. */
                                AWBURST  == 2'b00 &&
                                /* All accesses are defined as Normal accesses,
                                 * equivalent to an AxLOCK value of zero. */
                                AWLOCK   == 1'b0 &&
                                /* All accesses are defined as Non-modifiable,
                                 * Non-bufferable, equivalent to an AxCACHE
                                 * value of 0b0000. */
                                AWCACHE  == 4'b0000 &&
                                /* A default value of 0b0000 indicates that
                                 * the interface is not participating in any
                                 * QoS scheme. */
                                AWQOS    == 4'b0000 &&
                                /* Table A10-1 Master interface write channel
                                 * signals and default signal values.
                                 * AWREGION Default all zeros. */
                                AWREGION == 4'b0000 &&
                                /* Optional User-defined signal in the write address channel.
                                 * Supported only in AXI4. */
                                AWUSER   == {AWUSER_WIDTH{1'b0}} &&
                                /* AXI4-Lite does not support AXI IDs. This means
                                 * all transactions must be in order, and all
                                 * accesses use a single fixed ID value. */
                                AWID     == {ID_WIDTH{1'b0}});

   logic aw_full_width_transaction;
   generate
      if(STRB_WIDTH > 1) begin: aw_full_width_addr
         assign aw_full_width_transaction =
           (AWSIZE == MAX_SIZE) && (AWADDR[MAX_SIZE-1:0] == '0);
      end
      else begin: aw_full_width_addr
         assign aw_full_width_transaction = (AWSIZE == 3'b000);
      end
   endgenerate

   /* Upper 4 bits are never set for AxLEN <= 16.
    * it can also be: let FIXED_len = ((AWLEN == [0:15])) */
   wire AW_FIXED_len = AWLEN[7:4] == 4'b000;
   logic [ADDRESS_WIDTH-1:0] end_addr;
   logic aw_4KB_boundary;
   generate
      if(PROTOCOL_TYPE == AXI4FULL && ADDRESS_WIDTH > 12) begin
	 /* The calculation of the end address of an incremental burst depends on AxSIZE,
	  * AxADDR and AxLEN as follows:
	  * end_address = AxADDR[ADDR_WIDTH-1:AxSIZE] + {AxLEN, AxSIZE}, for each AxSIZE.
	  * The concatenation between AxLEN and AxSIZE can be represented with a shift
	  * operation: AxLEN << AxSIZE. This simplifies the logic a bit (instead of
	  * creating: case(AxSIZE) [..] 'd4: end_address = {AxADDR[ADDR_WIDTH-1:4], 4'h0}
	  * {AxLEN, 4'h0} [...] for each AxSIZE, the same can be achieved by a simple
	  * comb logic: always_comb end_addr = AxADDR + (AxLEN << AxSIZE).
	  * Finally we make sure that AWADDR-1:12 bits are stable,
	  * otherwise this is a violation. */
	 always_comb begin
	    end_addr = (AWADDR + (AWLEN << AWSIZE));
	    aw_4KB_boundary = AWADDR[ADDRESS_WIDTH-1:12] == end_addr[ADDRESS_WIDTH-1:12];
	 end
      end // if (ADDRESS_WIDTH > 12)
   endgenerate

   logic m_bit;
   logic ra_bit;
   logic wa_bit;

   always_comb begin
      // Modifiable bit (renamed from <cacheable> (AXI3)), see A4.3.1
      m_bit = AWCACHE[1];
      // Read-allocate bit
      ra_bit = AWCACHE[2];
      // Write-allocate bit
      wa_bit = AWCACHE[3];
   end


   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *            Section B1.1: Definition of AXI4-Lite                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4LITE) begin
	 // Configure the AXI4-Lite checker unsupported signals.
         always @(posedge ACLK) begin
            cp_AW_unsupported_axi4l: assume (`AMBA_AXI4L_UNSUPPORTED_SIG(AW_unsupported_sig));
         end

         // Guard correct AXI4-Lite DATA_WIDTH since the parameter is used here.
         if(CHECK_PARAMETERS == 1) begin
            `AMBA_AXI4L_ASSERT_DATABUS_WIDTH(ap_AW_AXI4LITE_DATAWIDTH, ACLK, DATA_WIDTH)

         end
      end
   endgenerate

   /*		 ><><><><><><><><><><><><><><><><><><><><             *
    *		                   AWID                               *
    *		 ><><><><><><><><><><><><><><><><><><><><	      */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(INTERFACE_REQS == 1'b1) begin
	    if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	       `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWID, ACLK, ARESETn, AWVALID, AWREADY, AWID)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWID_X, ACLK, ARESETn, AWVALID, AWID)

	       end
	    end
	    else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	       `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWID, ACLK, ARESETn, AWVALID, AWREADY, AWID)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWID_X, ACLK, ARESETn, AWVALID, AWID)

	       end
	    end
	 end
      end
   endgenerate

   /*		 ><><><><><><><><><><><><><><><><><><><><             *
    *		                  AWADDR                              *
    *		 ><><><><><><><><><><><><><><><><><><><><	      */
   generate
      if(INTERFACE_REQS == 1'b1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWADDR, ACLK, ARESETn, AWVALID, AWREADY, AWADDR)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWADDR_X, ACLK, ARESETn, AWVALID, AWADDR)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWADDR, ACLK, ARESETn, AWVALID, AWREADY, AWADDR)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWADDR_X, ACLK, ARESETn, AWVALID, AWADDR)

	    end
	 end
      end

      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    if(ADDRESS_WIDTH > 12) begin
	       `AMBA_AXI4_ASSERT_BURST_CACHE_LINE_BOUNDARY(ap_AW_AWADDR_BOUNDARY_4KB, ACLK, ARESETn, AWVALID, AWBURST, aw_4KB_boundary)

	    end
	    if(BURST_SIZE_MAX >= 1 && INTERFACE_REQS == 1'b1) begin
	       `AMBA_AXI4_ASSERT_START_ADDRESS_ALIGN(ap_AW_ADDRESS_ALIGNMENT, ACLK, ARESETn, AWVALID, AWBURST, AWADDR[6:0], AWSIZE)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(ADDRESS_WIDTH > 12) begin
	       `AMBA_AXI4_ASSUME_BURST_CACHE_LINE_BOUNDARY(cp_AW_AWADDR_BOUNDARY_4KB, ACLK, ARESETn, AWVALID, AWBURST, aw_4KB_boundary)

	    end
	    if(BURST_SIZE_MAX >= 1 && INTERFACE_REQS == 1'b1) begin
	       `AMBA_AXI4_ASSUME_START_ADDRESS_ALIGN(cp_AW_ADDRESS_ALIGNMENT, ACLK, ARESETn, AWVALID, AWBURST, AWADDR[6:0], AWSIZE)

	    end
	 end
	 if(OPTIONAL_WSTRB == 1) begin
	    if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             ap_AW_FULL_WIDTH_TRANSACTION_OPTIONAL_WSTRB: assert (!(AWVALID) || (aw_full_width_transaction));
	          end
	       end

	    end
	    else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             cp_AW_FULL_WIDTH_TRANSACTION_OPTIONAL_WSTRB: assume (!(AWVALID) || (aw_full_width_transaction));
	          end
	       end

	    end
	 end
      end
   endgenerate

   /*		 ><><><><><><><><><><><><><><><><><><><><             *
    *		                   AWLEN                              *
    *		 ><><><><><><><><><><><><><><><><><><><><	      */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 if(CHECK_PARAMETERS) begin
	    always @(posedge ACLK) begin
	       ap_AW_AWLEN_MAX: assert (AWLEN < WRITE_BURST_MAX);
	    end

	    always @(posedge ACLK) begin
	       ap_AW_AWLEN_MAX_WR_BURST_LEN: assert (!(AWVALID) || (AWLEN < MAX_WR_LENGTH));
	    end

	 end
	 if(INTERFACE_REQS) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWLEN, ACLK, ARESETn, AWVALID, AWREADY, AWLEN)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWLEN_X, ACLK, ARESETn, AWVALID, AWLEN)

	    end
	 end
	 `AMBA_AXI4_ASSERT_VALID_WRAP_BURST_LENGTH(ap_AW_VALID_WRAP_BURST, ACLK, ARESETn, AWVALID, AWBURST, AWLEN)

	 `AMBA_AXI4_ASSERT_SUPPORTED_BURST_TRANSFER(ap_AW_VALID_LEN_FIXED, ACLK, ARESETn, AWVALID, AWBURST, FIXED, AW_FIXED_len)

	 if(EXCLUSIVE_ACCESS) begin
	    `AMBA_AXI4_ASSERT_VALID_BURST_LEN_EXCLUSIVE(ap_AW_VALID_BURST_LEN_EXCLUSIVE, ACLK, ARESETn, AWVALID, AWLOCK, AWLEN)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 if(CHECK_PARAMETERS) begin
	    always @(posedge ACLK) begin
	       cp_AW_AWLEN_MAX: assume (AWLEN < WRITE_BURST_MAX);
	    end

	    always @(posedge ACLK) begin
	       cp_AW_AWLEN_MAX_WR_BURST_LEN: assume (!(AWVALID) || (AWLEN < MAX_WR_LENGTH));
	    end

	 end
	 if(INTERFACE_REQS) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWLEN, ACLK, ARESETn, AWVALID, AWREADY, AWLEN)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWLEN_X, ACLK, ARESETn, AWVALID, AWLEN)

	    end
	 end
	 `AMBA_AXI4_ASSUME_VALID_WRAP_BURST_LENGTH(cp_AW_VALID_WRAP_BURST, ACLK, ARESETn, AWVALID, AWBURST, AWLEN)

	 `AMBA_AXI4_ASSUME_SUPPORTED_BURST_TRANSFER(cp_AW_VALID_LEN_FIXED, ACLK, ARESETn, AWVALID, AWBURST, FIXED, AW_FIXED_len)

         if(EXCLUSIVE_ACCESS) begin
            `AMBA_AXI4_ASSUME_VALID_BURST_LEN_EXCLUSIVE(cp_AW_VALID_BURST_LEN_EXCLUSIVE, ACLK, ARESETn, AWVALID, AWLOCK, AWLEN)

	 end
      end // if (((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT)))
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWSIZE                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    if(INTERFACE_REQS == 1'b1) begin
               `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWSIZE, ACLK, ARESETn, AWVALID, AWREADY, AWSIZE)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWSIZE_X, ACLK, ARESETn, AWVALID, AWSIZE)

	       end
	    end
	    `AMBA_AXI4_ASSERT_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(ap_AW_CORRECT_BURST_SIZE, ACLK, ARESETn, AWVALID, AWSIZE, STRB_WIDTH)

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(INTERFACE_REQS) begin
	       `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWSIZE, ACLK, ARESETn, AWVALID, AWREADY, AWSIZE)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWSIZE_X, ACLK, ARESETn, AWVALID, AWSIZE)

	       end
	       `AMBA_AXI4_ASSUME_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(cp_AW_CORRECT_BURST_SIZE, ACLK, ARESETn, AWVALID, AWSIZE, STRB_WIDTH)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              AWBURST                            *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    if(INTERFACE_REQS == 1'b1) begin
	       `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWBURST, ACLK, ARESETn, AWVALID, AWREADY, AWBURST)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWBURST_X, ACLK, ARESETn, AWVALID, AWBURST)

	       end
	    end
	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          ap_AW_BURST_TYPES: assert (!(AWVALID) || (AWBURST != RESERVED));
	       end
	    end

         end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(INTERFACE_REQS == 1'b1) begin
	       `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWBURST, ACLK, ARESETn, AWVALID, AWREADY, AWBURST)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWBURST_X, ACLK, ARESETn, AWVALID, AWBURST)

	       end
	    end
	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          cp_AW_BURST_TYPES: assume (!(AWVALID) || (AWBURST != RESERVED));
	       end
	    end

	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWLOCK                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(INTERFACE_REQS == 1'b1) begin
	    if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	       `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWLOCK, ACLK, ARESETn, AWVALID, AWREADY, AWLOCK)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWLOCK_X, ACLK, ARESETn, AWVALID, AWLOCK)

	       end
	    end
	    else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	       `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWLOCK, ACLK, ARESETn, AWVALID, AWREADY, AWLOCK)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWLOCK_X, ACLK, ARESETn, AWVALID, AWLOCK)

	       end
	    end
	 end
      end
      if(PROTOCOL_TYPE == AXI4LITE) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4L_ASSERT_UNSUPPORTED_EXCLUSIVE_ACCESS(ap_AW_UNSUPPORTED_EXCLUSIVE, ACLK, ARESETn, AWVALID, AWLOCK, EXCLUSIVE)

         end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4L_ASSUME_UNSUPPORTED_EXCLUSIVE_ACCESS(cp_AW_UNSUPPORTED_EXCLUSIVE, ACLK, ARESETn, AWVALID, AWLOCK, EXCLUSIVE)

         end
      end // if (PROTOCOL_TYPE == AXI4LITE)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWCACHE                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    if(INTERFACE_REQS == 1'b1) begin
	       `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWCACHE, ACLK, ARESETn, AWVALID, AWREADY, AWCACHE)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWCACHE_X, ACLK, ARESETn, AWVALID, AWCACHE)

	       end
	    end
	    `AMBA_AXI4_ASSERT_MEMORY_TYPE_ENCODING(ap_AW_MEMORY_TYPE_ENCODING, ACLK, ARESETn, AWVALID, AWCACHE)

	    always @(posedge ACLK) begin
	       ap_AW_NON_CACHEABLE: assert (!(AWVALID && !m_bit) || ({ra_bit, wa_bit} == 2'b00));
	    end

	    if(EXCLUSIVE_ACCESS) begin
	       always @(posedge ACLK) begin
	          ap_AW_EXCLUSIVE_NON_CACHEABLE: assert (!(AWVALID && AWLOCK == EXCLUSIVE) || ({ra_bit, wa_bit} == 2'b00));
	       end

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(INTERFACE_REQS == 1'b1) begin
               `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWCACHE, ACLK, ARESETn, AWVALID, AWREADY, AWCACHE)

	       if(ENABLE_XPROP) begin
		  `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWCACHE_X, ACLK, ARESETn, AWVALID, AWCACHE)

	       end
	    end
	    `AMBA_AXI4_ASSUME_MEMORY_TYPE_ENCODING(cp_AW_MEMORY_TYPE_ENCODING, ACLK, ARESETn, AWVALID, AWCACHE)

	    always @(posedge ACLK) begin
	       cp_AW_NON_CACHEABLE: assume (!(AWVALID && !m_bit) || ({ra_bit, wa_bit} == 2'b00));
	    end

	    if(EXCLUSIVE_ACCESS) begin
	       always @(posedge ACLK) begin
	          cp_AW_EXCLUSIVE_NON_CACHEABLE: assume (!(AWVALID && AWLOCK == EXCLUSIVE) || ({ra_bit, wa_bit} == 2'b00));
	       end

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWPROT                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(INTERFACE_REQS == 1'b1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWPROT, ACLK, ARESETn, AWVALID, AWREADY, AWPROT)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWPROT_X, ACLK, ARESETn, AWVALID, AWPROT)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWPROT, ACLK, ARESETn, AWVALID, AWREADY, AWPROT)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWPROT_X, ACLK, ARESETn, AWVALID, AWPROT)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWQOS                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL && INTERFACE_REQS == 1'b1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWQOS, ACLK, ARESETn, AWVALID, AWREADY, AWQOS)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWQOS_X, ACLK, ARESETn, AWVALID, AWQOS)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWQOS, ACLK, ARESETn, AWVALID, AWREADY, AWQOS)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWQOS_X, ACLK, ARESETn, AWVALID, AWQOS)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWREGION                            *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL && INTERFACE_REQS == 1'b1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWREGION, ACLK, ARESETn, AWVALID, AWREADY, AWREGION)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWREGION_X, ACLK, ARESETn, AWVALID, AWREGION)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWREGION, ACLK, ARESETn, AWVALID, AWREADY, AWREGION)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWREGION_X, ACLK, ARESETn, AWVALID, AWREGION)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWUSER                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL && INTERFACE_REQS == 1'b1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AW_STABLE_AWUSER, ACLK, ARESETn, AWVALID, AWREADY, AWUSER)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWUSER_X, ACLK, ARESETn, AWVALID, AWUSER)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AW_STABLE_AWUSER, ACLK, ARESETn, AWVALID, AWREADY, AWUSER)

	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWUSER_X, ACLK, ARESETn, AWVALID, AWUSER)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWVALID                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(OPTIONAL_RESET == 1 && INTERFACE_REQS == 1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_EXIT_FROM_RESET(ap_AW_EXIT_RESET, ACLK, ARESETn, AWVALID)

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_EXIT_FROM_RESET(cp_AW_EXIT_RESET, ACLK, ARESETn, AWVALID)

	 end
      end
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(ap_AW_AWVALID_until_AWREADY, ACLK, ARESETn, AWVALID, AWREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWVALID_X, ACLK, ARESETn, ARESETn, AWVALID)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(cp_AW_AWVALID_until_AWREADY, ACLK, ARESETn, AWVALID, AWREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWVALID_X, ACLK, ARESETn, ARESETn, AWVALID)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             AWREADY                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 if(INTERFACE_REQS == 1'b1) begin
	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AW_AWREADY_X, ACLK, ARESETn, ARESETn, AWREADY)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(ENABLE_XPROP) begin
	       `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AW_AWREADY_X, ACLK, ARESETn, ARESETn, AWREADY)

	    end
	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                        AMBA Recommended                         *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(ARM_RECOMMENDED == 1) begin
	 if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT(ap_AW_READY_MAXWAIT, ACLK, ARESETn, AWVALID, AWREADY, MAXWAIT)

	 end
	 else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT(cp_AW_READY_MAXWAIT, ACLK, ARESETn, AWVALID, AWREADY, MAXWAIT)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *              Covers To Maximise Debug Information               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   // Witnessing scenarios stated in the AMBA AXI4 spec
   generate
      if(ENABLE_COVER == 1) begin: witness
	 // For witness
	 wire AW_request_accepted = AWVALID && AWREADY;
	 // Single handshake
// OSS conversion: original sequence kept as comment.
// 	 sequence aw_handshake_cond(cond);
// 	    AWVALID ##0 AWREADY ##0 cond;
// 	 endsequence // aw_burst_size

	 /* This sequence looks for two handshakes
	  * and is used to witness a transaction
	  * process where two request are made
	  * with different ID. */
// OSS conversion: original sequence kept as comment.
// 	 sequence aw_two_handshakes;
// 	    AWVALID ##0 AWREADY ##1
// 	    AWVALID ##0 AWREADY;
// 	 endsequence // aw_two_handshakes

	 /* ,         ,                                                     *
	  * |\\\\ ////|  "The length of the burst must be 2, 4, 8, or 16    *
	  * | \\\V/// |   transfers".                                       *
	  * |  |~~~|  |                                                     *
	  * |  |===|  |   Ref: A3.4 Transaction structure, Burst type WRAP, *
	  * |  |A  |  |   pA3-48.                                           *
	  * |  | X |  |                                                     *
	  *  \ |  I| /                                                      *
	  *   \|===|/                                                       *
	  *    '---'                                                        */
// OSS conversion: original sequence kept as comment.
// 	 sequence wrapping_burst_len(l);
// 	    AWVALID ##0 AWREADY ##0 AWBURST == WRAP
// 	    ##0 AWLEN == l;
// 	 endsequence // wrapping_burst_len

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *          Section A3.4.3 Data read and write structure           *
	  *            ><><><><><><><><><><><><><><><><><><><><             */

	 /* ,         ,                                                     *
	  * |\\\\ ////|  "AXI supports unaligned transfers. [...],          *
	  * | \\\V/// |   A source can: use the low-order address lines to  *
	  * |  |~~~|  |   signal an unaligned start address".               *
	  * |  |===|  |   Ref: A3.4.3 Address structure, Unaligned,         *
	  * |  |A  |  |        transfers, pA3-54.                           *
	  * |  | X |  |                                                     *
	  *  \ |  I| /                                                      *
	  *   \|===|/                                                       *
	  *    '---'                                                        */
// OSS conversion: original sequence kept as comment.
// 	 sequence unaligned_transfer(a, t);
// 	    AWVALID ##0 AWREADY ##0 AWSIZE == SIZE2B
// 	    ##0 AWADDR[a] == 1'b1 ##0 AWBURST == t;
// 	 endsequence // unaligned_transfer

	 /* ,         ,                                                     *
	  * |\\\\ ////|  "The number of bytes to be transferred in an       *
	  * | \\\V/// |   exclusive access burst must be a power of 2, that *
	  * |  |~~~|  |   is, 1, 2, 4, 8, 16, 32, 64, or 128 bytes".        *
	  * |  |===|  |   Ref: A7.2.4 Exclusive access restrictions, pA7-97 *
	  * |  |A  |  |                                                     *
	  * |  | X |  |                                                     *
	  *  \ | I | /	                                                    *
	  *   \|===|/							    *
	  *    '---'							    */
// OSS conversion: original sequence kept as comment.
// 	 sequence exclusive_access_byte_transfer(size, len);
// 	    AWVALID ##0 AWREADY ##0 AWLOCK == EXCLUSIVE
// 	    ##0 AWSIZE == size ##0 AWLEN == len;
// 	 endsequence // exclusive_access_byte_transfer

	 /*		 ><><><><><><><><><><><><><><><><><><><><             *
	  *		                   AWID                               *
	  *		 ><><><><><><><><><><><><><><><><><><><><	      */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       reg wp_TWO_TRANSACTIONS_DIFFERENT_AWID_past_valid = 1'b0;
	       always @(posedge ACLK) begin
	          wp_TWO_TRANSACTIONS_DIFFERENT_AWID_past_valid <= 1'b1;
	          if (wp_TWO_TRANSACTIONS_DIFFERENT_AWID_past_valid) begin
	             wp_TWO_TRANSACTIONS_DIFFERENT_AWID: cover (($past((AWVALID)) && $past((AWREADY)) && (AWVALID) && (AWREADY)) && (AWID != $past(AWID)));
	          end
	       end

	       for(genvar idx = 0; idx < (2**ID_WIDTH); idx++) begin: wp_AWID_TAG_NUMBER
		  amba_axi4_write_address_channel__oss_cover__wp_AWID_TAG_NUMBER oss_cover_inst_wp_AWID_TAG_NUMBER (
		     .ACLK(ACLK),
		     .cond(((AWVALID) && (AWREADY) && ((AWID == idx))))
		  );

	       end
	    end
	 end

	 /*		 ><><><><><><><><><><><><><><><><><><><><             *
	  *		                  AWADDR                              *
	  *		 ><><><><><><><><><><><><><><><><><><><><	      */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       always @(posedge ACLK) begin
	          wp_UNALIGNED_TRANSFERS_FIXED_BURST: cover ((AWVALID) && (AWREADY) && (AWSIZE == SIZE2B) && (AWADDR[(0)] == 1'b1) && (AWBURST == (FIXED)));
	       end

	       always @(posedge ACLK) begin
	          wp_UNALIGNED_TRANSFERS_INCR_BURST: cover ((AWVALID) && (AWREADY) && (AWSIZE == SIZE2B) && (AWADDR[(1)] == 1'b1) && (AWBURST == (INCR)));
	       end

	    end
	 end

	 /*		 ><><><><><><><><><><><><><><><><><><><><             *
	  *		                   AWLEN                              *
	  *		 ><><><><><><><><><><><><><><><><><><><><	      */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       for(genvar i = 0; i <= MAX_WR_LENGTH-1; i++) begin: wp_AW_LEN_TRANSFERS
		  amba_axi4_write_address_channel__oss_cover__wp_AW_LEN_TRANSFERS oss_cover_inst_wp_AW_LEN_TRANSFERS (
		     .ACLK(ACLK),
		     .cond((AW_request_accepted && AWLEN == i[7:0]))
		  );

	       end
	       /* TODO: Bring here outstanding transaction counters to create covers for
		* first transactions with different AWLEN values. */
	       for(genvar len = 2; len <= MAX_WR_LENGTH; len = len * 2) begin: wp_WRAPPING_BURST_LEN
		  amba_axi4_write_address_channel__oss_cover__wp_WRAPPING_BURST_LEN oss_cover_inst_wp_WRAPPING_BURST_LEN (
		     .ACLK(ACLK),
		     .cond(((AWVALID) && (AWREADY) && (AWBURST == WRAP) && (AWLEN == ((len -  1'b1)))))
		  );

	       end
	    end // if (PROTOCOL_TYPE == AXI4FULL)
	 end // if (VERIFY_AGENT_TYPE != DESTINATION)

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                             AWSIZE                              *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       /* As stated in Table A3-2 Burst size encoding,
		* BURST_SIZE_MAX (calculated with WSTRB) is the
		* maximum number of bytes to transfer in each beat.
		* This sequence helps to check that the model can
		* accept such burst transfer sizes. */
	       for(genvar j = 0; j <= BURST_SIZE_MAX; j++) begin: wp_MAX_BURST_SIZE
		  amba_axi4_write_address_channel__oss_cover__wp_MAX_BURST_SIZE oss_cover_inst_wp_MAX_BURST_SIZE (
		     .ACLK(ACLK),
		     .cond((ARESETn) && ((AWVALID) && (AWREADY) && ((AWSIZE == j))))
		  );

	       end
	    end // if (PROTOCOL_TYPE == AXI4FULL)
	 end // if (VERIFY_AGENT_TYPE != DESTINATION)

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                              AWBURST                            *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_BURST_FIXED: cover ((AWVALID) && (AWREADY) && ((AWBURST == FIXED)));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_BURST_INCR: cover ((AWVALID) && (AWREADY) && ((AWBURST == INCR)));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_BURST_WRAP: cover ((AWVALID) && (AWREADY) && ((AWBURST == WRAP)));
	          end
	       end

	    end
	 end

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                             AWLOCK                              *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AWLOCK_NORMAL: cover ((AWVALID) && (AWREADY) && ((AWLOCK == NORMAL)));
	          end
	       end

	       if(EXCLUSIVE_ACCESS) begin
		  always @(posedge ACLK) begin
		     if (ARESETn) begin
		        wp_AWLOCK_EXCLUSIVE: cover ((AWVALID) && (AWREADY) && ((AWLOCK == EXCLUSIVE)));
		     end
		  end

		  for(genvar i = 0; i <= BURST_SIZE_MAX; i++) begin: transfer_size
		     amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE1B oss_cover_inst_wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE1B (
		        .ACLK(ACLK),
		        .cond(((AWVALID) && (AWREADY) && (AWLOCK == EXCLUSIVE) && (AWSIZE == (SIZE1B)) && (AWLEN == (((2**i)-1)))))
		     );

		     amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE2B oss_cover_inst_wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE2B (
		        .ACLK(ACLK),
		        .cond(((AWVALID) && (AWREADY) && (AWLOCK == EXCLUSIVE) && (AWSIZE == (SIZE2B)) && (AWLEN == (((2**i)-1)))))
		     );

		     amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE4B oss_cover_inst_wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE4B (
		        .ACLK(ACLK),
		        .cond(((AWVALID) && (AWREADY) && (AWLOCK == EXCLUSIVE) && (AWSIZE == (SIZE4B)) && (AWLEN == (((2**i)-1)))))
		     );

		     amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE8B oss_cover_inst_wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE8B (
		        .ACLK(ACLK),
		        .cond(((AWVALID) && (AWREADY) && (AWLOCK == EXCLUSIVE) && (AWSIZE == (SIZE8B)) && (AWLEN == (((2**i)-1)))))
		     );

		  end
	       end // if (EXCLUSIVE_ACCESS)
	    end // if (PROTOCOL_TYPE == AXI4FULL)
	 end // if (VERIFY_AGENT_TYPE != DESTINATION)

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                             AWCACHE                             *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       always @(posedge ACLK) begin
	          wp_AWCACHE_NON_BUFFERABLE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h0)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_BUFFERABLE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h1)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h2)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h3)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_THROUGH_NO_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h6)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'hA)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'hE)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_BACK_READ_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'h7)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_BACK_WRITE_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'hB)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE: cover ((AWVALID) && (AWREADY) && ((AWCACHE == 4'hF)));
	       end

	       always @(posedge ACLK) begin
	          wp_ATOMIC_WRITE_NONCACHEABLE_mbit: cover ((AWVALID) && (AWREADY) && ((AWLOCK == EXCLUSIVE && !m_bit)));
	       end

	    end // if (PROTOCOL_TYPE == AXI4FULL)
	 end // if (VERIFY_AGENT_TYPE != DESTINATION)

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                             AWPROT                              *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
	    if(PROTOCOL_TYPE == AXI4FULL) begin
	       always @(posedge ACLK) begin
	          wp_AWPROT_UNPRIVILEGED_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[0] == 1'b0)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWPROT_PRIVILEGED_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[0] == 1'b1)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWPROT_SECURE_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[1] == 1'b0)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWPROT_NON_SECURE_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[1] == 1'b1)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWPROT_DATA_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[2] == 1'b0)));
	       end

	       always @(posedge ACLK) begin
	          wp_AWPROT_INSTRUCTION_ACCESS: cover ((AWVALID) && (AWREADY) && ((AWPROT[2] == 1'b1)));
	       end

	    end // if (PROTOCOL_TYPE == AXI4FULL)
	 end // if (VERIFY_AGENT_TYPE != DESTINATION)

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                             AWREADY                             *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
         `AMBA_AXI4_COVER_VALID_BEFORE_READY(wp_AWVALID_before_AWREADY, ACLK, ARESETn, AWVALID, AWREADY)

         `AMBA_AXI4_COVER_READY_BEFORE_VALID(wp_AWREADY_before_AWVALID, ACLK, ARESETn, AWVALID, AWREADY)

         `AMBA_AXI4_COVER_VALID_WITH_READY(wp_AWVALID_with_AWREADY, ACLK, ARESETn, AWVALID, AWREADY)

	 if(MAX_WR_BURSTS > 1) begin
            `AMBA_AXI4_COVER_BACK_TO_BACK(wp_AW_B2B, ACLK, ARESETn, AWVALID, AWREADY)

	 end
         `AMBA_AXI4_COVER_WAIT_STATE(wp_AW_WAIT, ACLK, ARESETn, AWVALID, AWREADY)

         `AMBA_AXI4_COVER_NO_WAIT_STATE(wp_AW_NO_WAIT, ACLK, ARESETn, AWVALID, AWREADY)

      end // block: witness
   endgenerate
endmodule // amba_axi4_write_address_channel
`default_nettype wire

module amba_axi4_write_address_channel__oss_cover__wp_AWID_TAG_NUMBER (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_AWID_TAG_NUMBER: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_AW_LEN_TRANSFERS (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_AW_LEN_TRANSFERS: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_WRAPPING_BURST_LEN (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_WRAPPING_BURST_LEN: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_MAX_BURST_SIZE (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_MAX_BURST_SIZE: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE1B (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE1B: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE2B (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE2B: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE4B (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE4B: cover (cond);
   end
endmodule

module amba_axi4_write_address_channel__oss_cover__wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE8B (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_EXCLUSIVE_ACCESS_BYTE_TRANSFER_SIZE8B: cover (cond);
   end
endmodule
