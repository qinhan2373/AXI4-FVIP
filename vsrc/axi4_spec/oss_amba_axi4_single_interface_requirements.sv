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
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
`ifndef __AMBA_AXI4_SINGLE_INTERFACE_REQUIREMENTS__
 `define __AMBA_AXI4_SINGLE_INTERFACE_REQUIREMENTS__

// OSS Yosys does not accept package-scoped property declarations, and its
// concurrent SVA support is limited. The AMBA_AXI4_* macros below are
// expression helpers intended for clocked procedural blocks. The
// AMBA_AXI4_ASSERT_*, AMBA_AXI4_ASSUME_*, and AMBA_AXI4_COVER_* macros emit
// complete procedural checks and are the preferred OSS replacement for
// "assert/assume/cover property (...)" call sites.
`define AMBA_AXI4_EXIT_FROM_RESET(aresetn, valid) \
   (!((!(aresetn)) || $rose(aresetn)) || !(valid))

`define AMBA_AXI4_STABLE_BEFORE_HANDSHAKE(valid, ready, control) \
   (!$past((valid) && !(ready)) || ((control) == $past((control))))

`define AMBA_AXI4_VALID_BEFORE_HANDSHAKE(valid, ready) \
   (!$past((valid) && !(ready)) || (valid))

`define AMBA_AXI4_VALID_BEFORE_READY(valid, ready) \
   ((valid) && !(ready))

`define AMBA_AXI4_READY_BEFORE_VALID(valid, ready) \
   ((ready) && !(valid))

`define AMBA_AXI4_VALID_WITH_READY(valid, ready) \
   ((valid) && (ready))

`define AMBA_AXI4_HANDSHAKE_MAX_WAIT(valid, ready, timeout) \
   Use_AMBA_AXI4_ASSERT_or_ASSUME_HANDSHAKE_MAX_WAIT_for_stateful_check

`define AMBA_AXI4_HANDSHAKE_MAX_WAIT_R(valid, ready, timeout) \
   Use_AMBA_AXI4_ASSERT_or_ASSUME_HANDSHAKE_MAX_WAIT_R_for_stateful_check

`define AMBA_AXI4_VALID_INFORMATION(valid, sig) \
   (!(valid) || !$isunknown(sig))

`define AMBA_AXI4_ADDR_ALIGN_CHECK(addr, size) \
   ((addr) == ((addr) & (7'b1111111 << (size))))

`define AMBA_AXI4_START_ADDRESS_ALIGN(valid, burst, address, size) \
   (!((valid) && ((burst) == amba_axi4_protocol_checker_pkg::WRAP)) || \
    `AMBA_AXI4_ADDR_ALIGN_CHECK(address, size))

`define AMBA_AXI4_FULL_DATA_TRANSACTION(valid, default_strb_value) \
   (!(valid) || (default_strb_value))

`define AMBA_AXI4_RDWR_RESPONSE_OKAY(valid, ready, resp) \
   ((valid) && (ready) && ((resp) == amba_axi4_protocol_checker_pkg::OKAY))

`define AMBA_AXI4_RDWR_RESPONSE_EXOKAY(valid, ready, resp) \
   ((valid) && (ready) && ((resp) == amba_axi4_protocol_checker_pkg::EXOKAY))

`define AMBA_AXI4_RDWR_RESPONSE_SLVERR(valid, ready, resp) \
   ((valid) && (ready) && ((resp) == amba_axi4_protocol_checker_pkg::SLVERR))

`define AMBA_AXI4_RDWR_RESPONSE_DECERR(valid, ready, resp) \
   ((valid) && (ready) && ((resp) == amba_axi4_protocol_checker_pkg::DECERR))

`define AMBA_AXI4_BACK_TO_BACK(valid, ready) \
   ($past((valid) && (ready)) && (valid))

`define AMBA_AXI4_WAIT_STATE(valid, ready) \
   ($past((valid) && !(ready)) && (ready))

`define AMBA_AXI4_NO_WAIT_STATE(valid, ready) \
   ($past(!(valid) || (ready)) && ((valid) && (ready)))

// Skip the formal initial sample so synchronous-reset DUTs are only checked
// after reset has been observed on at least one clock edge.
`define AMBA_AXI4_ASSERT_EXIT_FROM_RESET(name, clk, aresetn, valid) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && ((!(aresetn)) || $rose(aresetn))) begin \
         name: assert (!(valid)); \
      end \
   end

`define AMBA_AXI4_ASSUME_EXIT_FROM_RESET(name, clk, aresetn, valid) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && ((!(aresetn)) || $rose(aresetn))) begin \
         name: assume (!(valid)); \
      end \
   end

`define AMBA_AXI4_ASSERT_STABLE_BEFORE_HANDSHAKE(name, clk, rst_n, valid, ready, control) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assert (`AMBA_AXI4_STABLE_BEFORE_HANDSHAKE(valid, ready, control)); \
      end \
   end

