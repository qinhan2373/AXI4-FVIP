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
`ifndef __AMBA_AXI4_DEFINITION_OF_AXI4_LITE__
 `define __AMBA_AXI4_DEFINITION_OF_AXI4_LITE__

// OSS Yosys does not support the original concurrent-SVA style used at the
// call sites. These helpers are pure expressions; use the ASSERT/ASSUME macros
// below when replacing a complete "assert/assume property (...)" statement.
`define AMBA_AXI4L_DATABUS_WIDTH(data_width) \
   (((data_width) == 32) || ((data_width) == 64))

`define AMBA_AXI4L_UNSUPPORTED_EXCLUSIVE_ACCESS(valid, lock, value) \
   (!(valid) || ((lock) != (value)))

`define AMBA_AXI4L_UNSUPPORTED_TRANSFER_STATUS(valid, response, value) \
   (!(valid) || ((response) != (value)))

`define AMBA_AXI4L_UNSUPPORTED_SIG(axi4_lite_sig_bundle) \
   (axi4_lite_sig_bundle)

`define AMBA_AXI4L_ASSERT_DATABUS_WIDTH(name, clk, data_width) \
   always @(posedge clk) begin \
      name: assert (`AMBA_AXI4L_DATABUS_WIDTH(data_width)); \
   end

`define AMBA_AXI4L_ASSUME_DATABUS_WIDTH(name, clk, data_width) \
   always @(posedge clk) begin \
      name: assume (`AMBA_AXI4L_DATABUS_WIDTH(data_width)); \
   end

`define AMBA_AXI4L_ASSERT_UNSUPPORTED_EXCLUSIVE_ACCESS(name, clk, rst_n, valid, lock, value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4L_UNSUPPORTED_EXCLUSIVE_ACCESS(valid, lock, value)); \
      end \
   end

`define AMBA_AXI4L_ASSUME_UNSUPPORTED_EXCLUSIVE_ACCESS(name, clk, rst_n, valid, lock, value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4L_UNSUPPORTED_EXCLUSIVE_ACCESS(valid, lock, value)); \
      end \
   end

`define AMBA_AXI4L_ASSERT_UNSUPPORTED_TRANSFER_STATUS(name, clk, rst_n, valid, response, value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4L_UNSUPPORTED_TRANSFER_STATUS(valid, response, value)); \
      end \
   end

`define AMBA_AXI4L_ASSUME_UNSUPPORTED_TRANSFER_STATUS(name, clk, rst_n, valid, response, value) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4L_UNSUPPORTED_TRANSFER_STATUS(valid, response, value)); \
      end \
   end

`define AMBA_AXI4L_ASSERT_UNSUPPORTED_SIG(name, clk, rst_n, axi4_lite_sig_bundle) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assert (`AMBA_AXI4L_UNSUPPORTED_SIG(axi4_lite_sig_bundle)); \
      end \
   end

`define AMBA_AXI4L_ASSUME_UNSUPPORTED_SIG(name, clk, rst_n, axi4_lite_sig_bundle) \
   always @(posedge clk) begin \
      if (rst_n) begin \
         name: assume (`AMBA_AXI4L_UNSUPPORTED_SIG(axi4_lite_sig_bundle)); \
      end \
   end

package amba_axi4_definition_of_axi4_lite;
endpackage // amba_axi4_definition_of_axi4_lite
`endif // `ifndef __AMBA_AXI4_DEFINITION_OF_AXI4_LITE__
