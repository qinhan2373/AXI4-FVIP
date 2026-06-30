`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_single_bridge_data_integrity_properties (
   input wire        clock,
   input wire        reset,
   input wire        di_active_q,
   input wire [2:0]  s_w_index_q,
   input wire [31:0] tracked_base,
   input wire [2:0]  tracked_beat,
   input wire [7:0]  source_burst_len,
   input wire [2:0]  source_transfer_size,
   input wire [31:0] source_tracked_write_data,
   input wire [3:0]  source_tracked_write_strb,
   input wire [31:0] memory_tracked_word,
   input wire [31:0] observer_golden_tracked_word,
   input wire [31:0] observer_expected_read_tracked_word,
   input wire        observer_read_snapshot_valid,

   input wire        m_aw_fire,
   input wire        m_w_fire,
   input wire        m_b_fire,
   input wire        m_ar_fire,
   input wire        m_r_fire,
   input wire [31:0] m_r_data,

   input wire        s_aw_fire,
   input wire [31:0] s_aw_addr,
   input wire [7:0]  s_aw_len,
   input wire [2:0]  s_aw_size,
   input wire [1:0]  s_aw_burst,
   input wire [1:0]  s_aw_id,
   input wire        s_w_fire,
   input wire [31:0] s_w_data,
   input wire [3:0]  s_w_strb,
   input wire        s_w_last,
   input wire        s_ar_fire,
   input wire [31:0] s_ar_addr,
   input wire [7:0]  s_ar_len,
   input wire [2:0]  s_ar_size,
   input wire [1:0]  s_ar_burst,
   input wire [1:0]  s_ar_id,
   input wire        s_r_fire,
   input wire [31:0] s_r_data,

   input wire        s_w_is_tracked_beat,
   input wire        s_r_is_tracked_beat,
   input wire        m_r_is_tracked_beat,
   input wire [31:0] s_tracked_r_data_q,
   input wire        s_tracked_r_seen_q,
   input wire [31:0] downstream_golden_tracked_word_q,
   input wire        downstream_model_init_q,
   input wire        downstream_tracked_write_seen_q,
   input wire [31:0] committed_expected_tracked_word_q,
   input wire        committed_expected_valid_q
);

// OSS conversion: removed default clocking tb_clk @(posedge clock); endclocking
// OSS conversion: removed default disable iff (reset || !di_active_q);
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_wpath_output_aw_matches_tracked: assert (!(s_aw_fire) || (s_aw_addr == tracked_base && s_aw_len == source_burst_len && s_aw_size == source_transfer_size && s_aw_burst == INCR && s_aw_id == 2'h0));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_wpath_output_w_matches_write: assert (!(s_w_fire && s_w_is_tracked_beat) || (s_w_data == source_tracked_write_data && s_w_strb == source_tracked_write_strb));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_rpath_output_ar_matches_tracked: assert (!(s_ar_fire) || (s_ar_addr == tracked_base && s_ar_len == source_burst_len && s_ar_size == source_transfer_size && s_ar_burst == INCR && s_ar_id == 2'h0));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_wpath_output_w_index_in_range: assert (!(s_w_fire) || (amba_axi4_data_integrity_pkg::axi4_di_beat_index_in_range( {5'h0, s_w_index_q}, source_burst_len)));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_rpath_tracked_r_preserved: assert (!(m_r_fire && m_r_is_tracked_beat) || (s_tracked_r_seen_q && m_r_data == s_tracked_r_data_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_commit_memory_matches_downstream_model: assert (!(downstream_model_init_q) || (memory_tracked_word == downstream_golden_tracked_word_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_commit_downstream_seen_before_b: assert (!(m_b_fire) || (downstream_tracked_write_seen_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_commit_expected_valid_when_seen: assert (!(downstream_tracked_write_seen_q) || (committed_expected_valid_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_commit_downstream_word_matches_expected: assert (!(downstream_tracked_write_seen_q && committed_expected_valid_q) || (downstream_golden_tracked_word_q == committed_expected_tracked_word_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_commit_downstream_matches_expected: assert (!(downstream_tracked_write_seen_q) || (committed_expected_valid_q && downstream_golden_tracked_word_q == committed_expected_tracked_word_q));
      end
   end


   reg ap_di_bridge_commit_observer_matches_expected_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_bridge_commit_observer_matches_expected_oss_past_valid <= 1'b1;
      if (ap_di_bridge_commit_observer_matches_expected_oss_past_valid && !(reset || !di_active_q) && !$past((reset || !di_active_q))) begin
         ap_di_bridge_commit_observer_matches_expected: assert (!$past((m_b_fire)) || (committed_expected_valid_q && observer_golden_tracked_word == committed_expected_tracked_word_q));
      end
   end


   reg ap_di_bridge_commit_model_matches_observer_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_bridge_commit_model_matches_observer_oss_past_valid <= 1'b1;
      if (ap_di_bridge_commit_model_matches_observer_oss_past_valid && !(reset || !di_active_q) && !$past((reset || !di_active_q))) begin
         ap_di_bridge_commit_model_matches_observer: assert (!$past((m_b_fire)) || ($past(downstream_golden_tracked_word_q) == observer_golden_tracked_word));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         ap_di_bridge_rpath_downstream_tracked_r_matches_expected: assert (!(s_r_fire && s_r_is_tracked_beat) || (observer_read_snapshot_valid && s_r_data == observer_expected_read_tracked_word));
      end
   end


`ifdef AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_wpath_output_w_matches_write: assume (!(s_w_fire && s_w_is_tracked_beat) || (s_w_data == source_tracked_write_data && s_w_strb == source_tracked_write_strb));
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_ASSUME_COMMIT_EQUIV
   reg as_di_bridge_commit_model_matches_observer_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      as_di_bridge_commit_model_matches_observer_oss_past_valid <= 1'b1;
      if (as_di_bridge_commit_model_matches_observer_oss_past_valid && !(reset || !di_active_q) && !$past((reset || !di_active_q))) begin
         as_di_bridge_commit_model_matches_observer: assume (!$past((m_b_fire)) || ($past(downstream_golden_tracked_word_q) == observer_golden_tracked_word));
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_ASSUME_COMMIT_EXPECTED
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_commit_downstream_matches_expected: assume (!(downstream_tracked_write_seen_q) || (committed_expected_valid_q && downstream_golden_tracked_word_q == committed_expected_tracked_word_q));
      end
   end


   reg as_di_bridge_commit_observer_matches_expected_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      as_di_bridge_commit_observer_matches_expected_oss_past_valid <= 1'b1;
      if (as_di_bridge_commit_observer_matches_expected_oss_past_valid && !(reset || !di_active_q) && !$past((reset || !di_active_q))) begin
         as_di_bridge_commit_observer_matches_expected: assume (!$past((m_b_fire)) || (committed_expected_valid_q && observer_golden_tracked_word == committed_expected_tracked_word_q));
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_ASSUME_MEMORY_MODEL
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_commit_memory_matches_downstream_model: assume (!(downstream_model_init_q) || (memory_tracked_word == downstream_golden_tracked_word_q));
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_ASSUME_STRUCTURAL_PATH
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_rpath_tracked_r_preserved: assume (!(m_r_fire && m_r_is_tracked_beat) || (s_tracked_r_seen_q && m_r_data == s_tracked_r_data_q));
      end
   end


   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_rpath_downstream_tracked_r_matches_expected: assume (!(s_r_fire && s_r_is_tracked_beat) || (observer_read_snapshot_valid && s_r_data == observer_expected_read_tracked_word));
      end
   end