`define AMBA_AXI4_ASSUME_STABLE_BEFORE_HANDSHAKE(name, clk, rst_n, valid, ready, control) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assume (`AMBA_AXI4_STABLE_BEFORE_HANDSHAKE(valid, ready, control)); \
      end \
   end

`define AMBA_AXI4_ASSERT_VALID_BEFORE_HANDSHAKE(name, clk, rst_n, valid, ready) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assert (`AMBA_AXI4_VALID_BEFORE_HANDSHAKE(valid, ready)); \
      end \
   end

`define AMBA_AXI4_ASSUME_VALID_BEFORE_HANDSHAKE(name, clk, rst_n, valid, ready) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assume (`AMBA_AXI4_VALID_BEFORE_HANDSHAKE(valid, ready)); \
      end \
   end

`define AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT(name, clk, rst_n, valid, ready, timeout) \
   reg name``_waiting = 1'b0; \
   integer name``_wait_count = 0; \
   always @(posedge clk) begin \
      if (!(rst_n)) begin \
         name``_waiting <= 1'b0; \
         name``_wait_count <= 0; \
      end else if (!(name``_waiting)) begin \
         if ((valid) && !(ready)) begin \
            name``_waiting <= 1'b1; \
            name``_wait_count <= 0; \
         end \
      end else begin \
         name: assert ((ready) || ((name``_wait_count + 1) < (timeout))); \
         if (ready) begin \
            name``_waiting <= 1'b0; \
            name``_wait_count <= 0; \
         end else begin \
            name``_wait_count <= name``_wait_count + 1; \
         end \
      end \
   end

`define AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT(name, clk, rst_n, valid, ready, timeout) \
   reg name``_waiting = 1'b0; \
   integer name``_wait_count = 0; \
   always @(posedge clk) begin \
      if (!(rst_n)) begin \
         name``_waiting <= 1'b0; \
         name``_wait_count <= 0; \
      end else if (!(name``_waiting)) begin \
         if ((valid) && !(ready)) begin \
            name``_waiting <= 1'b1; \
            name``_wait_count <= 0; \
         end \
      end else begin \
         name: assume ((ready) || ((name``_wait_count + 1) < (timeout))); \
         if (ready) begin \
            name``_waiting <= 1'b0; \
            name``_wait_count <= 0; \
         end else begin \
            name``_wait_count <= name``_wait_count + 1; \
         end \
      end \
   end

`define AMBA_AXI4_ASSERT_HANDSHAKE_MAX_WAIT_R(name, clk, rst_n, valid, ready, timeout) \
   reg name``_waiting = 1'b0; \
   integer name``_wait_count = 0; \
   always @(posedge clk) begin \
      if (!(rst_n)) begin \
         name``_waiting <= 1'b0; \
         name``_wait_count <= 0; \
      end else if (!(name``_waiting)) begin \
         if ((valid) && !(ready)) begin \
            name``_waiting <= 1'b1; \
            name``_wait_count <= 0; \
         end \
      end else begin \
         name: assert ((!(valid) || (ready)) || ((name``_wait_count + 1) < (timeout))); \
         if (!(valid) || (ready)) begin \
            name``_waiting <= 1'b0; \
            name``_wait_count <= 0; \
         end else begin \
            name``_wait_count <= name``_wait_count + 1; \
         end \
      end \
   end

`define AMBA_AXI4_ASSUME_HANDSHAKE_MAX_WAIT_R(name, clk, rst_n, valid, ready, timeout) \
   reg name``_waiting = 1'b0; \
   integer name``_wait_count = 0; \
   always @(posedge clk) begin \
      if (!(rst_n)) begin \
         name``_waiting <= 1'b0; \
         name``_wait_count <= 0; \
      end else if (!(name``_waiting)) begin \
         if ((valid) && !(ready)) begin \
            name``_waiting <= 1'b1; \
            name``_wait_count <= 0; \
         end \
      end else begin \
         name: assume ((!(valid) || (ready)) || ((name``_wait_count + 1) < (timeout))); \
         if (!(valid) || (ready)) begin \
            name``_waiting <= 1'b0; \
            name``_wait_count <= 0; \
         end else begin \
            name``_wait_count <= name``_wait_count + 1; \
         end \
      end \
   end

