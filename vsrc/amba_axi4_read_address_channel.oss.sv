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
module amba_axi4_read_address_channel #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 32,
   parameter int unsigned ARUSER_WIDTH = 32,
   parameter int unsigned MAX_RD_BURSTS = 2,
   parameter int unsigned MAX_RD_LENGTH = 8,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit EXCLUSIVE_ACCESS = 1'b1,
   // Read only
     localparam unsigned STRB_WIDTH = DATA_WIDTH/8,
     localparam unsigned BURST_SIZE_MAX = $clog2(STRB_WIDTH),
     localparam unsigned READ_BURST_MAX = 256
)
   (input wire                         ACLK,
    input wire 			       ARESETn,
    input wire [ID_WIDTH-1:0]      ARID,
    input wire [ADDRESS_WIDTH-1:0] ARADDR,
    input wire [7:0] 		       ARLEN,
    input wire [2:0] 		       ARSIZE,
    input wire [1:0] 		       ARBURST,
    input wire 			       ARLOCK,
    input wire [3:0] 		       ARCACHE,
    input wire [2:0] 		       ARPROT,
    input wire [3:0] 		       ARQOS,
    input wire [3:0] 		       ARREGION,
    input wire [ARUSER_WIDTH-1:0]  ARUSER,
    input wire 			       ARVALID,
    input wire 			       ARREADY);

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
   logic AR_unsupported_sig;
   assign AR_unsupported_sig = (/* The burst length is defined to be 1,
				 * equivalent to an AxLEN value of zero. */
				ARLEN    == 8'b00000000 &&
				/* All accesses are defined to be the width
				 * of the data bus. */
				ARSIZE   == BURST_SIZE_MAX &&
				/* The burst type has no meaning because the burst
				 * length is 1. */
				ARBURST  == 2'b00 &&
				/* All accesses are defined as Normal accesses,
				 * equivalent to an AxLOCK value of zero. */
				ARLOCK   == 1'b0 &&
				/* All accesses are defined as Non-modifiable,
				 * Non-bufferable, equivalent to an AxCACHE
				 * value of 0b0000. */
				ARCACHE  == 4'b0000 &&
				/* A default value of 0b0000 indicates that
				 * the interface is not participating in any
				 * QoS scheme. */
				ARQOS    == 4'b0000 &&
				/* Table A10-1 Master interface write channel
				 * signals and default signal values.
				 * AWREGION Default all zeros. */
				ARREGION == 4'b0000 &&
				/* Optional User-defined signal in the write address channel.
				 * Supported only in AXI4. */
				ARUSER   == {ARUSER_WIDTH{1'b0}} &&
	                        /* AXI4-Lite does not support AXI IDs. This means
	                         * all transactions must be in order, and all
	                         * accesses use a single fixed ID value. */
	                        ARID     == {ID_WIDTH{1'b0}});

   /* Upper 4 bits are never set for AxLEN <= 16.
    * it can also be: let FIXED_len = ((ARLEN == [0:15])) */
   wire AR_FIXED_len = ARLEN[7:4] == 4'b000;
   logic [ADDRESS_WIDTH-1:0] end_addr;
   logic ar_4KB_boundary;
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
	    end_addr = (ARADDR + (ARLEN << ARSIZE));
	    ar_4KB_boundary = ARADDR[ADDRESS_WIDTH-1:12] == end_addr[ADDRESS_WIDTH-1:12];
	 end
      end // if (ADDRESS_WIDTH > 12)
   endgenerate

   logic m_bit;
   logic ra_bit;
   logic wa_bit;

   always_comb begin
      // Modifiable bit (renamed from <cacheable> (AXI3)), see A4.3.1
      m_bit = ARCACHE[1];
      // Read-allocate bit
      ra_bit = ARCACHE[2];
      // Write-allocate bit
      wa_bit = ARCACHE[3];
   end

   typedef struct packed {
      /* A burst must not cross a
       * 4KB address boundary (pA3-46). */
      bit [11:0] raddr_total_bytes;
      /* The maximum number of bytes
       * that can be transferred in an
       * exclusive burst is 128. (pA7-97). */
      bit [11:0] raddr_mask_exclusive;
      /* Aligment is correct if LSB bits of
       * based on araddr & arlen & arsize are LOW. */
      bit raddr_exclusive_aligned;
   } raddr_exclusive_alignment_dbg;
   raddr_exclusive_alignment_dbg raddr_excl_align;
   bit ar_excl_align;

   always_comb begin
      // Get the total bytes of the transaction
      raddr_excl_align.raddr_total_bytes = ((ARLEN + 1'b1) << ARSIZE);
      // Now calculate the mask, that is, remove the 1 appended to ARLEN (for debugging purposes)
      raddr_excl_align.raddr_mask_exclusive = raddr_excl_align.raddr_total_bytes - 1'b1;
      // Check that LSB bits are LOW
      raddr_excl_align.raddr_exclusive_aligned = ((raddr_excl_align.raddr_mask_exclusive &
						   ARADDR[10:0]) == 1'b0);
      ar_excl_align = raddr_excl_align.raddr_exclusive_aligned;
   end

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *            Section B1.1: Definition of AXI4-Lite                *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4LITE) begin: axi4lite_defs
         // Configure the AXI4-Lite checker unsupported signals.
	 `AMBA_AXI4L_ASSUME_UNSUPPORTED_SIG(cp_AR_unsupported_axi4l, ACLK, ARESETn, AR_unsupported_sig)

	 // Guard correct AXI4-Lite DATA_WIDTH since the parameter is used here.
         if(CHECK_PARAMETERS == 1) begin: check_dataw
            `AMBA_AXI4L_ASSERT_DATABUS_WIDTH(ap_AR_AXI4LITE_DATAWIDTH, ACLK, DATA_WIDTH)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARID                               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
         if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_AWID, ACLK, ARESETn, ARVALID, ARREADY, ARID)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARID_X, ACLK, ARESETn, ARVALID, ARID)

            end
         end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARID, ACLK, ARESETn, ARVALID, ARREADY, ARID)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARID_X, ACLK, ARESETn, ARVALID, ARID)

            end
         end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARADDR                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARADDR, ACLK, ARESETn, ARVALID, ARREADY, ARADDR)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARADDR_X, ACLK, ARESETn, ARVALID, ARADDR)

         end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARADDR, ACLK, ARESETn, ARVALID, ARREADY, ARADDR)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARADDR_X, ACLK, ARESETn, ARVALID, ARADDR)

         end
      end
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    if(ADDRESS_WIDTH > 12) begin
	       `AMBA_AXI4_ASSERT_BURST_CACHE_LINE_BOUNDARY(ap_AR_ARADDR_BOUNDARY_4KB, ACLK, ARESETn, ARVALID, ARBURST, ar_4KB_boundary)

	    end
	    if(BURST_SIZE_MAX >= 1) begin
	       `AMBA_AXI4_ASSERT_START_ADDRESS_ALIGN(ap_AR_ADDRESS_ALIGMENT, ACLK, ARESETn, ARVALID, ARBURST, ARADDR[6:0], ARSIZE)

	    end
	    if(EXCLUSIVE_ACCESS == 1) begin
	       `AMBA_AXI4_ASSERT_EXCLUSIVE_ACCESS_ADDR_ALIGN(ap_AR_ADDRESS_ALIGNMENT_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLEN, ARLOCK, ar_excl_align)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    if(ADDRESS_WIDTH > 12) begin
	       `AMBA_AXI4_ASSUME_BURST_CACHE_LINE_BOUNDARY(cp_AR_ARADDR_BOUNDARY_4KB, ACLK, ARESETn, ARVALID, ARBURST, ar_4KB_boundary)

	    end
	    if(BURST_SIZE_MAX >= 1) begin
	       `AMBA_AXI4_ASSUME_START_ADDRESS_ALIGN(cp_AR_address_alignment, ACLK, ARESETn, ARVALID, ARBURST, ARADDR[6:0], ARSIZE)

	    end
	    if(EXCLUSIVE_ACCESS == 1) begin
	       `AMBA_AXI4_ASSUME_EXCLUSIVE_ACCESS_ADDR_ALIGN(cp_AR_ADDRESS_ALIGNMENT_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLEN, ARLOCK, ar_excl_align)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARLEN                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   if(PROTOCOL_TYPE == AXI4FULL) begin
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 if(CHECK_PARAMETERS) begin
	    always @(posedge ACLK) begin
	       ap_AR_ARLEN_MAX: assert (ARLEN < READ_BURST_MAX);
	    end

	    always @(posedge ACLK) begin
	       ap_AR_ARLEN_MAX_RD_BURST_LEN: assert (!(ARVALID) || (ARLEN < MAX_RD_LENGTH));
	    end

	 end
         `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARLEN, ACLK, ARESETn, ARVALID, ARREADY, ARLEN)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARLEN_X, ACLK, ARESETn, ARVALID, ARLEN)

         end
	 `AMBA_AXI4_ASSERT_VALID_WRAP_BURST_LENGTH(ap_AR_VALID_WRAP_BURST, ACLK, ARESETn, ARVALID, ARBURST, ARLEN)

	 `AMBA_AXI4_ASSERT_SUPPORTED_BURST_TRANSFER(ap_AR_VALID_LEN_FIXED, ACLK, ARESETn, ARVALID, ARBURST, FIXED, AR_FIXED_len)

	 `AMBA_AXI4_ASSERT_VALID_NUMBER_BYTES_EXCLUSIVE(ap_AR_EXCLUSIVE_BYTES_TRANSFER, ACLK, ARESETn, ARVALID, ARLOCK, ARLEN)

      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 if(CHECK_PARAMETERS) begin
	    always @(posedge ACLK) begin
	       cp_AR_ARLEN_MAX: assume (ARLEN < READ_BURST_MAX);
	    end

	    always @(posedge ACLK) begin
	       cp_AR_ARLEN_MAX_RD_BURST_LEN: assume (!(ARVALID) || (ARLEN < MAX_RD_LENGTH));
	    end

	 end
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARLEN, ACLK, ARESETn, ARVALID, ARREADY, ARLEN)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARLEN_X, ACLK, ARESETn, ARVALID, ARLEN)

         end
	 `AMBA_AXI4_ASSUME_VALID_WRAP_BURST_LENGTH(cp_AR_VALID_WRAP_BURST, ACLK, ARESETn, ARVALID, ARBURST, ARLEN)

	 `AMBA_AXI4_ASSUME_SUPPORTED_BURST_TRANSFER(cp_AR_VALID_LEN_FIXED, ACLK, ARESETn, ARVALID, ARBURST, FIXED, AR_FIXED_len)

	 `AMBA_AXI4_ASSUME_VALID_NUMBER_BYTES_EXCLUSIVE(cp_AR_EXCLUSIVE_BYTES_TRANSFER, ACLK, ARESETn, ARVALID, ARLOCK, ARLEN)

      end
   end // if (PROTOCOL_TYPE == AXI4FULL)

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARSIZE                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARSIZE, ACLK, ARESETn, ARVALID, ARREADY, ARSIZE)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARSIZE_X, ACLK, ARESETn, ARVALID, ARSIZE)

            end
	    `AMBA_AXI4_ASSERT_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(ap_AR_CORRECT_BURST_SIZE, ACLK, ARESETn, ARVALID, ARSIZE, STRB_WIDTH)

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARSIZE, ACLK, ARESETn, ARVALID, ARREADY, ARSIZE)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARSIZE_X, ACLK, ARESETn, ARVALID, ARSIZE)

            end
	    `AMBA_AXI4_ASSUME_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(cp_AR_CORRECT_BURST_SIZE, ACLK, ARESETn, ARVALID, ARSIZE, STRB_WIDTH)

	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARBURST                            *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARBURST, ACLK, ARESETn, ARVALID, ARREADY, ARBURST)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARBURST_X, ACLK, ARESETn, ARVALID, ARBURST)

            end
	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          ap_AR_BURST_TYPES: assert (!(ARVALID) || (ARBURST != RESERVED));
	       end
	    end

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARBURST, ACLK, ARESETn, ARVALID, ARREADY, ARBURST)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARBURST_X, ACLK, ARESETn, ARVALID, ARBURST)

            end
	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          cp_AR_BURST_TYPES: assume (!(ARVALID) || (ARBURST != RESERVED));
	       end
	    end

	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARLOCK                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARLOCK, ACLK, ARESETn, ARVALID, ARREADY, ARLOCK)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARLOCK_X, ACLK, ARESETn, ARVALID, ARLOCK)

            end
	    `AMBA_AXI4_ASSERT_VALID_BURST_LEN_EXCLUSIVE(ap_AR_BURST_LEN_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLOCK, ARLEN)

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARLOCK, ACLK, ARESETn, ARVALID, ARREADY, ARLOCK)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARLOCK_X, ACLK, ARESETn, ARVALID, ARLOCK)

            end
	    `AMBA_AXI4_ASSUME_VALID_BURST_LEN_EXCLUSIVE(cp_AR_BURST_LEN_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLOCK, ARLEN)

	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
      if(PROTOCOL_TYPE == AXI4LITE) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4L_ASSERT_UNSUPPORTED_EXCLUSIVE_ACCESS(ap_AR_UNSUPPORTED_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLOCK, EXCLUSIVE)

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	    `AMBA_AXI4L_ASSUME_UNSUPPORTED_EXCLUSIVE_ACCESS(cp_AR_UNSUPPORTED_EXCLUSIVE, ACLK, ARESETn, ARVALID, ARLOCK, EXCLUSIVE)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARCACHE                            *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARCACHE, ACLK, ARESETn, ARVALID, ARREADY, ARCACHE)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARCACHE_X, ACLK, ARESETn, ARVALID, ARCACHE)

            end
	    `AMBA_AXI4_ASSERT_MEMORY_TYPE_ENCODING(ap_AR_MEMORY_TYPE_ENCODING, ACLK, ARESETn, ARVALID, ARCACHE)

	    always @(posedge ACLK) begin
	       ap_AR_NON_CACHEABLE: assert (!(ARVALID && ARLOCK) || ({ra_bit, wa_bit} == 2'b00));
	    end

	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARCACHE, ACLK, ARESETn, ARVALID, ARREADY, ARCACHE)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARCACHE_X, ACLK, ARESETn, ARVALID, ARCACHE)

            end
	    `AMBA_AXI4_ASSUME_MEMORY_TYPE_ENCODING(cp_AR_MEMORY_TYPE_ENCODING, ACLK, ARESETn, ARVALID, ARCACHE)

	    always @(posedge ACLK) begin
	       cp_AR_NON_CACHEABLE: assume (!(ARVALID && ARLOCK) || ({ra_bit, wa_bit} == 2'b00));
	    end

	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARPROT                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARPROT, ACLK, ARESETn, ARVALID, ARREADY, ARPROT)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARPROT_X, ACLK, ARESETn, ARVALID, ARPROT)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARPROT, ACLK, ARESETn, ARVALID, ARREADY, ARPROT)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARPROT_X, ACLK, ARESETn, ARVALID, ARPROT)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARQOS                              *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARQOS, ACLK, ARESETn, ARVALID, ARREADY, ARQOS)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARQOS_X, ACLK, ARESETn, ARVALID, ARQOS)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARQOS, ACLK, ARESETn, ARVALID, ARREADY, ARQOS)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARQOS_X, ACLK, ARESETn, ARVALID, ARQOS)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                            ARREGION                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARREGION, ACLK, ARESETn, ARVALID, ARREADY, ARREGION)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARREGION_X, ACLK, ARESETn, ARVALID, ARREGION)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARREGION, ACLK, ARESETn, ARVALID, ARREADY, ARREGION)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARREGION_X, ACLK, ARESETn, ARVALID, ARREGION)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARUSER                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(PROTOCOL_TYPE == AXI4FULL) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	    `AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(ap_AR_STABLE_ARUSER, ACLK, ARESETn, ARVALID, ARREADY, ARUSER)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARUSER_X, ACLK, ARESETn, ARVALID, ARUSER)

	    end
	 end
	 else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(cp_AR_STABLE_ARUSER, ACLK, ARESETn, ARVALID, ARREADY, ARUSER)

	    if(ENABLE_XPROP) begin
               `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARUSER_X, ACLK, ARESETn, ARVALID, ARUSER)

	    end
	 end
      end // if (PROTOCOL_TYPE == AXI4FULL)
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                              ARVALID                            *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(OPTIONAL_RESET == 1) begin
	 if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_EXIT_FROM_RESET(ap_AR_EXIT_RESET, ACLK, ARESETn, ARVALID)

	 end
         else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_EXIT_FROM_RESET(cp_AR_EXIT_RESET, ACLK, ARESETn, ARVALID)

	 end
      end // if (OPTIONAL_RESET == 1)
      if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == MONITOR))) begin
	 `AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(ap_AR_ARVALID_until_ARREADY, ACLK, ARESETn, ARVALID, ARREADY)

	 if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(ap_AR_ARVALID_X, ACLK, ARESETn, ARESETn, ARVALID)

	 end
      end
      else if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
	 `AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(cp_AR_ARVALID_until_ARREADY, ACLK, ARESETn, ARVALID, ARREADY)

	 if(ENABLE_XPROP) begin
	    `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARVALID_X, ACLK, ARESETn, ARESETn, ARVALID)

	 end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                             ARREADY                             *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSERT_VALID_INFORMATION(ap_AR_ARREADY_X, ACLK, ARESETn, ARESETn, ARREADY)

         end
      end
      else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
         if(ENABLE_XPROP) begin
            `AMBA_AXI4_ASSUME_VALID_INFORMATION(cp_AR_ARREADY_X, ACLK, ARESETn, ARESETn, ARREADY)

         end
      end
   endgenerate


   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *                        AMBA Recommended                         *
    *            ><><><><><><><><><><><><><><><><><><><><             */
   generate
      if(ARM_RECOMMENDED == 1) begin
         if(((VERIFY_AGENT_TYPE == DESTINATION) || (VERIFY_AGENT_TYPE == MONITOR))) begin
            `AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT(ap_AR_READY_MAXWAIT, ACLK, ARESETn, ARVALID, ARREADY, MAXWAIT)

         end
         else if(((VERIFY_AGENT_TYPE == SOURCE) || (VERIFY_AGENT_TYPE == CONSTRAINT))) begin
            `AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT(cp_AR_READY_MAXWAIT, ACLK, ARESETn, ARVALID, ARREADY, MAXWAIT)

         end
      end
   endgenerate

   /*            ><><><><><><><><><><><><><><><><><><><><             *
    *              Covers To Maximise Debug Information               *
    *            ><><><><><><><><><><><><><><><><><><><><             */
