`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_crossbar_di_aligned_properties (
   input wire        clock,
   input wire        reset,
   input wire [31:0] initial_tracked_word,
   input wire [2:0]  tracked_beat,
   input wire [31:0] tracked_base,
   input wire [31:0] tracked_read_base,
   input wire [31:0] memory_tracked_word,
   input wire        downstream_memory_read_active,
   input wire [7:0]  downstream_memory_read_beat_index,
   input wire        downstream_memory_read_targets_tracked_slot,
   input wire [31:0] downstream_memory_r_expected_word,

   input wire        source_aw_fire,
   input wire [31:0] source_aw_addr,
   input wire [7:0]  source_aw_len,
   input wire [2:0]  source_aw_size,
   input wire [1:0]  source_aw_burst,
   input wire        source_w_fire,
   input wire [3:0]  source_w_strb,
   input wire        source_w_last,
   input wire        source_b_valid,
   input wire        source_b_ready,
   input wire        source_b_fire,
   input wire [1:0]  source_b_resp,
   input wire        source_ar_fire,
   input wire [31:0] source_ar_addr,
   input wire [7:0]  source_ar_len,
   input wire [2:0]  source_ar_size,
   input wire [1:0]  source_ar_burst,
   input wire        source_r_valid,
   input wire        source_r_ready,
   input wire        source_r_fire,
   input wire [31:0] source_r_data,
   input wire [1:0]  source_r_resp,
   input wire        source_r_last,

   input wire        downstream_aw_fire,
   input wire [31:0] downstream_aw_addr,
   input wire [7:0]  downstream_aw_len,
   input wire [2:0]  downstream_aw_size,
   input wire [1:0]  downstream_aw_burst,
   input wire        downstream_w_fire,
   input wire [31:0] downstream_w_data,
   input wire [3:0]  downstream_w_strb,
   input wire        downstream_w_last,
   input wire        downstream_ar_fire,
   input wire [31:0] downstream_ar_addr,
   input wire [7:0]  downstream_ar_len,
   input wire [2:0]  downstream_ar_size,
   input wire [1:0]  downstream_ar_burst,
   input wire        downstream_r_fire,
   input wire [31:0] downstream_r_data,
   input wire [1:0]  downstream_r_resp,

   input wire        source1_write_req_fire,
   input wire [31:0] source1_req_data,
   input wire [3:0]  source1_req_mask,
   input wire        source1_read_rsp_fire,
   input wire [31:0] source1_rsp_data,

   input wire        source_aw_seen_q,
   input wire [2:0]  source_w_index_q,
   input wire [2:0]  source_r_index_q,
   input wire [7:0]  pending_aw_len_q,
   input wire [2:0]  pending_aw_size_q,
   input wire        pending_write_seen_q,
   input wire        pending_wlast_seen_q,
   input wire [31:0] pending_tracked_write_word_q,
   input wire [3:0]  pending_tracked_write_strb_q,
   input wire        observer_write_committed_q,
   input wire [31:0] observer_expected_read_word_q,
   input wire [7:0]  observer_read_len_q,
   input wire [2:0]  observer_read_size_q,
   input wire        observer_read_snapshot_valid_q,
   input wire        observer_commit_check_pending_q,
   input wire [31:0] observer_precommit_word_q,
   input wire [31:0] observer_commit_expected_word_q,
   input wire [31:0] observer_golden_word_q,
   input wire [31:0] observer_commit_word_now,
   input wire        read_snapshot_check_pending_q,
   input wire [31:0] read_snapshot_expected_word_q,
   input wire [7:0]  read_snapshot_expected_len_q,

   input wire [31:0] downstream_golden_word_q,
   input wire        downstream_model_init_q,
   input wire [2:0]  downstream_r_index_q,
   input wire        downstream_read_active_q,
   input wire [31:0] downstream_commit_actual_word_q,
   input wire        downstream_commit_actual_valid_q,
   input wire        downstream_commit_actual_matches_source_q,
   input wire [31:0] committed_expected_word_q,
   input wire        committed_expected_valid_q,
   input wire        downstream_tracked_write_seen_q,
   input wire        commit_pair_matched_q,
   input wire        downstream_tracked_r_seen_q,
   input wire [31:0] downstream_tracked_r_data_q,

   input wire        source_tracked_w_beat,
   input wire        source_tracked_r_beat,
   input wire        downstream_tracked_w_beat,
   input wire        downstream_tracked_r_beat,
   input wire        source1_rsp_tracked_r_beat,
   input wire        cachebus_tracked_w_beat,
   input wire        source_downstream_ar_fire,
   input wire        source_downstream_r_fire,

   input wire        wpath_expected_valid,
   input wire [31:0] wpath_expected_data,
   input wire [3:0]  wpath_expected_strb,
   input wire        wpath_expected_last,
   input wire        wpath_expected_tracked,
   input wire        wpath_fifo_full,
   input wire        wpath_commit_actual_event,
   input wire        wpath_commit_actual_valid,
   input wire [31:0] wpath_commit_actual_word,
   input wire [31:0] wpath_expected_commit_word_from_path,
   input wire        wpath_commit_actual_matches_source,

   input wire        rpath_expected_valid,
   input wire [31:0] rpath_expected_data,
   input wire [31:0] rpath_expected_downstream_data,
   input wire        rpath_expected_last,
   input wire        rpath_expected_tracked,
   input wire        rpath_fifo_full,
   input wire        rpath_fifo_entry0_active,
   input wire        rpath_fifo_entry1_active,
   input wire        rpath_fifo_entry2_active,
   input wire        rpath_fifo_entry3_active,
   input wire        rpath_fifo_entry4_active,
   input wire        rpath_fifo_entry5_active,
   input wire        rpath_fifo_entry6_active,
   input wire        rpath_fifo_entry7_active,
   input wire        rpath_fifo_entry0_tracked,
   input wire        rpath_fifo_entry1_tracked,
   input wire        rpath_fifo_entry2_tracked,
   input wire        rpath_fifo_entry3_tracked,
   input wire        rpath_fifo_entry4_tracked,
   input wire        rpath_fifo_entry5_tracked,
   input wire        rpath_fifo_entry6_tracked,
   input wire        rpath_fifo_entry7_tracked,
   input wire [31:0] rpath_fifo_entry0_data,
   input wire [31:0] rpath_fifo_entry1_data,
   input wire [31:0] rpath_fifo_entry2_data,
   input wire [31:0] rpath_fifo_entry3_data,
   input wire [31:0] rpath_fifo_entry4_data,
   input wire [31:0] rpath_fifo_entry5_data,
   input wire [31:0] rpath_fifo_entry6_data,
   input wire [31:0] rpath_fifo_entry7_data,
   input wire [31:0] rpath_fifo_entry0_downstream_data,
   input wire [31:0] rpath_fifo_entry1_downstream_data,
   input wire [31:0] rpath_fifo_entry2_downstream_data,
   input wire [31:0] rpath_fifo_entry3_downstream_data,
   input wire [31:0] rpath_fifo_entry4_downstream_data,
   input wire [31:0] rpath_fifo_entry5_downstream_data,
   input wire [31:0] rpath_fifo_entry6_downstream_data,
   input wire [31:0] rpath_fifo_entry7_downstream_data,

   input wire [31:0] tracked_write_word_now,
   input wire [3:0]  tracked_write_strb_now,
   input wire [31:0] source_expected_commit_word_q,
   input wire        source_expected_commit_valid_q,
   input wire        commit_pair_matches_next,
   input wire        commit_pair_words_match_now,
   input wire        saw_source_b_stall_q,
   input wire        saw_source_r_stall_q
);

   function automatic bit di_xbar_len_in_profile(input logic [7:0] len);
      begin
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
         di_xbar_len_in_profile = len == 8'h00;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
         di_xbar_len_in_profile = len < 8'h08;
`else
         di_xbar_len_in_profile = len < 8'h08;
