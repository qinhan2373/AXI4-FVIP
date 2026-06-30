`default_nettype none

module amba_axi4_di_crossbar_downstream_memory_properties (
   input wire        clock,
   input wire        reset,
   input wire        w_fire,
   input wire [31:0] w_data,
   input wire [3:0]  w_strb,
   input wire        w_last,
   input wire        b_fire,
   input wire        ar_fire,
   input wire        r_fire,
   input wire        write_context_valid,
   input wire [7:0]  write_context_len,
   input wire [7:0]  write_beat_index,
   input wire        write_beat_addr_tracked,
   input wire [31:0] write_beat_expected_word,
   input wire        b_valid_q,
   input wire        write_aw_seen,
   input wire        write_wlast_seen,
   input wire [1:0]  b_id_q,
   input wire [1:0]  saved_aw_id,
   input wire        ar_addr_tracked_read,
   input wire        r_valid_q,
   input wire [31:0] r_data_q,
   input wire [31:0] r_expected_q,
   input wire [31:0] tracked_word,
   input wire        proof_read_active,
   input wire        proof_read_targets_tracked_slot,
   input wire [31:0] proof_r_expected_word,
   input wire [31:0] proof_read_current_profile_word,
   input wire        read_current_addr_tracked,
   input wire        read_current_addr_has_write_state,
   input wire [31:0] read_current_expected_word,
   input wire        r_last_q,
   input wire [7:0]  read_beat_index,
   input wire [7:0]  saved_ar_len,
   input wire [1:0]  r_id_q,
   input wire [1:0]  saved_ar_id,
   input wire        write_check_pending,
   input wire [31:0] write_check_current,
   input wire [31:0] write_check_expected,
   input wire [31:0] write_check_old,
   input wire [31:0] write_check_data,
   input wire [3:0]  write_check_strb,
   input wire        ar_addr_source0_read_window,
   input wire        ar_addr_source1_read_window,
   input wire        ar_addr_shared_read_write_window
);

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_memory_w_has_aw_context:
            assert (!w_fire || write_context_valid);
         ap_di_xbar_memory_write_addr_tracked:
            assert (!w_fire || !write_context_valid || write_beat_addr_tracked);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
         ap_di_xbar_memory_wdata_matches_source_pattern:
            assert (!w_fire || !write_context_valid ||
                    !write_beat_addr_tracked ||
                    (w_data == write_beat_expected_word));
`endif
         ap_di_xbar_memory_wlast_matches_awlen:
            assert (!w_fire || !write_context_valid ||
                    amba_axi4_data_integrity_pkg::axi4_di_last_matches_len(
                       write_beat_index, write_context_len, w_last));
         ap_di_xbar_memory_b_after_write_commit:
            assert (!b_valid_q || (write_aw_seen && write_wlast_seen));
         ap_di_xbar_memory_bid_matches_aw:
            assert (!b_valid_q || (b_id_q == saved_aw_id));
         ap_di_xbar_memory_ar_addr_tracked:
            assert (!ar_fire || ar_addr_tracked_read);
         ap_di_xbar_memory_rdata_matches_snapshot:
            assert (!r_valid_q || (r_data_q == r_expected_q));
         ap_di_xbar_memory_rdata_matches_read_window:
            assert (!r_valid_q || !read_current_addr_tracked ||
                    read_current_addr_has_write_state ||
                    (r_data_q == read_current_expected_word));
         ap_di_xbar_memory_rlast_matches_arlen:
            assert (!r_valid_q || (r_last_q == (read_beat_index == saved_ar_len)));
         ap_di_xbar_memory_rid_matches_ar:
            assert (!r_valid_q || (r_id_q == saved_ar_id));
         ap_di_xbar_memory_no_ar_while_rvalid:
            assert (!(r_valid_q && ar_fire));
         ap_di_xbar_memory_rvalid_has_active_read:
            assert (!r_valid_q || proof_read_active);
         ap_di_xbar_memory_no_write_during_read:
            assert (!(ar_fire || proof_read_active) || !w_fire);
         ap_di_xbar_memory_expected_lane0_matches_profile:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[7:0] ==
                     proof_read_current_profile_word[7:0]));
         ap_di_xbar_memory_expected_lane1_matches_profile:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[15:8] ==
                     proof_read_current_profile_word[15:8]));
         ap_di_xbar_memory_expected_lane2_matches_profile:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[23:16] ==
                     proof_read_current_profile_word[23:16]));
         ap_di_xbar_memory_expected_lane3_matches_profile:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[31:24] ==
                     proof_read_current_profile_word[31:24]));
         ap_di_xbar_memory_profile_lane0_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[7:0] ==
                     tracked_word[7:0]));
         ap_di_xbar_memory_profile_lane1_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[15:8] ==
                     tracked_word[15:8]));
         ap_di_xbar_memory_profile_lane2_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[23:16] ==
                     tracked_word[23:16]));
         ap_di_xbar_memory_profile_lane3_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[31:24] ==
                     tracked_word[31:24]));
         ap_di_xbar_memory_rdata_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word == tracked_word));
         ap_di_xbar_memory_rdata_lane0_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[7:0] == tracked_word[7:0]));
         ap_di_xbar_memory_rdata_lane1_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[15:8] == tracked_word[15:8]));
         ap_di_xbar_memory_rdata_lane2_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[23:16] == tracked_word[23:16]));
         ap_di_xbar_memory_rdata_lane3_matches_tracked_word:
            assert (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[31:24] == tracked_word[31:24]));
         ap_di_xbar_memory_wstrb_lane_update:
            assert (!write_check_pending || (write_check_current == write_check_expected));
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         ap_di_xbar_symbolic_wstrb_lane0_update_preserve:
            assert (!write_check_pending ||
                    amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update(
                       write_check_current,
                       write_check_old,
                       write_check_data,
                       write_check_strb,
                       0));
         ap_di_xbar_symbolic_wstrb_lane1_update_preserve:
            assert (!write_check_pending ||
                    amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update(
                       write_check_current,
                       write_check_old,
                       write_check_data,
                       write_check_strb,
                       1));
         ap_di_xbar_symbolic_wstrb_lane2_update_preserve:
            assert (!write_check_pending ||
                    amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update(
                       write_check_current,
                       write_check_old,
                       write_check_data,
                       write_check_strb,
                       2));
         ap_di_xbar_symbolic_wstrb_lane3_update_preserve:
            assert (!write_check_pending ||
                    amba_axi4_data_integrity_pkg::axi4_di_wstrb32_lane_matches_update(
                       write_check_current,
                       write_check_old,
                       write_check_data,
                       write_check_strb,
                       3));
         ap_di_xbar_symbolic_wstrb_zero_preserves_word:
            assert (!write_check_pending || (write_check_strb != 4'h0) ||
                    (write_check_current == write_check_old));
         ap_di_xbar_symbolic_wstrb_full_overwrites_word:
            assert (!write_check_pending || (write_check_strb != 4'hf) ||
                    (write_check_current == write_check_data));
`endif
      end
   end

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_READBACK
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_ar_addr_tracked:
            assume (!ar_fire || ar_addr_tracked_read);
         as_di_xbar_memory_rdata_matches_snapshot:
            assume (!r_valid_q || (r_data_q == r_expected_q));
         as_di_xbar_memory_rdata_matches_read_window:
            assume (!r_valid_q || !read_current_addr_tracked ||
                    read_current_addr_has_write_state ||
                    (r_data_q == read_current_expected_word));
         as_di_xbar_memory_rlast_matches_arlen:
            assume (!r_valid_q || (r_last_q == (read_beat_index == saved_ar_len)));
         as_di_xbar_memory_rid_matches_ar:
            assume (!r_valid_q || (r_id_q == saved_ar_id));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_READ_ISSUE_CONTROL
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_no_ar_while_rvalid:
            assume (!(r_valid_q && ar_fire));
         as_di_xbar_memory_rvalid_has_active_read:
            assume (!r_valid_q || proof_read_active);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_NO_WRITE_DURING_READ
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_no_write_during_read:
            assume (!(ar_fire || proof_read_active) || !w_fire);
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_EXPECTED_PROFILE_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_expected_lane0_matches_profile:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[7:0] ==
                     proof_read_current_profile_word[7:0]));
         as_di_xbar_memory_expected_lane1_matches_profile:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[15:8] ==
                     proof_read_current_profile_word[15:8]));
         as_di_xbar_memory_expected_lane2_matches_profile:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[23:16] ==
                     proof_read_current_profile_word[23:16]));
         as_di_xbar_memory_expected_lane3_matches_profile:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[31:24] ==
                     proof_read_current_profile_word[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_PROFILE_TRACKED_READ_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_profile_lane0_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[7:0] ==
                     tracked_word[7:0]));
         as_di_xbar_memory_profile_lane1_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[15:8] ==
                     tracked_word[15:8]));
         as_di_xbar_memory_profile_lane2_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[23:16] ==
                     tracked_word[23:16]));
         as_di_xbar_memory_profile_lane3_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_read_current_profile_word[31:24] ==
                     tracked_word[31:24]));
      end
   end
`endif

`ifdef AXI4_DI_CROSSBAR_ASSUME_MEMORY_TRACKED_READ_EXPECTED_LANES
   always @(posedge clock) begin
      if (!reset) begin
         as_di_xbar_memory_rdata_lane0_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[7:0] == tracked_word[7:0]));
         as_di_xbar_memory_rdata_lane1_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[15:8] == tracked_word[15:8]));
         as_di_xbar_memory_rdata_lane2_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[23:16] == tracked_word[23:16]));
         as_di_xbar_memory_rdata_lane3_matches_tracked_word:
            assume (!(r_valid_q && proof_read_targets_tracked_slot) ||
                    (proof_r_expected_word[31:24] == tracked_word[31:24]));
      end
   end
`endif

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_memory_write_commit:
            cover (b_fire && write_aw_seen && write_wlast_seen);
         cv_di_xbar_memory_read_last:
            cover (r_fire && r_last_q);
         cv_di_xbar_memory_wstrb_update:
            cover (write_check_pending);
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
         cv_di_xbar_memory_symbolic_wdata_nonzero:
            cover (w_fire && write_beat_addr_tracked && (w_data != 32'h0));
         cv_di_xbar_memory_symbolic_wdata_byte_variation:
            cover (w_fire && write_beat_addr_tracked &&
                   (w_data[7:0] != w_data[15:8]));
`endif
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         cv_di_xbar_memory_symbolic_wstrb_zero:
            cover (w_fire && write_beat_addr_tracked && (w_strb == 4'b0000));
         cv_di_xbar_memory_symbolic_wstrb_single:
            cover (w_fire && write_beat_addr_tracked && (w_strb == 4'b0001));
         cv_di_xbar_memory_symbolic_wstrb_partial:
            cover (w_fire && write_beat_addr_tracked && (w_strb == 4'b0101));
         cv_di_xbar_memory_symbolic_wstrb_full:
            cover (w_fire && write_beat_addr_tracked && (w_strb == 4'b1111));
`endif
         cv_di_xbar_memory_source0_read_window:
            cover (ar_fire && ar_addr_source0_read_window);
         cv_di_xbar_memory_source1_read_window:
            cover (ar_fire && ar_addr_source1_read_window);
         cv_di_xbar_memory_shared_read_write_window:
            cover (ar_fire && ar_addr_shared_read_write_window);
      end
   end
endmodule


`default_nettype wire