`endif

   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_profile_tracked_beat_in_range: assume (amba_axi4_data_integrity_pkg::axi4_di_tracked_beat_in_range( tracked_beat, source_burst_len));
      end
   end


`ifdef AXI4_DI_SINGLE_BRIDGE_FORCE_SINGLE_BEAT
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_profile_force_single_beat: assume (source_burst_len == 8'h00);
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_FORCE_TRACKED_BEAT0
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_profile_force_tracked_beat0: assume (tracked_beat == 3'h0);
      end
   end

`endif

`ifdef AXI4_DI_SINGLE_BRIDGE_FORCE_TRACKED_BEAT
   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         as_di_bridge_profile_force_tracked_beat: assume (tracked_beat == `AXI4_DI_SINGLE_BRIDGE_FORCE_TRACKED_BEAT);
      end
   end

`endif

   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         cv_di_bridge_wpath_output_aw_fire: cover (s_aw_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         cv_di_bridge_wpath_output_w_fire: cover (s_w_fire);
      end
   end

   always @(posedge clock) begin
      if (!(reset || !di_active_q)) begin
         cv_di_bridge_rpath_output_ar_fire: cover (s_ar_fire);
      end
   end

   localparam int unsigned cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W = 3;
   localparam int unsigned cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W = 5;
   reg [cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W-1:0] cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q = {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
   reg [cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1:0] cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q = {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
   (* anyseq *) wire cv_di_bridge_flow_end_to_end_complete_oss_seq_start_pick;
   (* anyseq *) wire cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_1;
   (* anyseq *) wire cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_2;
   (* anyseq *) wire cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_3;
   always @(posedge clock) begin
      if ((reset || !di_active_q)) begin
         cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
         cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
      end
      else begin
         case (cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q)
            3'd0: begin
               cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               if ((m_aw_fire) && cv_di_bridge_flow_end_to_end_complete_oss_seq_start_pick) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= 3'd1;
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
            end
            3'd1: begin
               if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd1 && (cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 5'd20) && (m_w_fire) && cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_1) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= 3'd2;
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd20)) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            3'd2: begin
               if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd1 && (cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 5'd20) && (m_b_fire) && cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_2) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= 3'd3;
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd20)) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            3'd3: begin
               if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd1 && (cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 5'd20) && (m_ar_fire) && cv_di_bridge_flow_end_to_end_complete_oss_seq_advance_pick_3) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= 3'd4;
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd20)) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            3'd4: begin
               if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd1 && (cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 5'd20) && (m_r_fire) && 1'b1) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else if (((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd20)) begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
               end
               else begin
                  cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1};
               end
            end
            default: begin
               cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_STAGE_W{1'b0}};
               cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q <= {cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W{1'b0}};
            end
         endcase
         cv_di_bridge_flow_end_to_end_complete: cover ((cv_di_bridge_flow_end_to_end_complete_oss_seq_stage_q == 3'd4) && ((cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) >= 5'd1 && (cv_di_bridge_flow_end_to_end_complete_oss_seq_age_q + {{cv_di_bridge_flow_end_to_end_complete_OSS_SEQ_AGE_W-1{1'b0}}, 1'b1}) <= 5'd20) && (m_r_fire));
      end
   end

endmodule


`default_nettype wire
