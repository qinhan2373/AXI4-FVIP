`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_crossbar_di_aligned_observer (
   input  wire        clock,
   input  wire        reset,
   input  wire [31:0] initial_tracked_word,
   input  wire [2:0]  tracked_beat,
   input  wire [31:0] tracked_base,
   input  wire [31:0] tracked_read_base,
   input  wire [31:0] memory_tracked_word,
   input  wire        downstream_memory_read_active,
   input  wire [7:0]  downstream_memory_read_beat_index,
   input  wire        downstream_memory_read_targets_tracked_slot,
   input  wire [31:0] downstream_memory_r_expected_word,

   input  wire        source_aw_valid,
   input  wire        source_aw_ready,
   input  wire [31:0] source_aw_addr,
   input  wire [7:0]  source_aw_len,
   input  wire [2:0]  source_aw_size,
   input  wire [1:0]  source_aw_burst,
   input  wire        source_w_valid,
   input  wire        source_w_ready,
   input  wire [31:0] source_w_data,
   input  wire [3:0]  source_w_strb,
   input  wire        source_w_last,
   input  wire        source_b_valid,
   input  wire        source_b_ready,
   input  wire [1:0]  source_b_resp,
   input  wire        source_ar_valid,
   input  wire        source_ar_ready,
   input  wire [31:0] source_ar_addr,
   input  wire [7:0]  source_ar_len,
   input  wire [2:0]  source_ar_size,
   input  wire [1:0]  source_ar_burst,
   input  wire        source_r_valid,
   input  wire        source_r_ready,
   input  wire [31:0] source_r_data,
   input  wire [1:0]  source_r_resp,
   input  wire        source_r_last,

   input  wire        downstream_aw_valid,
   input  wire        downstream_aw_ready,
   input  wire [31:0] downstream_aw_addr,
   input  wire [7:0]  downstream_aw_len,
   input  wire [2:0]  downstream_aw_size,
   input  wire [1:0]  downstream_aw_burst,
   input  wire        downstream_w_valid,
   input  wire        downstream_w_ready,
   input  wire [31:0] downstream_w_data,
   input  wire [3:0]  downstream_w_strb,
   input  wire        downstream_w_last,
   input  wire        downstream_b_valid,
   input  wire        downstream_b_ready,
   input  wire        downstream_ar_valid,
   input  wire        downstream_ar_ready,
   input  wire [31:0] downstream_ar_addr,
   input  wire [7:0]  downstream_ar_len,
   input  wire [2:0]  downstream_ar_size,
   input  wire [1:0]  downstream_ar_burst,
   input  wire        downstream_r_valid,
   input  wire        downstream_r_ready,
   input  wire [31:0] downstream_r_data,
   input  wire [1:0]  downstream_r_resp,
   input  wire        downstream_r_last,

   input  wire        source1_req_valid,
   input  wire        source1_req_ready,
   input  wire        source1_req_wen,
   input  wire [31:0] source1_req_data,
   input  wire [3:0]  source1_req_mask,
   input  wire        source1_req_last,
   input  wire        source1_rsp_valid,
   input  wire        source1_rsp_ready,
   input  wire [31:0] source1_rsp_data,
   input  wire        source1_rsp_last
);

   localparam int unsigned WPATH_FIFO_DEPTH = 8;
   localparam logic [3:0] WPATH_FIFO_DEPTH_COUNT = 4'(WPATH_FIFO_DEPTH);
   localparam int unsigned RPATH_FIFO_DEPTH = 8;
   localparam logic [3:0] RPATH_FIFO_DEPTH_COUNT = 4'(RPATH_FIFO_DEPTH);

   reg [31:0] observer_golden_word_q = 32'h0;
   reg [31:0] pending_tracked_write_word_q = 32'h0;
   reg [3:0]  pending_tracked_write_strb_q = 4'h0;
   reg [7:0]  pending_aw_len_q = 8'h0;
   reg [2:0]  pending_aw_size_q = SIZE4B;
   reg        source_aw_seen_q = 1'b0;
   reg [2:0]  source_w_index_q = 3'h0;
   reg [2:0]  source_r_index_q = 3'h0;
   reg        pending_write_seen_q = 1'b0;
   reg        pending_wlast_seen_q = 1'b0;
   reg        observer_write_committed_q = 1'b0;
   reg [31:0] observer_expected_read_word_q = 32'h0;
   reg [7:0]  observer_read_len_q = 8'h0;
   reg [2:0]  observer_read_size_q = SIZE4B;
   reg        observer_read_snapshot_valid_q = 1'b0;
   reg        observer_commit_check_pending_q = 1'b0;
   reg [31:0] observer_precommit_word_q = 32'h0;
   reg [31:0] observer_commit_expected_word_q = 32'h0;
   reg [31:0] source_expected_commit_word_q = 32'h0;
   reg        source_expected_commit_valid_q = 1'b0;
   reg        read_snapshot_check_pending_q = 1'b0;
   reg [31:0] read_snapshot_expected_word_q = 32'h0;
   reg [7:0]  read_snapshot_expected_len_q = 8'h0;

   reg [2:0]  downstream_w_index_q = 3'h0;
   reg [2:0]  downstream_r_index_q = 3'h0;
   reg [31:0] downstream_golden_word_q = 32'h0;
   reg        downstream_model_init_q = 1'b0;
   reg [31:0] downstream_commit_actual_word_q = 32'h0;
   reg        downstream_commit_actual_valid_q = 1'b0;
   reg        downstream_commit_actual_matches_source_q = 1'b0;
   reg [31:0] committed_expected_word_q = 32'h0;
   reg        committed_expected_valid_q = 1'b0;
   reg        downstream_tracked_write_seen_q = 1'b0;
   reg        commit_pair_matched_q = 1'b0;
   reg        downstream_w_active_q = 1'b0;
   reg        source1_read_req_pending_q = 1'b0;
   reg        source1_read_rsp_active_q = 1'b0;
   reg        source_read_ar_pending_q = 1'b0;
   reg        downstream_read_active_q = 1'b0;
   reg [31:0] downstream_tracked_r_data_q = 32'h0;
   reg        downstream_tracked_r_seen_q = 1'b0;
   reg [31:0] rpath_fifo_data [0:RPATH_FIFO_DEPTH-1];
   reg [31:0] rpath_fifo_downstream_data [0:RPATH_FIFO_DEPTH-1];
   reg        rpath_fifo_last [0:RPATH_FIFO_DEPTH-1];
   reg        rpath_fifo_tracked [0:RPATH_FIFO_DEPTH-1];
   reg [2:0]  rpath_fifo_rd_q = 3'h0;
   reg [2:0]  rpath_fifo_wr_q = 3'h0;
   reg [3:0]  rpath_fifo_count_q = 4'h0;

   reg [2:0]  cachebus_w_index_q = 3'h0;
   reg [2:0]  source1_rsp_index_q = 3'h0;

   reg [31:0] wpath_fifo_data [0:WPATH_FIFO_DEPTH-1];
   reg [3:0]  wpath_fifo_strb [0:WPATH_FIFO_DEPTH-1];
   reg        wpath_fifo_last [0:WPATH_FIFO_DEPTH-1];
   reg        wpath_fifo_tracked [0:WPATH_FIFO_DEPTH-1];
   reg [2:0]  wpath_fifo_rd_q = 3'h0;
   reg [2:0]  wpath_fifo_wr_q = 3'h0;
   reg [3:0]  wpath_fifo_count_q = 4'h0;

   reg        saw_source_b_stall_q = 1'b0;
   reg        saw_source_r_stall_q = 1'b0;

   function automatic bit fifo_entry_active3(
      input logic [2:0] entry,
      input logic [2:0] rd,
      input logic [3:0] count
   );
      logic [2:0] relative;
      begin
         relative = entry - rd;
         fifo_entry_active3 = ({1'b0, relative} < count);
      end
   endfunction

   wire source_aw_fire = source_aw_valid && source_aw_ready;
   wire source_w_fire  = source_w_valid && source_w_ready;
   wire source_b_fire  = source_b_valid && source_b_ready;
   wire source_ar_fire = source_ar_valid && source_ar_ready;
   wire source_r_fire  = source_r_valid && source_r_ready;
   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire  = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire  = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire  = downstream_r_valid && downstream_r_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;
   wire source1_write_req_fire = source1_req_fire && source1_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source1_read_rsp_fire = source1_rsp_fire && source1_read_rsp_active_q;

   wire source_tracked_w_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         source_w_index_q, tracked_beat);
   wire source_tracked_r_beat = observer_read_snapshot_valid_q &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         source_r_index_q, tracked_beat);
   wire downstream_tracked_w_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         downstream_w_index_q, tracked_beat);
   wire downstream_tracked_r_beat = downstream_read_active_q &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         downstream_r_index_q, tracked_beat);
   wire cachebus_tracked_w_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         cachebus_w_index_q, tracked_beat);
   wire source1_rsp_tracked_r_beat = source1_read_rsp_active_q &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         source1_rsp_index_q, tracked_beat);
   wire source_read_pending_now = source_read_ar_pending_q || source1_read_req_fire;
   wire source_downstream_ar_fire = downstream_ar_fire && source_read_pending_now;
   wire source_downstream_r_fire = downstream_r_fire && downstream_read_active_q;

   wire wpath_fifo_empty = wpath_fifo_count_q == 4'h0;
   wire wpath_fifo_full = wpath_fifo_count_q == WPATH_FIFO_DEPTH_COUNT;
   wire wpath_expected_valid = !wpath_fifo_empty || source_w_fire;
   wire [31:0] wpath_expected_data =
      !wpath_fifo_empty ? wpath_fifo_data[wpath_fifo_rd_q] : source_w_data;
   wire [3:0] wpath_expected_strb =
      !wpath_fifo_empty ? wpath_fifo_strb[wpath_fifo_rd_q] : source_w_strb;
   wire wpath_expected_last =
      !wpath_fifo_empty ? wpath_fifo_last[wpath_fifo_rd_q] : source_w_last;
   wire wpath_expected_tracked =
      !wpath_fifo_empty ? wpath_fifo_tracked[wpath_fifo_rd_q] : source_tracked_w_beat;
   wire rpath_fifo_empty = rpath_fifo_count_q == 4'h0;
   wire rpath_fifo_full = rpath_fifo_count_q == RPATH_FIFO_DEPTH_COUNT;
   wire rpath_expected_valid = !rpath_fifo_empty || source1_read_rsp_fire;
   wire [31:0] rpath_expected_data =
      !rpath_fifo_empty ? rpath_fifo_data[rpath_fifo_rd_q] : source1_rsp_data;
   wire [31:0] rpath_expected_downstream_data =
      !rpath_fifo_empty ? rpath_fifo_downstream_data[rpath_fifo_rd_q] :
      downstream_tracked_r_data_q;
   wire rpath_expected_last =
      !rpath_fifo_empty ? rpath_fifo_last[rpath_fifo_rd_q] : source1_rsp_last;
   wire rpath_expected_tracked =
      !rpath_fifo_empty ? rpath_fifo_tracked[rpath_fifo_rd_q] :
      source1_rsp_tracked_r_beat;
   wire rpath_fifo_entry0_active =
      fifo_entry_active3(3'd0, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry1_active =
      fifo_entry_active3(3'd1, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry2_active =
      fifo_entry_active3(3'd2, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry3_active =
      fifo_entry_active3(3'd3, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry4_active =
      fifo_entry_active3(3'd4, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry5_active =
      fifo_entry_active3(3'd5, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry6_active =
      fifo_entry_active3(3'd6, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry7_active =
      fifo_entry_active3(3'd7, rpath_fifo_rd_q, rpath_fifo_count_q);
   wire rpath_fifo_entry0_tracked = rpath_fifo_tracked[0];
   wire rpath_fifo_entry1_tracked = rpath_fifo_tracked[1];
   wire rpath_fifo_entry2_tracked = rpath_fifo_tracked[2];
   wire rpath_fifo_entry3_tracked = rpath_fifo_tracked[3];
   wire rpath_fifo_entry4_tracked = rpath_fifo_tracked[4];
   wire rpath_fifo_entry5_tracked = rpath_fifo_tracked[5];
   wire rpath_fifo_entry6_tracked = rpath_fifo_tracked[6];
   wire rpath_fifo_entry7_tracked = rpath_fifo_tracked[7];
   wire [31:0] rpath_fifo_entry0_data = rpath_fifo_data[0];
   wire [31:0] rpath_fifo_entry1_data = rpath_fifo_data[1];
   wire [31:0] rpath_fifo_entry2_data = rpath_fifo_data[2];
   wire [31:0] rpath_fifo_entry3_data = rpath_fifo_data[3];
   wire [31:0] rpath_fifo_entry4_data = rpath_fifo_data[4];
   wire [31:0] rpath_fifo_entry5_data = rpath_fifo_data[5];
   wire [31:0] rpath_fifo_entry6_data = rpath_fifo_data[6];
   wire [31:0] rpath_fifo_entry7_data = rpath_fifo_data[7];
   wire [31:0] rpath_fifo_entry0_downstream_data = rpath_fifo_downstream_data[0];
   wire [31:0] rpath_fifo_entry1_downstream_data = rpath_fifo_downstream_data[1];
   wire [31:0] rpath_fifo_entry2_downstream_data = rpath_fifo_downstream_data[2];
   wire [31:0] rpath_fifo_entry3_downstream_data = rpath_fifo_downstream_data[3];
   wire [31:0] rpath_fifo_entry4_downstream_data = rpath_fifo_downstream_data[4];
   wire [31:0] rpath_fifo_entry5_downstream_data = rpath_fifo_downstream_data[5];
   wire [31:0] rpath_fifo_entry6_downstream_data = rpath_fifo_downstream_data[6];
   wire [31:0] rpath_fifo_entry7_downstream_data = rpath_fifo_downstream_data[7];
   wire [31:0] tracked_write_word_now =
      (source_w_fire && source_tracked_w_beat) ?
      source_w_data : pending_tracked_write_word_q;
   wire [3:0] tracked_write_strb_now =
      (source_w_fire && source_tracked_w_beat) ?
      source_w_strb : pending_tracked_write_strb_q;

   wire [31:0] expected_committed_word =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         initial_tracked_word,
         tracked_write_word_now,
         tracked_write_strb_now);
   wire [31:0] observer_commit_word_from_source =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         observer_golden_word_q,
         tracked_write_word_now,
         tracked_write_strb_now);
   wire [31:0] observer_commit_word_now =
      source_expected_commit_valid_q ?
      source_expected_commit_word_q : observer_commit_word_from_source;
   wire [31:0] downstream_golden_word_after_write =
      (downstream_w_fire && downstream_tracked_w_beat) ?
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         downstream_golden_word_q,
         downstream_w_data,
         downstream_w_strb) :
      downstream_golden_word_q;
   wire [31:0] downstream_commit_actual_word_from_initial =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         initial_tracked_word,
         downstream_w_data,
         downstream_w_strb);
   wire [31:0] wpath_expected_commit_word_from_path =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         initial_tracked_word,
         wpath_expected_data,
         wpath_expected_strb);
   wire [31:0] source_expected_commit_word_next =
      (source_w_fire && source_tracked_w_beat) ?
      expected_committed_word : source_expected_commit_word_q;
   wire source_expected_commit_valid_next =
      source_expected_commit_valid_q ||
      (source_w_fire && source_tracked_w_beat);
   wire [31:0] committed_expected_word_next =
      (downstream_w_fire && downstream_tracked_w_beat) ?
      source_expected_commit_word_next : committed_expected_word_q;
   wire committed_expected_valid_next =
      committed_expected_valid_q ||
      (downstream_w_fire && downstream_tracked_w_beat);
   wire commit_pair_matches_next =
      source_expected_commit_valid_next &&
      committed_expected_valid_next &&
      (committed_expected_word_next == source_expected_commit_word_next);
   wire commit_pair_words_match_now =
      source_expected_commit_valid_q &&
      committed_expected_valid_q &&
      (committed_expected_word_q == source_expected_commit_word_q);
   wire wpath_commit_actual_event =
      downstream_w_fire && downstream_tracked_w_beat;
   wire wpath_commit_actual_valid =
      wpath_expected_valid && wpath_expected_tracked;
   wire [31:0] wpath_commit_actual_word =
      downstream_commit_actual_word_from_initial;
   wire wpath_commit_actual_matches_source =
      wpath_commit_actual_valid &&
      (wpath_commit_actual_word == wpath_expected_commit_word_from_path);

   integer wpath_init_i;
   integer rpath_init_i;
   always @(posedge clock) begin
      if (reset) begin
         observer_golden_word_q <= 32'h0;
         pending_tracked_write_word_q <= 32'h0;
         pending_tracked_write_strb_q <= 4'h0;
         pending_aw_len_q <= 8'h0;
         pending_aw_size_q <= SIZE4B;
         source_aw_seen_q <= 1'b0;
         source_w_index_q <= 3'h0;
         source_r_index_q <= 3'h0;
         pending_write_seen_q <= 1'b0;
         pending_wlast_seen_q <= 1'b0;
         observer_write_committed_q <= 1'b0;
         observer_expected_read_word_q <= 32'h0;
         observer_read_len_q <= 8'h0;
         observer_read_size_q <= SIZE4B;
         observer_read_snapshot_valid_q <= 1'b0;
         observer_commit_check_pending_q <= 1'b0;
         observer_precommit_word_q <= 32'h0;
         observer_commit_expected_word_q <= 32'h0;
         source_expected_commit_word_q <= 32'h0;
         source_expected_commit_valid_q <= 1'b0;
         read_snapshot_check_pending_q <= 1'b0;
         read_snapshot_expected_word_q <= 32'h0;
         read_snapshot_expected_len_q <= 8'h0;

         downstream_w_index_q <= 3'h0;
         downstream_r_index_q <= 3'h0;
         downstream_golden_word_q <= 32'h0;
         downstream_model_init_q <= 1'b0;
         downstream_commit_actual_word_q <= 32'h0;
         downstream_commit_actual_valid_q <= 1'b0;
         downstream_commit_actual_matches_source_q <= 1'b0;
         committed_expected_word_q <= 32'h0;
         committed_expected_valid_q <= 1'b0;
         downstream_tracked_write_seen_q <= 1'b0;
         commit_pair_matched_q <= 1'b0;
         downstream_w_active_q <= 1'b0;
         source1_read_req_pending_q <= 1'b0;
         source1_read_rsp_active_q <= 1'b0;
         source_read_ar_pending_q <= 1'b0;
         downstream_read_active_q <= 1'b0;
         downstream_tracked_r_data_q <= 32'h0;
         downstream_tracked_r_seen_q <= 1'b0;
         rpath_fifo_rd_q <= 3'h0;
         rpath_fifo_wr_q <= 3'h0;
         rpath_fifo_count_q <= 4'h0;

         cachebus_w_index_q <= 3'h0;
         source1_rsp_index_q <= 3'h0;

         wpath_fifo_rd_q <= 3'h0;
         wpath_fifo_wr_q <= 3'h0;
         wpath_fifo_count_q <= 4'h0;
         saw_source_b_stall_q <= 1'b0;
         saw_source_r_stall_q <= 1'b0;
         for (wpath_init_i = 0; wpath_init_i < WPATH_FIFO_DEPTH;
              wpath_init_i = wpath_init_i + 1) begin
            wpath_fifo_data[wpath_init_i] <= 32'h0;
            wpath_fifo_strb[wpath_init_i] <= 4'h0;
            wpath_fifo_last[wpath_init_i] <= 1'b0;
            wpath_fifo_tracked[wpath_init_i] <= 1'b0;
         end
         for (rpath_init_i = 0; rpath_init_i < RPATH_FIFO_DEPTH;
              rpath_init_i = rpath_init_i + 1) begin
            rpath_fifo_data[rpath_init_i] <= 32'h0;
            rpath_fifo_downstream_data[rpath_init_i] <= 32'h0;
            rpath_fifo_last[rpath_init_i] <= 1'b0;
            rpath_fifo_tracked[rpath_init_i] <= 1'b0;
         end
      end
      else begin
         observer_commit_check_pending_q <= 1'b0;
         read_snapshot_check_pending_q <= 1'b0;

         if (source_b_valid && !source_b_ready)
            saw_source_b_stall_q <= 1'b1;
         if (source_b_fire)
            saw_source_b_stall_q <= 1'b0;

         if (source_r_valid && !source_r_ready)
            saw_source_r_stall_q <= 1'b1;
         if (source_r_fire)
            saw_source_r_stall_q <= 1'b0;

         if (!downstream_model_init_q) begin
            observer_golden_word_q <= initial_tracked_word;
            downstream_golden_word_q <= initial_tracked_word;
            downstream_model_init_q <= 1'b1;
         end

         if (source_aw_fire) begin
            pending_aw_len_q <= source_aw_len;
            pending_aw_size_q <= source_aw_size;
            source_aw_seen_q <= 1'b1;
            source_w_index_q <= 3'h0;
            pending_write_seen_q <= 1'b0;
            pending_wlast_seen_q <= 1'b0;
            pending_tracked_write_word_q <= 32'h0;
            pending_tracked_write_strb_q <= 4'h0;
            source_expected_commit_word_q <= 32'h0;
            source_expected_commit_valid_q <= 1'b0;
            downstream_commit_actual_word_q <= 32'h0;
            downstream_commit_actual_valid_q <= 1'b0;
            downstream_commit_actual_matches_source_q <= 1'b0;
            commit_pair_matched_q <= 1'b0;
         end

         if (source_w_fire) begin
            if (source_tracked_w_beat) begin
               pending_tracked_write_word_q <= source_w_data;
               pending_tracked_write_strb_q <= source_w_strb;
               source_expected_commit_word_q <= expected_committed_word;
               source_expected_commit_valid_q <= 1'b1;
            end
            pending_write_seen_q <= 1'b1;
            if (source_w_last)
               pending_wlast_seen_q <= 1'b1;
            else
               source_w_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     source_w_index_q);
         end

         if (source_w_fire && (!downstream_w_fire || !wpath_fifo_empty)) begin
            wpath_fifo_data[wpath_fifo_wr_q] <= source_w_data;
            wpath_fifo_strb[wpath_fifo_wr_q] <= source_w_strb;
            wpath_fifo_last[wpath_fifo_wr_q] <= source_w_last;
            wpath_fifo_tracked[wpath_fifo_wr_q] <= source_tracked_w_beat;
         end

         if (source_w_fire && downstream_w_fire) begin
            if (!wpath_fifo_empty) begin
               wpath_fifo_rd_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(wpath_fifo_rd_q);
               wpath_fifo_wr_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(wpath_fifo_wr_q);
            end
         end
         else if (source_w_fire) begin
            if (!wpath_fifo_full) begin
               wpath_fifo_wr_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(wpath_fifo_wr_q);
               wpath_fifo_count_q <= wpath_fifo_count_q + 4'h1;
            end
         end
         else if (downstream_w_fire) begin
            if (!wpath_fifo_empty) begin
               wpath_fifo_rd_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(wpath_fifo_rd_q);
               wpath_fifo_count_q <= wpath_fifo_count_q - 4'h1;
            end
         end

         if (source_b_fire) begin
            observer_precommit_word_q <= observer_golden_word_q;
            observer_commit_expected_word_q <= observer_commit_word_now;
            observer_commit_check_pending_q <= 1'b1;
            observer_golden_word_q <= observer_commit_word_now;
            observer_write_committed_q <= 1'b1;
         end

         if (source_ar_fire) begin
            read_snapshot_expected_word_q <= observer_golden_word_q;
            read_snapshot_expected_len_q <= source_ar_len;
            read_snapshot_check_pending_q <= 1'b1;
            observer_expected_read_word_q <= observer_golden_word_q;
            observer_read_len_q <= source_ar_len;
            observer_read_size_q <= source_ar_size;
            observer_read_snapshot_valid_q <= 1'b1;
            source_r_index_q <= 3'h0;
         end

         if (source_r_fire) begin
            if (source_r_last) begin
               observer_read_snapshot_valid_q <= 1'b0;
               source_r_index_q <= 3'h0;
            end
            else begin
               source_r_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     source_r_index_q);
            end
         end

         if (downstream_aw_fire && !downstream_w_active_q)
            downstream_w_index_q <= 3'h0;

         if (source1_read_req_fire)
            source1_read_req_pending_q <= 1'b1;

         if (downstream_w_fire) begin
            downstream_w_active_q <= !downstream_w_last;
            if (downstream_tracked_w_beat) begin
               downstream_golden_word_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
                     downstream_golden_word_q,
                     downstream_w_data,
                     downstream_w_strb);
               downstream_commit_actual_word_q <= downstream_commit_actual_word_from_initial;
               downstream_commit_actual_valid_q <= 1'b1;
               downstream_commit_actual_matches_source_q <=
                  wpath_expected_valid &&
                  wpath_expected_tracked &&
                  (downstream_commit_actual_word_from_initial ==
                   wpath_expected_commit_word_from_path);
               committed_expected_word_q <= source_expected_commit_word_next;
               committed_expected_valid_q <= 1'b1;
               downstream_tracked_write_seen_q <= 1'b1;
               commit_pair_matched_q <= commit_pair_matches_next;
            end
            if (downstream_w_last)
               downstream_w_index_q <= 3'h0;
            else
               downstream_w_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     downstream_w_index_q);
         end

         if (!source_read_ar_pending_q && source1_read_req_pending_q) begin
            source_read_ar_pending_q <= 1'b1;
            source1_read_req_pending_q <= 1'b0;
         end

         if (source_downstream_ar_fire) begin
            downstream_r_index_q <= 3'h0;
            source1_rsp_index_q <= 3'h0;
            rpath_fifo_rd_q <= 3'h0;
            rpath_fifo_wr_q <= 3'h0;
            rpath_fifo_count_q <= 4'h0;
            downstream_read_active_q <= 1'b1;
            source_read_ar_pending_q <= 1'b0;
            source1_read_rsp_active_q <= 1'b1;
            downstream_tracked_r_data_q <= 32'h0;
            downstream_tracked_r_seen_q <= 1'b0;
         end

         if (source_downstream_r_fire) begin
            if (downstream_tracked_r_beat) begin
               downstream_tracked_r_data_q <= downstream_r_data;
               downstream_tracked_r_seen_q <= 1'b1;
            end
            if (downstream_r_last) begin
               downstream_r_index_q <= 3'h0;
               downstream_read_active_q <= 1'b0;
            end
            else begin
               downstream_r_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     downstream_r_index_q);
            end
         end

         if (source1_read_rsp_fire && (!source_r_fire || !rpath_fifo_empty)) begin
            rpath_fifo_data[rpath_fifo_wr_q] <= source1_rsp_data;
            rpath_fifo_downstream_data[rpath_fifo_wr_q] <=
               downstream_tracked_r_data_q;
            rpath_fifo_last[rpath_fifo_wr_q] <= source1_rsp_last;
            rpath_fifo_tracked[rpath_fifo_wr_q] <= source1_rsp_tracked_r_beat;
         end

         if (source1_read_rsp_fire && source_r_fire) begin
            if (!rpath_fifo_empty) begin
               rpath_fifo_rd_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(rpath_fifo_rd_q);
               rpath_fifo_wr_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(rpath_fifo_wr_q);
            end
         end
         else if (source1_read_rsp_fire) begin
            if (!rpath_fifo_full) begin
               rpath_fifo_wr_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(rpath_fifo_wr_q);
               rpath_fifo_count_q <= rpath_fifo_count_q + 4'h1;
            end
         end
         else if (source_r_fire) begin
            if (!rpath_fifo_empty) begin
               rpath_fifo_rd_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(rpath_fifo_rd_q);
               rpath_fifo_count_q <= rpath_fifo_count_q - 4'h1;
            end
         end

         if (source1_read_rsp_fire) begin
            if (source1_rsp_last) begin
               source1_rsp_index_q <= 3'h0;
               source1_read_rsp_active_q <= 1'b0;
            end
            else begin
               source1_rsp_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     source1_rsp_index_q);
            end
         end

         if (source1_write_req_fire) begin
            if (source1_req_valid && source1_req_ready && source1_req_wen) begin
               if (cachebus_w_index_q == pending_aw_len_q[2:0])
                  cachebus_w_index_q <= 3'h0;
               else
                  cachebus_w_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        cachebus_w_index_q);
            end
         end
      end
   end

   amba_axi4_di_crossbar_di_aligned_properties di_properties (.*);

endmodule
