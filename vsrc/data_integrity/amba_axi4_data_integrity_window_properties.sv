`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_window_axi_memory_properties (
   input wire        clock,
   input wire        reset,

   input wire        b_valid,
   input wire        aw_seen,
   input wire        wlast_seen,

   input wire        w_fire,
   input wire [2:0]  w_index,
   input wire [7:0]  aw_len,

   input wire        r_valid,
   input wire [2:0]  r_index,
   input wire [7:0]  ar_len,
   input wire        r_is_tracked_slot,
   input wire [31:0] r_data,
   input wire [31:0] tracked_word,

   input wire        aw_valid,
   input wire        aw_can_accept,
   input wire        aw_ready,
   input wire        aw_fire,

   input wire        w_valid,
   input wire        w_can_accept,
   input wire        w_ready,

   input wire        ar_valid,
   input wire        ar_can_accept,
   input wire        ar_ready,
   input wire        ar_fire
);

// OSS conversion: removed default clocking mem_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset);
   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_bpath_b_after_aw_w: assert (!(b_valid) || (aw_seen && wlast_seen));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_wpath_w_index_in_range: assert (!(w_fire) || (amba_axi4_data_integrity_pkg::axi4_di_beat_index_in_range( {5'h0, w_index}, aw_len)));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_rpath_r_index_in_range: assert (!(r_valid) || (amba_axi4_data_integrity_pkg::axi4_di_beat_index_in_range( {5'h0, r_index}, ar_len)));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_readback_tracked_read_returns_word: assert (!(r_valid && r_is_tracked_slot) || (r_data == tracked_word));
      end
   end


`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_common_downstream_aw_stall: cover (aw_valid && aw_can_accept && !aw_ready);
      end
   end

   localparam int unsigned cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W = 1;
   localparam int unsigned cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W = 3;
   reg [cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W-1:0] cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q = {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1:0] cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q = {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_common_downstream_aw_stall_then_fire_oss_seq_start_pick;
   always @(posedge clock) begin
      if ((reset)) begin
         cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q)
            1'd0: begin
               cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               if ((aw_valid && aw_can_accept && !aw_ready) && cv_di_common_downstream_aw_stall_then_fire_oss_seq_start_pick) begin
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q <= 1'd1;
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            1'd1: begin
               if (((cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (aw_fire) && 1'b1) begin
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd3)) begin
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_common_downstream_aw_stall_then_fire: cover ((cv_di_common_downstream_aw_stall_then_fire_oss_seq_stage_q == 1'd1) && ((cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_aw_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_aw_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (aw_fire));
      end
   end

`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_common_downstream_w_stall: cover (w_valid && w_can_accept && !w_ready);
      end
   end

   localparam int unsigned cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W = 1;
   localparam int unsigned cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W = 3;
   reg [cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W-1:0] cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q = {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1:0] cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q = {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_common_downstream_w_stall_then_fire_oss_seq_start_pick;
   always @(posedge clock) begin
      if ((reset)) begin
         cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q)
            1'd0: begin
               cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               if ((w_valid && w_can_accept && !w_ready) && cv_di_common_downstream_w_stall_then_fire_oss_seq_start_pick) begin
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q <= 1'd1;
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            1'd1: begin
               if (((cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (w_fire) && 1'b1) begin
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd3)) begin
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_common_downstream_w_stall_then_fire: cover ((cv_di_common_downstream_w_stall_then_fire_oss_seq_stage_q == 1'd1) && ((cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_w_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_w_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (w_fire));
      end
   end

`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
   always @(posedge clock) begin
      if (!(reset)) begin
         cv_di_common_downstream_ar_stall: cover (ar_valid && ar_can_accept && !ar_ready);
      end
   end

   localparam int unsigned cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W = 1;
   localparam int unsigned cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W = 3;
   reg [cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W-1:0] cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q = {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1:0] cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q = {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_common_downstream_ar_stall_then_fire_oss_seq_start_pick;
   always @(posedge clock) begin
      if ((reset)) begin
         cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q)
            1'd0: begin
               cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               if ((ar_valid && ar_can_accept && !ar_ready) && cv_di_common_downstream_ar_stall_then_fire_oss_seq_start_pick) begin
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q <= 1'd1;
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            1'd1: begin
               if (((cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (ar_fire) && 1'b1) begin
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd3)) begin
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q <= {cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_common_downstream_ar_stall_then_fire: cover ((cv_di_common_downstream_ar_stall_then_fire_oss_seq_stage_q == 1'd1) && ((cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 3'd1 && (cv_di_common_downstream_ar_stall_then_fire_oss_seq_age_q + {{cv_di_common_downstream_ar_stall_then_fire_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 3'd3) && (ar_fire));
      end
   end

`endif
endmodule

module amba_axi4_di_window_observer_properties (
   input wire        clock,
   input wire        reset,

   input wire        aw_fire,
   input wire [31:0] aw_addr,
   input wire [7:0]  aw_len,
   input wire [2:0]  aw_size,
   input wire [1:0]  aw_burst,
   input wire [31:0] tracked_base,
   input wire [2:0]  transfer_size,

   input wire        w_fire,
   input wire [2:0]  w_index,
   input wire [7:0]  pending_aw_len,
   input wire        w_last,

   input wire        b_fire,
   input wire        pending_write_seen,
   input wire        pending_wlast_seen,
   input wire [1:0]  b_resp,

   input wire        ar_fire,
   input wire        write_committed,
   input wire [31:0] ar_addr,
   input wire [7:0]  ar_len,
   input wire [2:0]  ar_size,
   input wire [1:0]  ar_burst,
   input wire        read_snapshot_valid,

   input wire        r_fire,
   input wire [1:0]  r_resp
);

// OSS conversion: removed default clocking obs_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset);
   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_wpath_aw_targets_tracked_addr: assert (!(aw_fire) || (aw_addr == tracked_base));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_wpath_aw_burst_profile: assert (!(aw_fire) || (aw_len < 8'h08 && aw_size == transfer_size && aw_burst == INCR));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_wpath_write_beat_index_in_range: assert (!(w_fire) || (amba_axi4_data_integrity_pkg::axi4_di_beat_index_in_range( {5'h0, w_index}, pending_aw_len)));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_wpath_wlast_matches_final_beat: assert (!(w_fire) || (amba_axi4_data_integrity_pkg::axi4_di_last_matches_len( {5'h0, w_index}, pending_aw_len, w_last)));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_bpath_b_only_after_write_data: assert (!(b_fire) || (pending_write_seen && pending_wlast_seen && b_resp == OKAY));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_rpath_ar_after_write_commit: assert (!(ar_fire) || (write_committed));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_rpath_ar_targets_tracked_addr: assert (!(ar_fire) || (ar_addr == tracked_base));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_rpath_ar_burst_profile: assert (!(ar_fire) || (ar_len == pending_aw_len && ar_size == transfer_size && ar_burst == INCR));
      end
   end


   reg ap_di_common_readback_snapshot_created_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_readback_snapshot_created_oss_past_valid <= 1'b1;
      if (ap_di_common_readback_snapshot_created_oss_past_valid && !(reset) && !$past((reset))) begin
         ap_di_common_readback_snapshot_created: assert (!$past((ar_fire)) || (read_snapshot_valid));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_readback_no_compare_without_snapshot: assert (!(r_fire) || (read_snapshot_valid));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_common_rpath_read_response_okay: assert (!(r_fire) || (r_resp == OKAY));
      end
   end

endmodule

`default_nettype wire
