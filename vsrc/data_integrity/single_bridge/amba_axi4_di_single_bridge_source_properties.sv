`default_nettype none

module amba_axi4_di_single_bridge_source_properties (
   input wire       clock,
   input wire       reset,
   input wire       aw_fire,
   input wire       w_fire,
   input wire       b_fire,
   input wire       ar_fire,
   input wire       r_fire,
   input wire       compare_done_q,
   input wire [2:0] burst_len_q,
   input wire       b_valid,
   input wire       b_ready,
   input wire       r_valid,
   input wire       r_ready,
   input wire       r_last
);

// OSS conversion: removed default clocking src_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset);
   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_aw_fire: cover (aw_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_w_fire: cover (w_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_b_fire: cover (b_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_ar_fire: cover (ar_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_r_fire: cover (r_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_source_done: cover (compare_done_q);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_profile_burst_len_1: cover (aw_fire && burst_len_q == 3'd0);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_profile_burst_len_2: cover (aw_fire && burst_len_q == 3'd1);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_profile_burst_len_4: cover (aw_fire && burst_len_q == 3'd3);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_profile_burst_len_8: cover (aw_fire && burst_len_q == 3'd7);
      end
   end


`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_bpath_b_stall: cover (b_valid && !b_ready);
      end
   end

   localparam int unsigned cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W = 1;
   localparam int unsigned cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W = 3;
   reg [cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W-1:0] cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q = {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1:0] cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q = {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_bridge_bpath_b_stall_then_fire_oss_seq_start_pick;
   always @(posedge clock) begin
      if ((reset)) begin
         cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q)
            1'd0: begin
               cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               if ((b_valid && !b_ready) && cv_di_bridge_bpath_b_stall_then_fire_oss_seq_start_pick) begin
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q <= 1'd1;
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            1'd1: begin
               if (((cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (b_fire) && 1'b1) begin
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd3)) begin
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_bridge_bpath_b_stall_then_fire: cover ((cv_di_bridge_bpath_b_stall_then_fire_oss_seq_stage_q == 1'd1) && ((cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_bridge_bpath_b_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_bpath_b_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (b_fire));
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_rpath_r_stall: cover (r_valid && !r_ready);
      end
   end

   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_bridge_rpath_r_last_stall: cover (r_valid && r_last && !r_ready);
      end
   end

   localparam int unsigned cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W = 1;
   localparam int unsigned cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W = 3;
   reg [cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W-1:0] cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q = {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1:0] cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q = {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_bridge_rpath_r_stall_then_fire_oss_seq_start_pick;
   always @(posedge clock) begin
      if ((reset)) begin
         cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q)
            1'd0: begin
               cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               if ((r_valid && !r_ready) && cv_di_bridge_rpath_r_stall_then_fire_oss_seq_start_pick) begin
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q <= 1'd1;
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            1'd1: begin
               if (((cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (r_fire) && 1'b1) begin
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd3)) begin
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q <= {cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_bridge_rpath_r_stall_then_fire: cover ((cv_di_bridge_rpath_r_stall_then_fire_oss_seq_stage_q == 1'd1) && ((cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_bridge_rpath_r_stall_then_fire_oss_seq_age_q + {{cv_di_bridge_rpath_r_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (r_fire));
      end
   end

`endif
endmodule


`default_nettype wire