// OSS conversion: original parameterized let kept as comment.
//    let handshake_with_burst_type(burst_type) = (ARVALID && ARREADY && (ARBURST == burst_type));
// OSS conversion: original parameterized let kept as comment.
//    let handshake_with_lock_type(lock_type) = (ARVALID && ARREADY && (ARLOCK == lock_type));
// OSS conversion: original parameterized let kept as comment.
//    let protection_encoding(axprot, value) = (ARVALID && ARREADY && (axprot == value));
   wire AR_request_accepted = ARVALID && ARREADY;
   generate
      // Witnessing scenarios stated in the AMBA AXI4 spec
      if (ENABLE_COVER == 1) begin: witness
	 // Single handshake
// OSS conversion: original sequence kept as comment.
//          sequence ar_handshake_cond(cond);
//             ARVALID ##0 ARREADY ##0 cond;
//          endsequence // aw_burst_size

         /* This sequence looks for two handshakes
          * and is used to witness a transaction
          * process where two request are made
          * with different ID. */
// OSS conversion: original sequence kept as comment.
//          sequence ar_two_handshakes;
//             ARVALID ##0 ARREADY ##1
//             ARVALID ##0 ARREADY;
//          endsequence // aw_two_handshakes

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
//          sequence wrapping_burst_len(l);
//             ARVALID ##0 ARREADY ##0 ARBURST == WRAP
//             ##0 ARLEN == l;
//          endsequence // wrapping_burst_len

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
//          sequence unaligned_transfer(a, t);
//             ARVALID ##0 ARREADY ##0 ARSIZE == SIZE2B
//             ##0 ARADDR[a] == 1'b1 ##0 ARBURST == t;
//          endsequence // unaligned_transfer


	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                              ARID                               *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
            if(PROTOCOL_TYPE == AXI4FULL) begin
               reg wp_TWO_TRANSACTIONS_DIFFERENT_ARID_past_valid = 1'b0;
               always @(posedge ACLK) begin
                  wp_TWO_TRANSACTIONS_DIFFERENT_ARID_past_valid <= 1'b1;
                  if (wp_TWO_TRANSACTIONS_DIFFERENT_ARID_past_valid) begin
                     wp_TWO_TRANSACTIONS_DIFFERENT_ARID: cover (($past((ARVALID)) && $past((ARREADY)) && (ARVALID) && (ARREADY)) && (ARID != $past(ARID)));
                  end
               end

               for(genvar idx = 0; idx < (2**ID_WIDTH); idx++) begin: wp_ARID_TAG_NUMBER
                  amba_axi4_read_address_channel__oss_cover__wp_ARID_TAG_NUMBER oss_cover_inst_wp_ARID_TAG_NUMBER (
                     .ACLK(ACLK),
                     .cond(((ARVALID) && (ARREADY) && ((ARID == idx))))
                  );

               end
            end
         end

	 /*            ><><><><><><><><><><><><><><><><><><><><             *
	  *                              ARADDR                             *
	  *            ><><><><><><><><><><><><><><><><><><><><             */
	 if(VERIFY_AGENT_TYPE != DESTINATION) begin
            if(PROTOCOL_TYPE == AXI4FULL) begin
               always @(posedge ACLK) begin
                  wp_UNALIGNED_TRANSFERS_FIXED_BURST: cover ((ARVALID) && (ARREADY) && (ARSIZE == SIZE2B) && (ARADDR[(0)] == 1'b1) && (ARBURST == (FIXED)));
               end

               always @(posedge ACLK) begin
                  wp_UNALIGNED_TRANSFERS_INCR_BURST: cover ((ARVALID) && (ARREADY) && (ARSIZE == SIZE2B) && (ARADDR[(1)] == 1'b1) && (ARBURST == (INCR)));
               end

            end
         end

	 /*              ><><><><><><><><><><><><><><><><><><><><             *
          *                                ARLEN                              *
          *              ><><><><><><><><><><><><><><><><><><><><             */
         if(VERIFY_AGENT_TYPE != DESTINATION) begin
            if(PROTOCOL_TYPE == AXI4FULL) begin
               for(genvar i = 0; i <= MAX_RD_LENGTH-1; i++) begin: wp_AR_LEN_TRANSFERS
                  amba_axi4_read_address_channel__oss_cover__wp_AR_LEN_TRANSFERS oss_cover_inst_wp_AR_LEN_TRANSFERS (
                     .ACLK(ACLK),
                     .cond((AR_request_accepted && ARLEN == i[7:0]))
                  );

               end
               /* TODO: Bring here outstanding transaction counters to create covers for
                * first transactions with different ARLEN values. */
               for(genvar len = 2; len <= MAX_RD_LENGTH; len = len * 2) begin: wp_WRAPPING_BURST_LEN
                  amba_axi4_read_address_channel__oss_cover__wp_WRAPPING_BURST_LEN oss_cover_inst_wp_WRAPPING_BURST_LEN (
                     .ACLK(ACLK),
                     .cond(((ARVALID) && (ARREADY) && (ARBURST == WRAP) && (ARLEN == ((len -  1'b1)))))
                  );

               end
            end // if (PROTOCOL_TYPE == AXI4FULL)
         end // if (VERIFY_AGENT_TYPE != DESTINATION)


         `AMBA_AXI4_COVER_VALID_BEFORE_READY(wp_ARVALID_before_ARREADY, ACLK, ARESETn, ARVALID, ARREADY)

         `AMBA_AXI4_COVER_READY_BEFORE_VALID(wp_ARREADY_before_ARVALID, ACLK, ARESETn, ARVALID, ARREADY)

         `AMBA_AXI4_COVER_VALID_WITH_READY(wp_ARVALID_with_ARREADY, ACLK, ARESETn, ARVALID, ARREADY)

	 if(PROTOCOL_TYPE == AXI4FULL) begin
	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          wp_AR_BURST_FIXED: cover ((ARVALID && ARREADY && (ARBURST == (FIXED))));
	       end
	    end

	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          wp_AR_BURST_INCR: cover ((ARVALID && ARREADY && (ARBURST == (INCR))));
	       end
	    end

	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          wp_AR_BURST_WRAP: cover ((ARVALID && ARREADY && (ARBURST == (WRAP))));
	       end
	    end


	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          wp_AR_ARLOCK_NORMAL: cover ((ARVALID && ARREADY && (ARLOCK == (NORMAL))));
	       end
	    end

	    always @(posedge ACLK) begin
	       if (ARESETn) begin
	          wp_AR_ARLOCK_EXCLUSIVE: cover ((ARVALID && ARREADY && (ARLOCK == (EXCLUSIVE))));
	       end
	    end


	    if(VERIFY_AGENT_TYPE != DESTINATION) begin
	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_UNPRIVILEGED: cover ((ARVALID && ARREADY && ((ARPROT[0]) == (1'b0))));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_PRIVILEGED: cover ((ARVALID && ARREADY && ((ARPROT[0]) == (1'b1))));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_SECURE: cover ((ARVALID && ARREADY && ((ARPROT[1]) == (1'b0))));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_NONSECURE: cover ((ARVALID && ARREADY && ((ARPROT[1]) == (1'b1))));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_DATA: cover ((ARVALID && ARREADY && ((ARPROT[2]) == (1'b0))));
	          end
	       end

	       always @(posedge ACLK) begin
	          if (ARESETn) begin
	             wp_AR_ARPROT_INSTRUCTION: cover ((ARVALID && ARREADY && ((ARPROT[2]) == (1'b1))));
	          end
	       end

	    end // if (VERIFY_AGENT_TYPE != DESTINATION)
	 end // if (PROTOCOL_TYPE == AXI4FULL)
      end // block: witness
   endgenerate
endmodule // amba_axi4_read_address_channel
`default_nettype wire

module amba_axi4_read_address_channel__oss_cover__wp_ARID_TAG_NUMBER (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_ARID_TAG_NUMBER: cover (cond);
   end
endmodule

module amba_axi4_read_address_channel__oss_cover__wp_AR_LEN_TRANSFERS (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_AR_LEN_TRANSFERS: cover (cond);
   end
endmodule

module amba_axi4_read_address_channel__oss_cover__wp_WRAPPING_BURST_LEN (
   input wire ACLK,
   input wire cond
);
   always @(posedge ACLK) begin
      wp_WRAPPING_BURST_LEN: cover (cond);
   end
endmodule
