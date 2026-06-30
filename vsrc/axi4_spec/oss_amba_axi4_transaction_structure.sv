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
`ifndef __AMBA_AXI4_TRANSACTION_STRUCTURE__
 `define __AMBA_AXI4_TRANSACTION_STRUCTURE__

`define AMBA_AXI4_SUPPORTED_BURST_TRANSFER(valid, burst, burst_type, len_val) \
   (!((valid) && ((burst) == (burst_type))) || (len_val))

`define AMBA_AXI4_VALID_WRAP_BURST_LENGTH(valid, burst, len) \
   (!((valid) && ((burst) == amba_axi4_protocol_checker_pkg::WRAP)) || \
    (((len) == 8'd1) || ((len) == 8'd3) || ((len) == 8'd7) || ((len) == 8'd15)))

`define AMBA_AXI4_BURST_CACHE_LINE_BOUNDARY(valid, burst, cond) \
   (!((valid) && ((burst) == amba_axi4_protocol_checker_pkg::INCR)) || (cond))

`define AMBA_AXI4_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(valid, size, strb) \
   (!(valid) || ((size) <= $clog2(strb)))

`define AMBA_AXI4_ASSERT_SUPPORTED_BURST_TRANSFER(name, clk, rst_n, valid, burst, burst_type, len_val) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_SUPPORTED_BURST_TRANSFER(valid, burst, burst_type, len_val)); \
      end \
   end

`define AMBA_AXI4_ASSUME_SUPPORTED_BURST_TRANSFER(name, clk, rst_n, valid, burst, burst_type, len_val) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_SUPPORTED_BURST_TRANSFER(valid, burst, burst_type, len_val)); \
      end \
   end

`define AMBA_AXI4_ASSERT_VALID_WRAP_BURST_LENGTH(name, clk, rst_n, valid, burst, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_VALID_WRAP_BURST_LENGTH(valid, burst, len)); \
      end \
   end

`define AMBA_AXI4_ASSUME_VALID_WRAP_BURST_LENGTH(name, clk, rst_n, valid, burst, len) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_VALID_WRAP_BURST_LENGTH(valid, burst, len)); \
      end \
   end

`define AMBA_AXI4_ASSERT_BURST_CACHE_LINE_BOUNDARY(name, clk, rst_n, valid, burst, cond) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assert (!($past((valid) && ((burst) == amba_axi4_protocol_checker_pkg::INCR))) || (cond)); \
      end \
   end

`define AMBA_AXI4_ASSUME_BURST_CACHE_LINE_BOUNDARY(name, clk, rst_n, valid, burst, cond) \
   reg name``_past_valid = 1'b0; \
   always @(posedge clk) begin \
      name``_past_valid <= 1'b1; \
      if (name``_past_valid && (rst_n) && $past(rst_n)) begin \
         name: assume (!($past((valid) && ((burst) == amba_axi4_protocol_checker_pkg::INCR))) || (cond)); \
      end \
   end

`define AMBA_AXI4_ASSERT_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(name, clk, rst_n, valid, size, strb) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(valid, size, strb)); \
      end \
   end

`define AMBA_AXI4_ASSUME_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(name, clk, rst_n, valid, size, strb) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_BURST_SIZE_WITHIN_WIDTH_BOUNDARY(valid, size, strb)); \
      end \
   end

package amba_axi4_transaction_structure;
endpackage
`endif
