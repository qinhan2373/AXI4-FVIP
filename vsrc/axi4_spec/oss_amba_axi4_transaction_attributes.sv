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
`ifndef __AMBA_AXI4_TRANSACTION_ATTRIBUTES__
 `define __AMBA_AXI4_TRANSACTION_ATTRIBUTES__

`define AMBA_AXI4_MEMORY_TYPE_ENCODING(valid, cache) \
   (!(valid) || !(((cache) == 4'h4) || ((cache) == 4'h5) || \
                  ((cache) == 4'h8) || ((cache) == 4'h9) || \
                  ((cache) == 4'hC) || ((cache) == 4'hD)))

`define AMBA_AXI4_UNPRIVILEGED_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b001) == 3'b000))

`define AMBA_AXI4_PRIVILEGED_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b001) == 3'b001))

`define AMBA_AXI4_SECURE_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b010) == 3'b000))

`define AMBA_AXI4_UNSECURE_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b010) == 3'b010))

`define AMBA_AXI4_DATA_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b100) == 3'b000))

`define AMBA_AXI4_INSTRUCTION_ACCESS(valid, ready, axprot) \
   ((valid) && (ready) && (((axprot) & 3'b100) == 3'b100))

`define AMBA_AXI4_ASSERT_MEMORY_TYPE_ENCODING(name, clk, rst_n, valid, cache) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4_MEMORY_TYPE_ENCODING(valid, cache)); \
      end \
   end

`define AMBA_AXI4_ASSUME_MEMORY_TYPE_ENCODING(name, clk, rst_n, valid, cache) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4_MEMORY_TYPE_ENCODING(valid, cache)); \
      end \
   end

`define AMBA_AXI4_COVER_UNPRIVILEGED_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_UNPRIVILEGED_ACCESS(valid, ready, axprot)); \
      end \
   end

`define AMBA_AXI4_COVER_PRIVILEGED_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_PRIVILEGED_ACCESS(valid, ready, axprot)); \
      end \
   end

`define AMBA_AXI4_COVER_SECURE_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_SECURE_ACCESS(valid, ready, axprot)); \
      end \
   end

`define AMBA_AXI4_COVER_UNSECURE_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_UNSECURE_ACCESS(valid, ready, axprot)); \
      end \
   end

`define AMBA_AXI4_COVER_DATA_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_DATA_ACCESS(valid, ready, axprot)); \
      end \
   end

`define AMBA_AXI4_COVER_INSTRUCTION_ACCESS(name, clk, rst_n, valid, ready, axprot) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: cover (`AMBA_AXI4_INSTRUCTION_ACCESS(valid, ready, axprot)); \
      end \
   end

package amba_axi4_transaction_attributes;
endpackage // amba_axi4_transaction_attributes
`endif