`define AMBA_AXI4_ASSERT_VALID_INFORMATION(name, clk, rst_n, valid, sig) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_VALID_INFORMATION(valid, sig)); \
      end \
   end

`define AMBA_AXI4_ASSUME_VALID_INFORMATION(name, clk, rst_n, valid, sig) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_VALID_INFORMATION(valid, sig)); \
      end \
   end

`define AMBA_AXI4_ASSERT_START_ADDRESS_ALIGN(name, clk, rst_n, valid, burst, address, size) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_START_ADDRESS_ALIGN(valid, burst, address, size)); \
      end \
   end

`define AMBA_AXI4_ASSUME_START_ADDRESS_ALIGN(name, clk, rst_n, valid, burst, address, size) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_START_ADDRESS_ALIGN(valid, burst, address, size)); \
      end \
   end

`define AMBA_AXI4_ASSERT_FULL_DATA_TRANSACTION(name, clk, rst_n, valid, default_strb_value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_FULL_DATA_TRANSACTION(valid, default_strb_value)); \
      end \
   end

`define AMBA_AXI4_ASSUME_FULL_DATA_TRANSACTION(name, clk, rst_n, valid, default_strb_value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_FULL_DATA_TRANSACTION(valid, default_strb_value)); \
      end \
   end

`define AMBA_AXI4_COVER_VALID_BEFORE_READY(name, clk, rst_n, valid, ready) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_VALID_BEFORE_READY(valid, ready)); \
      end \
   end

`define AMBA_AXI4_COVER_READY_BEFORE_VALID(name, clk, rst_n, valid, ready) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_READY_BEFORE_VALID(valid, ready)); \
      end \
   end

`define AMBA_AXI4_COVER_VALID_WITH_READY(name, clk, rst_n, valid, ready) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_VALID_WITH_READY(valid, ready)); \
      end \
   end

`define AMBA_AXI4_COVER_RDWR_RESPONSE_OKAY(name, clk, rst_n, valid, ready, resp) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_RDWR_RESPONSE_OKAY(valid, ready, resp)); \
      end \
   end

`define AMBA_AXI4_COVER_RDWR_RESPONSE_EXOKAY(name, clk, rst_n, valid, ready, resp) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_RDWR_RESPONSE_EXOKAY(valid, ready, resp)); \
      end \
   end

`define AMBA_AXI4_COVER_RDWR_RESPONSE_SLVERR(name, clk, rst_n, valid, ready, resp) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_RDWR_RESPONSE_SLVERR(valid, ready, resp)); \
      end \
   end

`define AMBA_AXI4_COVER_RDWR_RESPONSE_DECERR(name, clk, rst_n, valid, ready, resp) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_RDWR_RESPONSE_DECERR(valid, ready, resp)); \
      end \
   end

`define AMBA_AXI4_COVER_BACK_TO_BACK(name, clk, rst_n, valid, ready) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: cover (`AMBA_AXI4_BACK_TO_BACK(valid, ready)); \
      end \
   end

`define AMBA_AXI4_COVER_WAIT_STATE(name, clk, rst_n, valid, ready) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: cover (`AMBA_AXI4_WAIT_STATE(valid, ready)); \
      end \
   end

`define AMBA_AXI4_COVER_NO_WAIT_STATE(name, clk, rst_n, valid, ready) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: cover (`AMBA_AXI4_NO_WAIT_STATE(valid, ready)); \
      end \
   end

package amba_axi4_single_interface_requirements;
endpackage // amba_axi4_single_interface_requirements
`endif
