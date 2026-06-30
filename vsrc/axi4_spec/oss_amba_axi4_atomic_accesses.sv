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
 *  MERCHANTABILITY. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL,
 *  DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
 *  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
 *  CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 *  CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
`ifndef __AMBA_AXI4_ATOMIC_ACCESSES__
 `define __AMBA_AXI4_ATOMIC_ACCESSES__

`define AMBA_AXI4_EXCLUSIVE_ACCESS(valid, ready, axlock) \
   ((valid) && (ready) && ((axlock) == amba_axi4_protocol_checker_pkg::EXCLUSIVE))

`define AMBA_AXI4_EXCLUSIVE_ACCESS_ADDR_ALIGN(valid, len, lock, addr_align) \
   (!((valid) && \
      (((len) == amba_axi4_protocol_checker_pkg::BURSTLEN1) || \
       ((len) == amba_axi4_protocol_checker_pkg::BURSTLEN2) || \
       ((len) == amba_axi4_protocol_checker_pkg::BURSTLEN4) || \
       ((len) == amba_axi4_protocol_checker_pkg::BURSTLEN8) || \
       ((len) == amba_axi4_protocol_checker_pkg::BURSTLEN16)) && \
      ((lock) == amba_axi4_protocol_checker_pkg::EXCLUSIVE)) || (addr_align))

`define AMBA_AXI4_EXCLUSIVE_RESTRICTION_TRANSFERS(valid, axlock, s_restrict) \
   (!((valid) && ((axlock) == amba_axi4_protocol_checker_pkg::EXCLUSIVE)) || !(s_restrict))

`define AMBA_AXI4_VALID_BURST_LEN_EXCLUSIVE(valid, lock, len) \
   (!((valid) && ((lock) == amba_axi4_protocol_checker_pkg::EXCLUSIVE)) || (((len) >> 4) == 0))

`define AMBA_AXI4_VALID_NUMBER_BYTES_EXCLUSIVE(valid, lock, len) \
   (!((valid) && ((lock) == amba_axi4_protocol_checker_pkg::EXCLUSIVE)) || \
    (((len) == 8'h0) || ((len) == 8'h1) || ((len) == 8'h3) || ((len) == 8'h7) || ((len) == 8'hf)))

`define AMBA_AXI4_NORMAL_ACCESS(valid, ready, axlock) \
   ((valid) && (ready) && ((axlock) == amba_axi4_protocol_checker_pkg::NORMAL))

`define AMBA_AXI4_ASSERT_EXCLUSIVE_ACCESS_ADDR_ALIGN(name, clk, rst_n, valid, len, lock, addr_align) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_EXCLUSIVE_ACCESS_ADDR_ALIGN(valid, len, lock, addr_align)); \
      end \
   end

`define AMBA_AXI4_ASSUME_EXCLUSIVE_ACCESS_ADDR_ALIGN(name, clk, rst_n, valid, len, lock, addr_align) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_EXCLUSIVE_ACCESS_ADDR_ALIGN(valid, len, lock, addr_align)); \
      end \
   end

`define AMBA_AXI4_ASSERT_EXCLUSIVE_RESTRICTION_TRANSFERS(name, clk, rst_n, valid, axlock, s_restrict) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_EXCLUSIVE_RESTRICTION_TRANSFERS(valid, axlock, s_restrict)); \
      end \
   end

`define AMBA_AXI4_ASSUME_EXCLUSIVE_RESTRICTION_TRANSFERS(name, clk, rst_n, valid, axlock, s_restrict) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_EXCLUSIVE_RESTRICTION_TRANSFERS(valid, axlock, s_restrict)); \
      end \
   end

`define AMBA_AXI4_ASSERT_VALID_BURST_LEN_EXCLUSIVE(name, clk, rst_n, valid, lock, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_VALID_BURST_LEN_EXCLUSIVE(valid, lock, len)); \
      end \
   end

`define AMBA_AXI4_ASSUME_VALID_BURST_LEN_EXCLUSIVE(name, clk, rst_n, valid, lock, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_VALID_BURST_LEN_EXCLUSIVE(valid, lock, len)); \
      end \
   end

`define AMBA_AXI4_ASSERT_VALID_NUMBER_BYTES_EXCLUSIVE(name, clk, rst_n, valid, lock, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_VALID_NUMBER_BYTES_EXCLUSIVE(valid, lock, len)); \
      end \
   end

`define AMBA_AXI4_ASSUME_VALID_NUMBER_BYTES_EXCLUSIVE(name, clk, rst_n, valid, lock, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_VALID_NUMBER_BYTES_EXCLUSIVE(valid, lock, len)); \
      end \
   end

`define AMBA_AXI4_COVER_EXCLUSIVE_ACCESS(name, clk, rst_n, valid, ready, axlock) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_EXCLUSIVE_ACCESS(valid, ready, axlock)); \
      end \
   end

`define AMBA_AXI4_COVER_NORMAL_ACCESS(name, clk, rst_n, valid, ready, axlock) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_NORMAL_ACCESS(valid, ready, axlock)); \
      end \
   end

package amba_axi4_atomic_accesses;
endpackage // amba_axi4_atomic_accesses
`endif
