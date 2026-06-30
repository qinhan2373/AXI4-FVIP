`default_nettype none

module amba_axi4_di_crossbar_smoke_covers (
   input wire clock,
   input wire reset,

   input wire source0_aw_valid,
   input wire source0_aw_ready,
   input wire source1_aw_valid,
   input wire source1_aw_ready,
   input wire source0_done,
   input wire source1_done,

   input wire downstream_aw_fire,
   input wire downstream_ar_fire,
   input wire downstream_r_fire,
   input wire downstream_r_last
);

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_smoke_source0_aw_fire:
            cover (source0_aw_valid && source0_aw_ready);
         cv_di_xbar_smoke_source1_aw_fire:
            cover (source1_aw_valid && source1_aw_ready);
         cv_di_xbar_smoke_source0_done:
            cover (source0_done);
         cv_di_xbar_smoke_source1_done:
            cover (source1_done);
         cv_di_xbar_smoke_output_aw_fire:
            cover (downstream_aw_fire);
         cv_di_xbar_smoke_output_ar_fire:
            cover (downstream_ar_fire);
         cv_di_xbar_smoke_output_r_last:
            cover (downstream_r_fire && downstream_r_last);
      end
   end
endmodule

`default_nettype wire