`endif
      end
   endfunction

   function automatic bit di_xbar_size_in_profile(input logic [2:0] size);
      begin
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
         di_xbar_size_in_profile = size <= SIZE4B;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
         di_xbar_size_in_profile = size <= SIZE4B;
`else
         di_xbar_size_in_profile = size == SIZE4B;
`endif
      end
   endfunction

   function automatic bit di_xbar_len_size_in_profile(
      input logic [7:0] len,
      input logic [2:0] size
   );
      begin
`ifdef AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
         di_xbar_len_size_in_profile =
            (size < SIZE4B && len == 8'h00) ||
            (size == SIZE4B && len < 8'h08);
`else
         di_xbar_len_size_in_profile =
            di_xbar_len_in_profile(len) && di_xbar_size_in_profile(size);
`endif
      end
   endfunction

   always @(posedge clock) begin
      if (!reset && source1_write_req_fire && cachebus_tracked_w_beat) begin
         ap_di_xbar_cachebus_wdata_matches_source_now:
            assert (source1_req_data == tracked_write_word_now);
         ap_di_xbar_cachebus_wstrb_matches_source_now:
            assert (source1_req_mask == tracked_write_strb_now);
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_aw_targets_tracked_addr:
            assert (!source_aw_fire ||
                    (source_aw_addr == tracked_base &&
                     di_xbar_len_size_in_profile(source_aw_len, source_aw_size) &&
                     source_aw_burst == INCR));
         ap_di_xbar_ar_after_write_commit:
            assert (!source_ar_fire || observer_write_committed_q);
         ap_di_xbar_ar_targets_tracked_addr:
            assert (!source_ar_fire ||
                    (source_ar_addr == tracked_read_base &&
`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
                     di_xbar_len_size_in_profile(source_ar_len, source_ar_size) &&
`else
                     source_ar_len == pending_aw_len_q &&
                     source_ar_size == pending_aw_size_q &&
                     di_xbar_size_in_profile(source_ar_size) &&
`endif
                     source_ar_burst == INCR));
         ap_di_xbar_wlast_matches_final_beat:
            assert (!source_w_fire ||
                    amba_axi4_data_integrity_pkg::axi4_di_last_matches_len(
                       {5'h0, source_w_index_q}, pending_aw_len_q,
                       source_w_last));
         ap_di_xbar_write_beat_index_in_range:
            assert (!source_w_fire ||
                    amba_axi4_data_integrity_pkg::axi4_di_beat_index_in_range(
                       {5'h0, source_w_index_q}, pending_aw_len_q));
         ap_di_xbar_b_only_after_write_data:
            assert (!source_b_fire ||
                    (pending_write_seen_q && pending_wlast_seen_q &&
                     source_b_resp == OKAY));

         ap_di_xbar_output_aw_matches_tracked:
            assert (!downstream_aw_fire ||
                    (downstream_aw_addr == tracked_base &&
                     downstream_aw_len == pending_aw_len_q &&
                     downstream_aw_size == pending_aw_size_q &&
                     di_xbar_size_in_profile(downstream_aw_size) &&
                     downstream_aw_burst == INCR));
         ap_di_xbar_output_w_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (wpath_expected_valid &&
                     downstream_w_data == wpath_expected_data &&
                     downstream_w_strb == wpath_expected_strb &&
                     downstream_w_last == wpath_expected_last));
         ap_di_xbar_output_w_expected_valid:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    wpath_expected_valid);
         ap_di_xbar_output_w_data_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data == wpath_expected_data));
         ap_di_xbar_output_w_data_lane0_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[7:0] == wpath_expected_data[7:0]));
         ap_di_xbar_output_w_data_lane1_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[15:8] == wpath_expected_data[15:8]));
         ap_di_xbar_output_w_data_lane2_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[23:16] == wpath_expected_data[23:16]));
         ap_di_xbar_output_w_data_lane3_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[31:24] == wpath_expected_data[31:24]));
         ap_di_xbar_output_w_strb_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_strb == wpath_expected_strb));
         ap_di_xbar_output_w_last_matches_write:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_last == wpath_expected_last));
         ap_di_xbar_output_w_tracked_matches_write:
            assert (!downstream_w_fire ||
                    (downstream_tracked_w_beat == wpath_expected_tracked));
         ap_di_xbar_output_w_fifo_no_overflow:
            assert (!(source_w_fire && !downstream_w_fire && wpath_fifo_full));
         ap_di_xbar_output_w_commit_actual_valid:
            assert (!wpath_commit_actual_event ||
                    wpath_commit_actual_valid);
         ap_di_xbar_output_w_commit_actual_lane0:
            assert (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[7:0] ==
                     wpath_expected_commit_word_from_path[7:0]));
         ap_di_xbar_output_w_commit_actual_lane1:
            assert (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[15:8] ==
                     wpath_expected_commit_word_from_path[15:8]));
         ap_di_xbar_output_w_commit_actual_lane2:
            assert (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[23:16] ==
                     wpath_expected_commit_word_from_path[23:16]));
         ap_di_xbar_output_w_commit_actual_lane3:
            assert (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[31:24] ==
                     wpath_expected_commit_word_from_path[31:24]));
         ap_di_xbar_output_w_commit_actual_matches_source:
            assert (!wpath_commit_actual_event ||
                    wpath_commit_actual_matches_source);
         ap_di_xbar_commit_downstream_seen_before_b:
            assert (!source_b_fire || downstream_tracked_write_seen_q);
         ap_di_xbar_commit_downstream_word_matches_expected:
            assert (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q == committed_expected_word_q));
         ap_di_xbar_commit_downstream_word_lane0:
            assert (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[7:0] ==
                     committed_expected_word_q[7:0]));
         ap_di_xbar_commit_downstream_word_lane1:
            assert (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[15:8] ==
                     committed_expected_word_q[15:8]));
         ap_di_xbar_commit_downstream_word_lane2:
            assert (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[23:16] ==
                     committed_expected_word_q[23:16]));
         ap_di_xbar_commit_downstream_word_lane3:
            assert (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[31:24] ==
                     committed_expected_word_q[31:24]));
         ap_di_xbar_commit_expected_valid_when_seen:
            assert (!downstream_tracked_write_seen_q ||
                    committed_expected_valid_q);
         ap_di_xbar_commit_downstream_matches_expected:
            assert (!downstream_tracked_write_seen_q ||
                    (committed_expected_valid_q &&
                     downstream_golden_word_q == committed_expected_word_q));
         ap_di_xbar_commit_precommit_word_is_initial:
            assert (!source_b_fire ||
                    (observer_golden_word_q == initial_tracked_word));
         ap_di_xbar_commit_source_expected_valid_before_b:
            assert (!source_b_fire || source_expected_commit_valid_q);
         ap_di_xbar_commit_source_word_matches_latch:
            assert (!source_b_fire ||
                    (observer_commit_word_now == source_expected_commit_word_q));
         ap_di_xbar_commit_source_current_matches_latch:
            assert (!source_b_fire ||
                    (source_expected_commit_valid_q &&
                     observer_commit_word_now == source_expected_commit_word_q));
         ap_di_xbar_commit_downstream_latch_matches_source:
            assert (!downstream_tracked_write_seen_q ||
                    (source_expected_commit_valid_q &&
                     committed_expected_word_q == source_expected_commit_word_q));
         ap_di_xbar_commit_downstream_source_word_before_b:
            assert (!source_b_fire ||
                    (committed_expected_valid_q &&
                     committed_expected_word_q == source_expected_commit_word_q));
         ap_di_xbar_commit_pair_matches_on_downstream_w:
            assert (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    commit_pair_matches_next);
         ap_di_xbar_commit_pair_latch_implies_words:
            assert (!commit_pair_matched_q || commit_pair_words_match_now);
         ap_di_xbar_commit_pair_seen_before_b:
            assert (!source_b_fire || commit_pair_matched_q);
         ap_di_xbar_commit_source_current_matches_expected:
            assert (!source_b_fire ||
                    (committed_expected_valid_q &&
                     observer_commit_word_now == committed_expected_word_q));
         ap_di_xbar_commit_downstream_current_matches_expected:
            assert (!source_b_fire ||
                    (downstream_commit_actual_valid_q &&
                     committed_expected_valid_q &&
                     downstream_commit_actual_matches_source_q &&
                     commit_pair_matched_q));
         ap_di_xbar_commit_actual_matches_before_b:
            assert (!source_b_fire ||
                    (downstream_commit_actual_valid_q &&
                     downstream_commit_actual_matches_source_q));
         ap_di_xbar_commit_observer_matches_expected:
            assert (!observer_commit_check_pending_q ||
                    (committed_expected_valid_q &&
                     observer_golden_word_q == observer_commit_expected_word_q &&
                     observer_golden_word_q == committed_expected_word_q));
         ap_di_xbar_commit_model_matches_observer:
            assert (!source_b_fire ||
                    (downstream_commit_actual_valid_q &&
                     downstream_commit_actual_matches_source_q &&
                     source_expected_commit_valid_q &&
                     observer_commit_word_now == source_expected_commit_word_q));
         ap_di_xbar_memory_matches_downstream_model:
            assert (!downstream_model_init_q ||
                    (memory_tracked_word == downstream_golden_word_q));
         ap_di_xbar_memory_lane0_matches_downstream_model:
            assert (!downstream_model_init_q ||
                    (memory_tracked_word[7:0] ==
                     downstream_golden_word_q[7:0]));
         ap_di_xbar_memory_lane1_matches_downstream_model:
            assert (!downstream_model_init_q ||
                    (memory_tracked_word[15:8] ==
                     downstream_golden_word_q[15:8]));
         ap_di_xbar_memory_lane2_matches_downstream_model:
            assert (!downstream_model_init_q ||
                    (memory_tracked_word[23:16] ==
                     downstream_golden_word_q[23:16]));
         ap_di_xbar_memory_lane3_matches_downstream_model:
            assert (!downstream_model_init_q ||
                    (memory_tracked_word[31:24] ==
                     downstream_golden_word_q[31:24]));
         ap_di_xbar_wstrb_write_commit_updates_tracked_beat:
            assert (!observer_commit_check_pending_q ||
                    (observer_golden_word_q == observer_commit_expected_word_q));
         ap_di_xbar_wstrb_updates_enabled_lanes:
            assert (!observer_commit_check_pending_q ||
                    ((!amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 0) ||
                      observer_golden_word_q[7:0] ==
                      pending_tracked_write_word_q[7:0]) &&
                     (!amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 1) ||
                      observer_golden_word_q[15:8] ==
                      pending_tracked_write_word_q[15:8]) &&
                     (!amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 2) ||
                      observer_golden_word_q[23:16] ==
                      pending_tracked_write_word_q[23:16]) &&
                     (!amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 3) ||
                      observer_golden_word_q[31:24] ==
                      pending_tracked_write_word_q[31:24])));
         ap_di_xbar_wstrb_preserves_disabled_lanes:
            assert (!observer_commit_check_pending_q ||
                    ((amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 0) ||
                      observer_golden_word_q[7:0] ==
                      observer_precommit_word_q[7:0]) &&
                     (amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 1) ||
                      observer_golden_word_q[15:8] ==
                      observer_precommit_word_q[15:8]) &&
                     (amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 2) ||
                      observer_golden_word_q[23:16] ==
                      observer_precommit_word_q[23:16]) &&
                     (amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                        pending_tracked_write_strb_q, 3) ||
                      observer_golden_word_q[31:24] ==
                      observer_precommit_word_q[31:24])));

         ap_di_xbar_output_ar_matches_tracked:
            assert (!source_downstream_ar_fire ||
                    (downstream_ar_addr == tracked_read_base &&
`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
                     downstream_ar_len == observer_read_len_q &&
`else
                     downstream_ar_len == pending_aw_len_q &&
`endif
                     downstream_ar_size == observer_read_size_q &&
                     di_xbar_size_in_profile(downstream_ar_size) &&
                     downstream_ar_burst == INCR));
         ap_di_xbar_read_snapshot_created:
            assert (!read_snapshot_check_pending_q ||
                    observer_read_snapshot_valid_q);
         ap_di_xbar_read_snapshot_captures_tracked_beat:
            assert (!read_snapshot_check_pending_q ||
                    (observer_expected_read_word_q ==
                     read_snapshot_expected_word_q &&
                     observer_read_len_q == read_snapshot_expected_len_q));
         ap_di_xbar_no_compare_without_snapshot:
            assert (!source_r_fire || observer_read_snapshot_valid_q);
         ap_di_xbar_read_snapshot_matches_memory_model:
            assert (!observer_read_snapshot_valid_q ||
                    (memory_tracked_word == observer_expected_read_word_q));
         ap_di_xbar_downstream_read_active_matches_memory:
            assert (!source_downstream_r_fire ||
                    (downstream_read_active_q == downstream_memory_read_active));
         ap_di_xbar_downstream_read_index_matches_memory:
            assert (!source_downstream_r_fire ||
                    ({5'h0, downstream_r_index_q} ==
                     downstream_memory_read_beat_index));
         ap_di_xbar_downstream_tracked_beat_matches_memory:
            assert (!source_downstream_r_fire ||
                    (downstream_tracked_r_beat ==
                     downstream_memory_read_targets_tracked_slot));
         ap_di_xbar_downstream_no_write_during_read:
            assert (!(source_downstream_ar_fire || downstream_read_active_q) ||
                    !downstream_w_fire);
         ap_di_xbar_downstream_memory_expected_lane0:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[7:0] ==
                     memory_tracked_word[7:0]));
         ap_di_xbar_downstream_memory_expected_lane1:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[15:8] ==
                     memory_tracked_word[15:8]));
         ap_di_xbar_downstream_memory_expected_lane2:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[23:16] ==
                     memory_tracked_word[23:16]));
         ap_di_xbar_downstream_memory_expected_lane3:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[31:24] ==
                     memory_tracked_word[31:24]));
         ap_di_xbar_downstream_tracked_r_matches_expected:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (observer_read_snapshot_valid_q &&
                     downstream_r_resp == OKAY &&
                     downstream_r_data == observer_expected_read_word_q));
         ap_di_xbar_downstream_expected_valid:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    observer_read_snapshot_valid_q);
         ap_di_xbar_downstream_expected_resp_okay:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_resp == OKAY));
         ap_di_xbar_downstream_expected_lane0:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[7:0] ==
                     observer_expected_read_word_q[7:0]));
         ap_di_xbar_downstream_expected_lane1:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[15:8] ==
                     observer_expected_read_word_q[15:8]));
         ap_di_xbar_downstream_expected_lane2:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[23:16] ==
                     observer_expected_read_word_q[23:16]));
         ap_di_xbar_downstream_expected_lane3:
            assert (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[31:24] ==
                     observer_expected_read_word_q[31:24]));
         ap_di_xbar_downstream_tracked_r_latch_matches_expected:
            assert (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q ==
                     observer_expected_read_word_q));
         ap_di_xbar_downstream_tracked_r_latch_lane0_matches_expected:
            assert (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[7:0] ==
                     observer_expected_read_word_q[7:0]));
         ap_di_xbar_downstream_tracked_r_latch_lane1_matches_expected:
            assert (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[15:8] ==
                     observer_expected_read_word_q[15:8]));
         ap_di_xbar_downstream_tracked_r_latch_lane2_matches_expected:
            assert (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[23:16] ==
                     observer_expected_read_word_q[23:16]));
         ap_di_xbar_downstream_tracked_r_latch_lane3_matches_expected:
            assert (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[31:24] ==
                     observer_expected_read_word_q[31:24]));
         ap_di_xbar_bridge_tracked_r_preserved:
            assert (!(source1_read_rsp_fire && source1_rsp_tracked_r_beat) ||
                    (downstream_tracked_r_seen_q &&
                     source_r_resp == OKAY &&
                     source1_rsp_data == downstream_tracked_r_data_q));
         ap_di_xbar_rpath_expected_valid:
            assert (!source_r_fire || rpath_expected_valid);
         ap_di_xbar_rpath_data_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data == rpath_expected_data));
         ap_di_xbar_rpath_data_lane0_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[7:0] == rpath_expected_data[7:0]));
         ap_di_xbar_rpath_data_lane1_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[15:8] == rpath_expected_data[15:8]));
         ap_di_xbar_rpath_data_lane2_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[23:16] == rpath_expected_data[23:16]));
         ap_di_xbar_rpath_data_lane3_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[31:24] == rpath_expected_data[31:24]));
         ap_di_xbar_rpath_last_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_last == rpath_expected_last));
         ap_di_xbar_rpath_tracked_matches_bridge:
            assert (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_tracked_r_beat == rpath_expected_tracked));
         ap_di_xbar_rpath_fifo_no_overflow:
            assert (!(source1_read_rsp_fire && !source_r_fire &&
                      rpath_fifo_full));
         ap_di_xbar_rpath_fifo_entry0_image_matches_bridge:
            assert (!rpath_fifo_entry0_tracked ||
                    (rpath_fifo_entry0_data ==
                     rpath_fifo_entry0_downstream_data));
         ap_di_xbar_rpath_fifo_entry1_image_matches_bridge:
            assert (!rpath_fifo_entry1_tracked ||
                    (rpath_fifo_entry1_data ==
                     rpath_fifo_entry1_downstream_data));
         ap_di_xbar_rpath_fifo_entry2_image_matches_bridge:
            assert (!rpath_fifo_entry2_tracked ||
                    (rpath_fifo_entry2_data ==
                     rpath_fifo_entry2_downstream_data));
         ap_di_xbar_rpath_fifo_entry3_image_matches_bridge:
            assert (!rpath_fifo_entry3_tracked ||
                    (rpath_fifo_entry3_data ==
                     rpath_fifo_entry3_downstream_data));
         ap_di_xbar_rpath_fifo_entry4_image_matches_bridge:
            assert (!rpath_fifo_entry4_tracked ||
                    (rpath_fifo_entry4_data ==
                     rpath_fifo_entry4_downstream_data));
         ap_di_xbar_rpath_fifo_entry5_image_matches_bridge:
            assert (!rpath_fifo_entry5_tracked ||
                    (rpath_fifo_entry5_data ==
                     rpath_fifo_entry5_downstream_data));
         ap_di_xbar_rpath_fifo_entry6_image_matches_bridge:
            assert (!rpath_fifo_entry6_tracked ||
                    (rpath_fifo_entry6_data ==
                     rpath_fifo_entry6_downstream_data));
         ap_di_xbar_rpath_fifo_entry7_image_matches_bridge:
            assert (!rpath_fifo_entry7_tracked ||
                    (rpath_fifo_entry7_data ==
                     rpath_fifo_entry7_downstream_data));
         ap_di_xbar_rpath_fifo_entry0_expected_matches_downstream:
            assert (!(rpath_fifo_entry0_active &&
                      rpath_fifo_entry0_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry0_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry1_expected_matches_downstream:
            assert (!(rpath_fifo_entry1_active &&
                      rpath_fifo_entry1_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry1_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry2_expected_matches_downstream:
            assert (!(rpath_fifo_entry2_active &&
                      rpath_fifo_entry2_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry2_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry3_expected_matches_downstream:
            assert (!(rpath_fifo_entry3_active &&
                      rpath_fifo_entry3_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry3_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry4_expected_matches_downstream:
            assert (!(rpath_fifo_entry4_active &&
                      rpath_fifo_entry4_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry4_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry5_expected_matches_downstream:
            assert (!(rpath_fifo_entry5_active &&
                      rpath_fifo_entry5_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry5_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry6_expected_matches_downstream:
            assert (!(rpath_fifo_entry6_active &&
                      rpath_fifo_entry6_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry6_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry7_expected_matches_downstream:
            assert (!(rpath_fifo_entry7_active &&
                      rpath_fifo_entry7_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry7_downstream_data ==
                     observer_expected_read_word_q));
         ap_di_xbar_rpath_fifo_entry0_latch_matches_downstream:
            assert (!(rpath_fifo_entry0_active &&
                      rpath_fifo_entry0_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry0_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry1_latch_matches_downstream:
            assert (!(rpath_fifo_entry1_active &&
                      rpath_fifo_entry1_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry1_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry2_latch_matches_downstream:
            assert (!(rpath_fifo_entry2_active &&
                      rpath_fifo_entry2_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry2_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry3_latch_matches_downstream:
            assert (!(rpath_fifo_entry3_active &&
                      rpath_fifo_entry3_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry3_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry4_latch_matches_downstream:
            assert (!(rpath_fifo_entry4_active &&
                      rpath_fifo_entry4_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry4_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry5_latch_matches_downstream:
            assert (!(rpath_fifo_entry5_active &&
                      rpath_fifo_entry5_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry5_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry6_latch_matches_downstream:
            assert (!(rpath_fifo_entry6_active &&
                      rpath_fifo_entry6_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry6_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_fifo_entry7_latch_matches_downstream:
            assert (!(rpath_fifo_entry7_active &&
                      rpath_fifo_entry7_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry7_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_downstream_image_matches_bridge:
            assert (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (rpath_expected_data ==
                     rpath_expected_downstream_data));
         ap_di_xbar_rpath_downstream_image_matches_latch:
            assert (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_expected_downstream_data ==
                     downstream_tracked_r_data_q));
         ap_di_xbar_rpath_expected_tracked_matches_downstream:
            assert (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_expected_data == downstream_tracked_r_data_q));
         ap_di_xbar_rpath_resp_okay_when_tracked:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    source_r_resp == OKAY);
         ap_di_xbar_rpath_source_r_matches_downstream_tracked:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (downstream_tracked_r_seen_q &&
                     source_r_resp == OKAY &&
                     source_r_data == downstream_tracked_r_data_q));
         ap_di_xbar_rdata_matches_snapshot:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_resp == OKAY &&
                     source_r_data == observer_expected_read_word_q));
         ap_di_xbar_rlast_matches_expected_final_beat:
            assert (!source_r_fire || !observer_read_snapshot_valid_q ||
                    amba_axi4_data_integrity_pkg::axi4_di_last_matches_len(
                       {5'h0, source_r_index_q}, observer_read_len_q,
                       source_r_last));

         ap_di_xbar_wstrb_lane0_readback:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_data[7:0] == observer_expected_read_word_q[7:0]));
         ap_di_xbar_wstrb_lane1_readback:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_data[15:8] == observer_expected_read_word_q[15:8]));
         ap_di_xbar_wstrb_lane2_readback:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_data[23:16] == observer_expected_read_word_q[23:16]));
         ap_di_xbar_wstrb_lane3_readback:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_data[31:24] == observer_expected_read_word_q[31:24]));
         ap_di_xbar_wstrb_readback_matches_all_lanes:
            assert (!(source_r_fire && source_tracked_r_beat) ||
                    (source_r_data == observer_expected_read_word_q));
      end
   end

`ifdef AXI4_DI_CROSSBAR_ASSUME_WPATH
	   always @(posedge clock) begin
	      if (!reset) begin
	         as_di_xbar_wpath_output_aw_matches_tracked:
	            assume (!downstream_aw_fire ||
	                    (downstream_aw_addr == tracked_base &&
	                     downstream_aw_len == pending_aw_len_q &&
	                     downstream_aw_size == pending_aw_size_q &&
	                     di_xbar_size_in_profile(downstream_aw_size) &&
	                     downstream_aw_burst == INCR));
         as_di_xbar_wpath_output_w_expected_valid:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    wpath_expected_valid);
         as_di_xbar_wpath_output_w_data_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data == wpath_expected_data));
         as_di_xbar_wpath_output_w_strb_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_strb == wpath_expected_strb));
         as_di_xbar_wpath_output_w_last_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_last == wpath_expected_last));
         as_di_xbar_wpath_output_w_tracked_matches_write:
            assume (!downstream_w_fire ||
                    (downstream_tracked_w_beat == wpath_expected_tracked));
         as_di_xbar_wpath_output_w_fifo_no_overflow:
            assume (!(source_w_fire && !downstream_w_fire && wpath_fifo_full));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_WPATH_DATA_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_wpath_output_w_data_lane0_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[7:0] == wpath_expected_data[7:0]));
         as_di_xbar_wpath_output_w_data_lane1_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[15:8] == wpath_expected_data[15:8]));
         as_di_xbar_wpath_output_w_data_lane2_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[23:16] == wpath_expected_data[23:16]));
         as_di_xbar_wpath_output_w_data_lane3_matches_write:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    (downstream_w_data[31:24] == wpath_expected_data[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_WPATH_COMMIT_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_wpath_output_w_commit_actual_valid:
            assume (!wpath_commit_actual_event ||
                    wpath_commit_actual_valid);
         as_di_xbar_wpath_output_w_commit_actual_lane0:
            assume (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[7:0] ==
                     wpath_expected_commit_word_from_path[7:0]));
         as_di_xbar_wpath_output_w_commit_actual_lane1:
            assume (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[15:8] ==
                     wpath_expected_commit_word_from_path[15:8]));
         as_di_xbar_wpath_output_w_commit_actual_lane2:
            assume (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[23:16] ==
                     wpath_expected_commit_word_from_path[23:16]));
         as_di_xbar_wpath_output_w_commit_actual_lane3:
            assume (!wpath_commit_actual_event ||
                    (wpath_commit_actual_word[31:24] ==
                     wpath_expected_commit_word_from_path[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_WPATH_COMMIT_ACTUAL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_wpath_output_w_commit_actual_matches_source:
            assume (!wpath_commit_actual_event ||
                    wpath_commit_actual_matches_source);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_SEEN
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_seen_before_b:
            assume (!source_b_fire || downstream_tracked_write_seen_q);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_DOWNSTREAM_WORD_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_word_lane0:
            assume (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[7:0] ==
                     committed_expected_word_q[7:0]));
         as_di_xbar_commit_downstream_word_lane1:
            assume (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[15:8] ==
                     committed_expected_word_q[15:8]));
         as_di_xbar_commit_downstream_word_lane2:
            assume (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[23:16] ==
                     committed_expected_word_q[23:16]));
         as_di_xbar_commit_downstream_word_lane3:
            assume (!(downstream_tracked_write_seen_q &&
                      committed_expected_valid_q) ||
                    (downstream_golden_word_q[31:24] ==
                     committed_expected_word_q[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_DOWNSTREAM_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_expected:
            assume (!downstream_tracked_write_seen_q ||
                    (committed_expected_valid_q &&
                     downstream_golden_word_q == committed_expected_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_matches_expected:
            assume (!downstream_tracked_write_seen_q ||
                    (committed_expected_valid_q &&
                     downstream_golden_word_q == committed_expected_word_q));
         as_di_xbar_commit_observer_matches_expected:
            assume (!observer_commit_check_pending_q ||
                    (committed_expected_valid_q &&
                     observer_golden_word_q == committed_expected_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_PRECOMMIT_INITIAL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_precommit_word_is_initial:
            assume (!source_b_fire ||
                    (observer_golden_word_q == initial_tracked_word));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_SOURCE_VALID
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_source_expected_valid_before_b:
            assume (!source_b_fire || source_expected_commit_valid_q);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_SOURCE_WORD_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_source_word_matches_latch:
            assume (!source_b_fire ||
                    (observer_commit_word_now == source_expected_commit_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_SOURCE_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_source_current_matches_latch:
            assume (!source_b_fire ||
                    (source_expected_commit_valid_q &&
                     observer_commit_word_now == source_expected_commit_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_DOWNSTREAM_SOURCE_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_latch_matches_source:
            assume (!downstream_tracked_write_seen_q ||
                    (source_expected_commit_valid_q &&
                     committed_expected_word_q == source_expected_commit_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_DOWNSTREAM_SOURCE_BEFORE_B
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_source_word_before_b:
            assume (!source_b_fire ||
                    (committed_expected_valid_q &&
                     committed_expected_word_q == source_expected_commit_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_PAIR_ON_DOWNSTREAM
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_pair_matches_on_downstream_w:
            assume (!(downstream_w_fire && downstream_tracked_w_beat) ||
                    commit_pair_matches_next);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_PAIR_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_pair_latch_implies_words:
            assume (!commit_pair_matched_q || commit_pair_words_match_now);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_PAIR_SEEN
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_pair_seen_before_b:
            assume (!source_b_fire || commit_pair_matched_q);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_SOURCE_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_source_current_matches_expected:
            assume (!source_b_fire ||
                    (committed_expected_valid_q &&
                     observer_commit_word_now == committed_expected_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_DOWNSTREAM_CURRENT_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_downstream_current_matches_expected:
            assume (!source_b_fire ||
                    (downstream_commit_actual_valid_q &&
                     committed_expected_valid_q &&
                     downstream_commit_actual_matches_source_q &&
                     commit_pair_matched_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_COMMIT_ACTUAL_BEFORE_B
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_commit_actual_matches_before_b:
            assume (!source_b_fire ||
                    (downstream_commit_actual_valid_q &&
                     downstream_commit_actual_matches_source_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_MODEL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_matches_downstream_model:
            assume (!downstream_model_init_q ||
                    (memory_tracked_word == downstream_golden_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_MODEL_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_lane0_matches_downstream_model:
            assume (!downstream_model_init_q ||
                    (memory_tracked_word[7:0] ==
                     downstream_golden_word_q[7:0]));
         as_di_xbar_memory_lane1_matches_downstream_model:
            assume (!downstream_model_init_q ||
                    (memory_tracked_word[15:8] ==
                     downstream_golden_word_q[15:8]));
         as_di_xbar_memory_lane2_matches_downstream_model:
            assume (!downstream_model_init_q ||
                    (memory_tracked_word[23:16] ==
                     downstream_golden_word_q[23:16]));
         as_di_xbar_memory_lane3_matches_downstream_model:
            assume (!downstream_model_init_q ||
                    (memory_tracked_word[31:24] ==
                     downstream_golden_word_q[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_STRUCTURAL_PATH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_downstream_tracked_r_matches_expected:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (observer_read_snapshot_valid_q &&
                     downstream_r_data == observer_expected_read_word_q));
         as_di_xbar_rpath_bridge_tracked_r_preserved:
            assume (!(source1_read_rsp_fire && source1_rsp_tracked_r_beat) ||
                    (downstream_tracked_r_seen_q &&
                     source1_rsp_data == downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_AR_REQUEST_CONTRACT
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_output_ar_matches_tracked:
            assume (!source_downstream_ar_fire ||
                    (downstream_ar_addr == tracked_read_base &&
`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
                     downstream_ar_len == observer_read_len_q &&
`else
                     downstream_ar_len == pending_aw_len_q &&
`endif
                     downstream_ar_size == observer_read_size_q &&
                     di_xbar_size_in_profile(downstream_ar_size) &&
                     downstream_ar_burst == INCR));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_READ_SNAPSHOT_CONTRACT
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_read_snapshot_created:
            assume (!read_snapshot_check_pending_q ||
                    observer_read_snapshot_valid_q);
         as_di_xbar_read_snapshot_captures_tracked_beat:
            assume (!read_snapshot_check_pending_q ||
                    (observer_expected_read_word_q ==
                     read_snapshot_expected_word_q &&
                     observer_read_len_q == read_snapshot_expected_len_q));
         as_di_xbar_no_compare_without_snapshot:
            assume (!source_r_fire || observer_read_snapshot_valid_q);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_READ_SNAPSHOT_MEMORY_MODEL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_read_snapshot_matches_memory_model:
            assume (!observer_read_snapshot_valid_q ||
                    (memory_tracked_word == observer_expected_read_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_CONTROL
`define AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_ACTIVE
`define AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_INDEX
`define AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_TRACKED_BEAT
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_ACTIVE
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_read_active_matches_memory:
            assume (!source_downstream_r_fire ||
                    (downstream_read_active_q == downstream_memory_read_active));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_INDEX
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_read_index_matches_memory:
            assume (!source_downstream_r_fire ||
                    ({5'h0, downstream_r_index_q} ==
                     downstream_memory_read_beat_index));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_TRACKED_BEAT
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_tracked_beat_matches_memory:
            assume (!source_downstream_r_fire ||
                    (downstream_tracked_r_beat ==
                     downstream_memory_read_targets_tracked_slot));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_NO_WRITE_DURING_READ
   always @(posedge clock) begin
         if (!reset) begin
         as_di_xbar_downstream_no_write_during_read:
            assume (!(source_downstream_ar_fire || downstream_read_active_q) ||
                    !downstream_w_fire);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_MEMORY_EXPECTED_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_memory_expected_lane0:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[7:0] ==
                     memory_tracked_word[7:0]));
         as_di_xbar_downstream_memory_expected_lane1:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[15:8] ==
                     memory_tracked_word[15:8]));
         as_di_xbar_downstream_memory_expected_lane2:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[23:16] ==
                     memory_tracked_word[23:16]));
         as_di_xbar_downstream_memory_expected_lane3:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_memory_r_expected_word[31:24] ==
                     memory_tracked_word[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_tracked_r_matches_expected:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (observer_read_snapshot_valid_q &&
                     downstream_r_resp == OKAY &&
                     downstream_r_data == observer_expected_read_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_EXPECTED_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_expected_valid:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    observer_read_snapshot_valid_q);
         as_di_xbar_downstream_expected_resp_okay:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_resp == OKAY));
         as_di_xbar_downstream_expected_lane0:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[7:0] ==
                     observer_expected_read_word_q[7:0]));
         as_di_xbar_downstream_expected_lane1:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[15:8] ==
                     observer_expected_read_word_q[15:8]));
         as_di_xbar_downstream_expected_lane2:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[23:16] ==
                     observer_expected_read_word_q[23:16]));
         as_di_xbar_downstream_expected_lane3:
            assume (!(source_downstream_r_fire && downstream_tracked_r_beat) ||
                    (downstream_r_data[31:24] ==
                     observer_expected_read_word_q[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_LATCH_EXPECTED_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_downstream_tracked_r_latch_lane0_matches_expected:
            assume (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[7:0] ==
                     observer_expected_read_word_q[7:0]));
         as_di_xbar_downstream_tracked_r_latch_lane1_matches_expected:
            assume (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[15:8] ==
                     observer_expected_read_word_q[15:8]));
         as_di_xbar_downstream_tracked_r_latch_lane2_matches_expected:
            assume (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[23:16] ==
                     observer_expected_read_word_q[23:16]));
         as_di_xbar_downstream_tracked_r_latch_lane3_matches_expected:
            assume (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q[31:24] ==
                     observer_expected_read_word_q[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_LATCH_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_downstream_tracked_r_latch_matches_expected:
            assume (!(downstream_tracked_r_seen_q &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_data_q ==
                     observer_expected_read_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_SOURCE_R_DOWNSTREAM
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_source_r_matches_downstream_tracked:
            assume (!(source_r_fire && source_tracked_r_beat) ||
                    (downstream_tracked_r_seen_q &&
                     source_r_resp == OKAY &&
                     source_r_data == downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_PRELUDE
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_prelude_bridge_tracked_r_preserved:
            assume (!(source1_read_rsp_fire && source1_rsp_tracked_r_beat) ||
                    (downstream_tracked_r_seen_q &&
                     source_r_resp == OKAY &&
                     source1_rsp_data == downstream_tracked_r_data_q));
         as_di_xbar_rpath_prelude_rlast_matches_expected:
            assume (!source_r_fire || !observer_read_snapshot_valid_q ||
                    amba_axi4_data_integrity_pkg::axi4_di_last_matches_len(
                       {5'h0, source_r_index_q}, observer_read_len_q,
                       source_r_last));
         as_di_xbar_rpath_prelude_expected_valid:
            assume (!source_r_fire || rpath_expected_valid);
         as_di_xbar_rpath_prelude_resp_okay_when_tracked:
            assume (!(source_r_fire && source_tracked_r_beat) ||
                    source_r_resp == OKAY);
         as_di_xbar_rpath_prelude_fifo_no_overflow:
            assume (!(source1_read_rsp_fire && !source_r_fire &&
                      rpath_fifo_full));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_LOCAL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_local_data_lane0_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[7:0] == rpath_expected_data[7:0]));
         as_di_xbar_rpath_local_data_lane1_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[15:8] == rpath_expected_data[15:8]));
         as_di_xbar_rpath_local_data_lane2_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[23:16] == rpath_expected_data[23:16]));
         as_di_xbar_rpath_local_data_lane3_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[31:24] == rpath_expected_data[31:24]));
         as_di_xbar_rpath_local_last_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_last == rpath_expected_last));
         as_di_xbar_rpath_local_tracked_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_tracked_r_beat == rpath_expected_tracked));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_DATA
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_data_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data == rpath_expected_data));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_DATA_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_data_lane0_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[7:0] == rpath_expected_data[7:0]));
         as_di_xbar_rpath_data_lane1_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[15:8] == rpath_expected_data[15:8]));
         as_di_xbar_rpath_data_lane2_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[23:16] == rpath_expected_data[23:16]));
         as_di_xbar_rpath_data_lane3_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_r_data[31:24] == rpath_expected_data[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_TRACKED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_tracked_matches_bridge:
            assume (!source_r_fire ||
                    (rpath_expected_valid &&
                     source_tracked_r_beat == rpath_expected_tracked));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_EXPECTED_DOWNSTREAM
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_expected_tracked_matches_downstream:
            assume (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_expected_data == downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_IMAGE
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_fifo_entry0_image_matches_bridge:
            assume (!rpath_fifo_entry0_tracked ||
                    (rpath_fifo_entry0_data ==
                     rpath_fifo_entry0_downstream_data));
         as_di_xbar_rpath_fifo_entry1_image_matches_bridge:
            assume (!rpath_fifo_entry1_tracked ||
                    (rpath_fifo_entry1_data ==
                     rpath_fifo_entry1_downstream_data));
         as_di_xbar_rpath_fifo_entry2_image_matches_bridge:
            assume (!rpath_fifo_entry2_tracked ||
                    (rpath_fifo_entry2_data ==
                     rpath_fifo_entry2_downstream_data));
         as_di_xbar_rpath_fifo_entry3_image_matches_bridge:
            assume (!rpath_fifo_entry3_tracked ||
                    (rpath_fifo_entry3_data ==
                     rpath_fifo_entry3_downstream_data));
         as_di_xbar_rpath_fifo_entry4_image_matches_bridge:
            assume (!rpath_fifo_entry4_tracked ||
                    (rpath_fifo_entry4_data ==
                     rpath_fifo_entry4_downstream_data));
         as_di_xbar_rpath_fifo_entry5_image_matches_bridge:
            assume (!rpath_fifo_entry5_tracked ||
                    (rpath_fifo_entry5_data ==
                     rpath_fifo_entry5_downstream_data));
         as_di_xbar_rpath_fifo_entry6_image_matches_bridge:
            assume (!rpath_fifo_entry6_tracked ||
                    (rpath_fifo_entry6_data ==
                     rpath_fifo_entry6_downstream_data));
         as_di_xbar_rpath_fifo_entry7_image_matches_bridge:
            assume (!rpath_fifo_entry7_tracked ||
                    (rpath_fifo_entry7_data ==
                     rpath_fifo_entry7_downstream_data));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_EXPECTED
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_fifo_entry0_expected_matches_downstream:
            assume (!(rpath_fifo_entry0_active &&
                      rpath_fifo_entry0_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry0_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry1_expected_matches_downstream:
            assume (!(rpath_fifo_entry1_active &&
                      rpath_fifo_entry1_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry1_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry2_expected_matches_downstream:
            assume (!(rpath_fifo_entry2_active &&
                      rpath_fifo_entry2_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry2_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry3_expected_matches_downstream:
            assume (!(rpath_fifo_entry3_active &&
                      rpath_fifo_entry3_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry3_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry4_expected_matches_downstream:
            assume (!(rpath_fifo_entry4_active &&
                      rpath_fifo_entry4_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry4_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry5_expected_matches_downstream:
            assume (!(rpath_fifo_entry5_active &&
                      rpath_fifo_entry5_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry5_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry6_expected_matches_downstream:
            assume (!(rpath_fifo_entry6_active &&
                      rpath_fifo_entry6_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry6_downstream_data ==
                     observer_expected_read_word_q));
         as_di_xbar_rpath_fifo_entry7_expected_matches_downstream:
            assume (!(rpath_fifo_entry7_active &&
                      rpath_fifo_entry7_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry7_downstream_data ==
                     observer_expected_read_word_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_fifo_entry0_latch_matches_downstream:
            assume (!(rpath_fifo_entry0_active &&
                      rpath_fifo_entry0_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry0_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry1_latch_matches_downstream:
            assume (!(rpath_fifo_entry1_active &&
                      rpath_fifo_entry1_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry1_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry2_latch_matches_downstream:
            assume (!(rpath_fifo_entry2_active &&
                      rpath_fifo_entry2_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry2_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry3_latch_matches_downstream:
            assume (!(rpath_fifo_entry3_active &&
                      rpath_fifo_entry3_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry3_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry4_latch_matches_downstream:
            assume (!(rpath_fifo_entry4_active &&
                      rpath_fifo_entry4_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry4_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry5_latch_matches_downstream:
            assume (!(rpath_fifo_entry5_active &&
                      rpath_fifo_entry5_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry5_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry6_latch_matches_downstream:
            assume (!(rpath_fifo_entry6_active &&
                      rpath_fifo_entry6_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry6_downstream_data ==
                     downstream_tracked_r_data_q));
         as_di_xbar_rpath_fifo_entry7_latch_matches_downstream:
            assume (!(rpath_fifo_entry7_active &&
                      rpath_fifo_entry7_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_fifo_entry7_downstream_data ==
                     downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_DOWNSTREAM_IMAGE
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_downstream_image_matches_bridge:
            assume (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (rpath_expected_data ==
                     rpath_expected_downstream_data));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_DOWNSTREAM_LATCH
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_downstream_image_matches_latch:
            assume (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_expected_downstream_data ==
                     downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_DOWNSTREAM_PAIR
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_downstream_pair_image_matches_bridge:
            assume (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (rpath_expected_data ==
                     rpath_expected_downstream_data));
         as_di_xbar_rpath_downstream_pair_image_matches_latch:
            assume (!(source_r_fire && rpath_expected_tracked &&
                      observer_read_snapshot_valid_q) ||
                    (downstream_tracked_r_seen_q &&
                     rpath_expected_downstream_data ==
                     downstream_tracked_r_data_q));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_RPATH_RESP_OKAY
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_rpath_resp_okay_when_tracked:
            assume (!(source_r_fire && source_tracked_r_beat) ||
                    source_r_resp == OKAY);
      end
   end
`endif

   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_profile_tracked_beat_in_range:
            assume ((!source_aw_seen_q ||
                     amba_axi4_data_integrity_pkg::axi4_di_tracked_beat_in_range(
                        tracked_beat, pending_aw_len_q)) &&
                    (!source_aw_fire ||
                     amba_axi4_data_integrity_pkg::axi4_di_tracked_beat_in_range(
                        tracked_beat, source_aw_len)) &&
                    (!observer_read_snapshot_valid_q ||
                     amba_axi4_data_integrity_pkg::axi4_di_tracked_beat_in_range(
                        tracked_beat, observer_read_len_q)) &&
                    (!source_ar_fire ||
                     amba_axi4_data_integrity_pkg::axi4_di_tracked_beat_in_range(
                        tracked_beat, source_ar_len)));
`ifdef AXI4_DI_CROSSBAR_FORCE_TRACKED_BEAT
         as_di_xbar_profile_force_tracked_beat:
            assume (tracked_beat == `AXI4_DI_CROSSBAR_FORCE_TRACKED_BEAT);
`endif
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_source_aw_fire:
            cover (source_aw_fire);
         cv_di_xbar_source_w_fire:
            cover (source_w_fire);
         cv_di_xbar_source_b_fire:
            cover (source_b_fire);
         cv_di_xbar_source_b_stall:
            cover (source_b_valid && !source_b_ready);
         cv_di_xbar_source_b_stall_then_fire:
            cover (saw_source_b_stall_q && source_b_fire);
         cv_di_xbar_source_ar_fire:
            cover (source_ar_fire && observer_write_committed_q);
         cv_di_xbar_source_tracked_r_compare:
            cover (source_r_fire && source_tracked_r_beat &&
                   source_r_data == observer_expected_read_word_q);
         cv_di_xbar_source_r_stall:
            cover (source_r_valid && !source_r_ready);
         cv_di_xbar_source_r_stall_then_fire:
            cover (saw_source_r_stall_q && source_r_fire);
         cv_di_xbar_downstream_tracked_w_commit:
            cover (downstream_w_fire && downstream_tracked_w_beat &&
                   wpath_expected_valid &&
                   downstream_w_data == wpath_expected_data &&
                   downstream_w_strb == wpath_expected_strb);
         cv_di_xbar_downstream_tracked_r_compare:
            cover (downstream_r_fire && downstream_tracked_r_beat &&
                   downstream_r_data == observer_expected_read_word_q);
         cv_di_xbar_wstrb_partial:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb != 4'h0 && source_w_strb != 4'hf);
         cv_di_xbar_wstrb_zero:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb == 4'h0);
         cv_di_xbar_wstrb_full:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb == 4'hf);
         cv_di_xbar_wstrb_lane0_update:
            cover (source_w_fire && source_tracked_w_beat &&
                   amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 0));
         cv_di_xbar_wstrb_lane0_preserve:
            cover (source_w_fire && source_tracked_w_beat &&
                   !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 0));
         cv_di_xbar_wstrb_lane1_update:
            cover (source_w_fire && source_tracked_w_beat &&
                   amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 1));
         cv_di_xbar_wstrb_lane1_preserve:
            cover (source_w_fire && source_tracked_w_beat &&
                   !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 1));
         cv_di_xbar_wstrb_lane2_update:
            cover (source_w_fire && source_tracked_w_beat &&
                   amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 2));
         cv_di_xbar_wstrb_lane2_preserve:
            cover (source_w_fire && source_tracked_w_beat &&
                   !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 2));
         cv_di_xbar_wstrb_lane3_update:
            cover (source_w_fire && source_tracked_w_beat &&
                   amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 3));
         cv_di_xbar_wstrb_lane3_preserve:
            cover (source_w_fire && source_tracked_w_beat &&
                   !amba_axi4_data_integrity_pkg::axi4_di_wstrb32_updates_lane(
                      source_w_strb, 3));
         cv_di_xbar_wstrb_partial_0001:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb == 4'b0001);
         cv_di_xbar_wstrb_partial_0101:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb == 4'b0101);
         cv_di_xbar_wstrb_partial_1000:
            cover (source_w_fire && source_tracked_w_beat &&
                   source_w_strb == 4'b1000);
         cv_di_xbar_compare_beat0:
            cover (source_r_fire && observer_read_snapshot_valid_q &&
                   source_r_index_q == 3'd0);
         cv_di_xbar_compare_mid_beat:
            cover (source_r_fire && observer_read_snapshot_valid_q &&
                   source_r_index_q != 3'd0 && !source_r_last);
         cv_di_xbar_compare_last_beat:
            cover (source_r_fire && observer_read_snapshot_valid_q &&
                   source_r_last &&
                   amba_axi4_data_integrity_pkg::axi4_di_is_last_beat(
                      {5'h0, source_r_index_q}, observer_read_len_q));
         cv_di_xbar_multi_beat_partial_wstrb:
            cover (source_w_fire && source_tracked_w_beat &&
                   pending_aw_len_q != 8'h00 &&
                   source_w_strb != 4'h0 && source_w_strb != 4'hf);
      end
   end
endmodule


`default_nettype wire
