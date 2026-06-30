`default_nettype none

module amba_axi4_di_word_properties (
   input wire        clock,
   input wire        reset,
   input wire        active,
   input wire        model_initialized,

   input wire        write_fire,
   input wire [3:0]  write_strb,
   input wire [7:0]  write_len,

   input wire        commit_fire,
   input wire        commit_cover_valid,
   input wire        commit_is_single_beat,
   input wire [31:0] tracked_word,
   input wire [31:0] pending_write_word,
   input wire [3:0]  pending_write_strb,

   input wire        snapshot_fire,
   input wire        snapshot_cover_valid,
   input wire [7:0]  snapshot_len,
   input wire        snapshot_valid,
   input wire [31:0] expected_read_word,

   input wire        read_fire,
   input wire        read_is_tracked_beat,
   input wire [31:0] read_data,
   input wire [2:0]  read_index,
   input wire [7:0]  read_len,
   input wire        read_last
);

// OSS conversion: removed default clocking word_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset || !active);
   reg ap_di_common_wstrb_write_commit_updates_enabled_lanes_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_wstrb_write_commit_updates_enabled_lanes_oss_past_valid <= 1'b1;
      if (ap_di_common_wstrb_write_commit_updates_enabled_lanes_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_wstrb_write_commit_updates_enabled_lanes: assert (!$past((commit_fire && commit_is_single_beat)) || (amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update( tracked_word, $past(tracked_word), $past(pending_write_word), $past(pending_write_strb), 0) && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update( tracked_word, $past(tracked_word), $past(pending_write_word), $past(pending_write_strb), 1) && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update( tracked_word, $past(tracked_word), $past(pending_write_word), $past(pending_write_strb), 2) && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update( tracked_word, $past(tracked_word), $past(pending_write_word), $past(pending_write_strb), 3)));
      end
   end


   reg ap_di_common_wstrb_updates_enabled_lanes_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_wstrb_updates_enabled_lanes_oss_past_valid <= 1'b1;
      if (ap_di_common_wstrb_updates_enabled_lanes_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_wstrb_updates_enabled_lanes: assert (!$past((commit_fire && commit_is_single_beat)) || ((!$past(pending_write_strb[0]) || tracked_word[7:0] == $past(pending_write_word[7:0])) && (!$past(pending_write_strb[1]) || tracked_word[15:8] == $past(pending_write_word[15:8])) && (!$past(pending_write_strb[2]) || tracked_word[23:16] == $past(pending_write_word[23:16])) && (!$past(pending_write_strb[3]) || tracked_word[31:24] == $past(pending_write_word[31:24]))));
      end
   end


   reg ap_di_common_wstrb_preserves_disabled_lanes_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_wstrb_preserves_disabled_lanes_oss_past_valid <= 1'b1;
      if (ap_di_common_wstrb_preserves_disabled_lanes_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_wstrb_preserves_disabled_lanes: assert (!$past((commit_fire && commit_is_single_beat)) || (($past(pending_write_strb[0]) || tracked_word[7:0] == $past(tracked_word[7:0])) && ($past(pending_write_strb[1]) || tracked_word[15:8] == $past(tracked_word[15:8])) && ($past(pending_write_strb[2]) || tracked_word[23:16] == $past(tracked_word[23:16])) && ($past(pending_write_strb[3]) || tracked_word[31:24] == $past(tracked_word[31:24]))));
      end
   end


   reg ap_di_common_wstrb_no_update_before_bresp_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_wstrb_no_update_before_bresp_oss_past_valid <= 1'b1;
      if (ap_di_common_wstrb_no_update_before_bresp_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_wstrb_no_update_before_bresp: assert (!$past((model_initialized && !commit_fire)) || (tracked_word == $past(tracked_word)));
      end
   end


   reg ap_di_common_wstrb_write_commit_updates_tracked_beat_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_wstrb_write_commit_updates_tracked_beat_oss_past_valid <= 1'b1;
      if (ap_di_common_wstrb_write_commit_updates_tracked_beat_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_wstrb_write_commit_updates_tracked_beat: assert (!$past((commit_fire)) || (tracked_word == amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32( $past(tracked_word), $past(pending_write_word), $past(pending_write_strb))));
      end
   end


   reg ap_di_common_readback_snapshot_captures_tracked_beat_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_common_readback_snapshot_captures_tracked_beat_oss_past_valid <= 1'b1;
      if (ap_di_common_readback_snapshot_captures_tracked_beat_oss_past_valid && !(reset || !active) && !$past((reset || !active))) begin
         ap_di_common_readback_snapshot_captures_tracked_beat: assert (!$past((snapshot_fire)) || (expected_read_word == $past(tracked_word) && snapshot_valid && read_len == $past(snapshot_len)));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_wstrb_matches_all_lanes: assert (!(read_fire && read_is_tracked_beat) || (read_data == expected_read_word));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_wstrb_lane0: assert (!(read_fire && read_is_tracked_beat) || (read_data[7:0] == expected_read_word[7:0]));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_wstrb_lane1: assert (!(read_fire && read_is_tracked_beat) || (read_data[15:8] == expected_read_word[15:8]));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_wstrb_lane2: assert (!(read_fire && read_is_tracked_beat) || (read_data[23:16] == expected_read_word[23:16]));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_wstrb_lane3: assert (!(read_fire && read_is_tracked_beat) || (read_data[31:24] == expected_read_word[31:24]));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_rdata_matches_expected_beat: assert (!(read_fire && read_is_tracked_beat) || (read_data == expected_read_word));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_rpath_rlast_matches_expected_final_beat: assert (!(read_fire && snapshot_valid) || (amba_axi4_data_integrity_pkg::axi4_di_last_matches_len( {5'h0, read_index}, read_len, read_last)));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         ap_di_common_readback_rdata_matches_snapshot: assert (!(read_fire && read_is_tracked_beat) || (read_data == expected_read_word));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_commit_write_commit: cover (commit_fire && commit_cover_valid);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_readback_snapshot: cover (snapshot_fire && snapshot_cover_valid);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_readback_write_then_read_compare: cover (read_fire && read_is_tracked_beat && read_data == expected_read_word);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane0_update: cover (write_fire && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 0));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane0_preserve: cover (write_fire && !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 0));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane1_update: cover (write_fire && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 1));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane1_preserve: cover (write_fire && !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 1));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane2_update: cover (write_fire && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 2));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane2_preserve: cover (write_fire && !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 2));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane3_update: cover (write_fire && amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 3));
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_lane3_preserve: cover (write_fire && !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane( write_strb, 3));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_partial_0001: cover (write_fire && write_strb == 4'b0001);
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_partial_0101: cover (write_fire && write_strb == 4'b0101);
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_partial_1000: cover (write_fire && write_strb == 4'b1000);
      end
   end

   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_zero_preserve: cover (write_fire && write_strb == 4'b0000);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_readback_compare_beat0: cover (read_fire && snapshot_valid && read_index == 3'd0);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_readback_compare_mid_beat: cover (read_fire && snapshot_valid && read_index != 3'd0 && !read_last);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_readback_compare_last_beat: cover (read_fire && snapshot_valid && read_last && read_index == read_len[2:0]);
      end
   end


   always @(posedge clock) begin
      if (!(reset || !active)) begin
         cv_di_common_wstrb_multi_beat_partial: cover (write_fire && write_len != 8'h00 && write_strb != 4'h0 && write_strb != 4'hf);
      end
   end

endmodule

`default_nettype wire
