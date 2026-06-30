`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

`ifdef AXI4_DI_CROSSBAR_EXTRA_SANITY
module amba_axi4_di_crossbar_source_driver_properties (
   input wire       clock,
   input wire       reset,
   input wire       b_valid,
   input wire [1:0] b_id,
   input wire [1:0] b_resp,
   input wire       r_valid,
   input wire [1:0] r_id,
   input wire [1:0] r_resp
);

// OSS conversion: removed default clocking src_drv_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset);
   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_source_driver_b_id_zero: assert (!b_valid || (b_id == 2'd0));
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_source_driver_b_no_exokay: assert (!b_valid || (b_resp != EXOKAY));
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_source_driver_r_id_zero: assert (!r_valid || (r_id == 2'd0));
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_source_driver_r_no_exokay: assert (!r_valid || (r_resp != EXOKAY));
      end
   end

endmodule

`endif

`default_nettype wire
