`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_window_axi_memory (
   input  wire        clock,
   input  wire        reset,
   input  wire [31:0] tracked_base,
   input  wire [2:0]  tracked_beat,
   input  wire [2:0]  transfer_size,
   input  wire [31:0] initial_tracked_word,

   output wire        aw_ready,
   input  wire        aw_valid,
   input  wire [31:0] aw_addr,
   input  wire [7:0]  aw_len,
   input  wire [2:0]  aw_size,
   input  wire [1:0]  aw_id,

   output wire        w_ready,
   input  wire        w_valid,
   input  wire [31:0] w_data,
   input  wire [3:0]  w_strb,
   input  wire        w_last,

   input  wire        b_ready,
   output wire        b_valid,
   output wire [1:0]  b_resp,
   output wire [1:0]  b_id,

   output wire        ar_ready,
   input  wire        ar_valid,
   input  wire [31:0] ar_addr,
   input  wire [7:0]  ar_len,
   input  wire [2:0]  ar_size,
   input  wire [1:0]  ar_id,

   input  wire        r_ready,
   output wire        r_valid,
   output wire [31:0] r_data,
   output wire [1:0]  r_resp,
   output wire        r_last,
   output wire [1:0]  r_id,

   output wire [31:0] tracked_word
);

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_BACKPRESSURE
`define AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
`define AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
`define AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
`endif

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
`define AXI4_DI_WINDOW_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
`define AXI4_DI_WINDOW_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
`define AXI4_DI_WINDOW_ANY_DOWNSTREAM_BACKPRESSURE
`endif

`ifdef AXI4_DI_WINDOW_ANY_DOWNSTREAM_BACKPRESSURE
`ifndef AXI4_DI_WINDOW_BACKPRESSURE_MAX_STALL
`define AXI4_DI_WINDOW_BACKPRESSURE_MAX_STALL 2
`endif
`endif

   reg        aw_seen_q = 1'b0;
   reg [31:0] aw_addr_q = 32'h0;
   reg [7:0]  aw_len_q = 8'h0;
   reg [2:0]  aw_size_q = SIZE4B;
   reg [1:0]  aw_id_q = 2'h0;
   reg [2:0]  w_index_q = 3'h0;
   reg        wlast_seen_q = 1'b0;
   reg        b_valid_q = 1'b0;
   reg [1:0]  b_id_q = 2'h0;
   reg        r_valid_q = 1'b0;
   reg [31:0] r_data_q = 32'h0;
   reg [1:0]  r_id_q = 2'h0;
   reg        r_last_q = 1'b0;
   reg [31:0] ar_addr_q = 32'h0;
   reg [7:0]  ar_len_q = 8'h0;
   reg [2:0]  ar_size_q = SIZE4B;
   reg [2:0]  r_index_q = 3'h0;
   reg [2:0]  r_out_index_q = 3'h0;
   reg        rd_active_q = 1'b0;
   reg        init_done_q = 1'b0;
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
   reg [2:0]  aw_stall_count_q = 3'h0;
   (* anyseq *) wire f_aw_ready_choice;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
   reg [2:0]  w_stall_count_q = 3'h0;
   (* anyseq *) wire f_w_ready_choice;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
   reg [2:0]  ar_stall_count_q = 3'h0;
   (* anyseq *) wire f_ar_ready_choice;
`endif

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire  = w_valid && w_ready;
   wire b_fire  = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire  = r_valid && r_ready;

`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   (* anyconst *) wire f_cl1_bresp_slverr;
   (* anyconst *) wire f_cl1_rresp_slverr;
`endif

   wire [1:0]  commit_id = aw_fire ? aw_id : aw_id_q;
`ifdef AXI4_DI_WINDOW_BUG_SWAP_WSTRB_LANE01
   wire [3:0]  swapped_w_strb = {w_strb[3:2], w_strb[0], w_strb[1]};
`else
   wire [3:0]  swapped_w_strb = w_strb;
`endif
`ifdef AXI4_DI_WINDOW_BUG_IGNORE_WSTRB_LANE0
   wire [3:0]  effective_w_strb = {swapped_w_strb[3:1], 1'b0};
`else
   wire [3:0]  effective_w_strb = swapped_w_strb;
`endif

   wire aw_can_accept = !reset && init_done_q && !aw_seen_q && !b_valid_q;
   wire w_can_accept =
      !reset && init_done_q && aw_seen_q && !b_valid_q && !wlast_seen_q;
   wire ar_can_accept = !reset && init_done_q && !r_valid_q && !rd_active_q;

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
   wire aw_stall_limit_reached =
      (aw_stall_count_q >= `AXI4_DI_WINDOW_BACKPRESSURE_MAX_STALL);
   assign aw_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         aw_can_accept, aw_valid, f_aw_ready_choice, aw_stall_limit_reached);
`else
   assign aw_ready = aw_can_accept;
`endif

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
   wire w_stall_limit_reached =
      (w_stall_count_q >= `AXI4_DI_WINDOW_BACKPRESSURE_MAX_STALL);
   assign w_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         w_can_accept, w_valid, f_w_ready_choice, w_stall_limit_reached);
`else
   assign w_ready = w_can_accept;
`endif
   assign b_valid = b_valid_q;
`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   assign b_resp = f_cl1_bresp_slverr ? SLVERR : OKAY;
`else
   assign b_resp = OKAY;
`endif
   assign b_id = b_id_q;

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
   wire ar_stall_limit_reached =
      (ar_stall_count_q >= `AXI4_DI_WINDOW_BACKPRESSURE_MAX_STALL);
   assign ar_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         ar_can_accept, ar_valid, f_ar_ready_choice, ar_stall_limit_reached);
`else
   assign ar_ready = ar_can_accept;
`endif
   assign r_valid = r_valid_q;
`ifdef AXI4_DI_WINDOW_BUG_FLIP_RDATA_BYTE0
   assign r_data = r_data_q ^ 32'h0000_00ff;
`else
   assign r_data = r_data_q;
`endif
`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   assign r_resp = f_cl1_rresp_slverr ? SLVERR : OKAY;
`else
   assign r_resp = OKAY;
`endif
   assign r_last = r_last_q;
   assign r_id = r_id_q;

   wire [31:0] core_write_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         aw_addr_q, {5'h0, w_index_q}, aw_size_q);
   wire [31:0] core_ar_addr = ar_fire ? ar_addr : ar_addr_q;
   wire [31:0] core_next_read_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         ar_addr_q, {5'h0, r_index_q}, ar_size_q);
   wire [31:0] core_read_addr =
      ar_fire ? core_ar_addr :
      (!r_valid_q && rd_active_q) ? core_next_read_addr :
      core_ar_addr;
   wire        core_write_addr_in_window;
   wire        core_write_targets_tracked_slot;
   wire [31:0] core_write_old_word;
   wire [31:0] core_write_expected_word;
   wire        core_read_addr_in_window;
   wire        core_read_targets_tracked_slot;
   wire [31:0] core_read_word;
   wire [31:0] core_tracked_word;

   wire       r_is_tracked_slot =
      amba_axi4_data_integrity_pkg::axi4_di_beat_targets_tracked_slot32(
         tracked_base, ar_addr_q, r_out_index_q, tracked_beat);
   wire ar_targets_tracked_slot =
      amba_axi4_data_integrity_pkg::axi4_di_targets_tracked_slot32(
         tracked_base, ar_addr, tracked_beat);
   wire r_next_targets_tracked_slot =
      amba_axi4_data_integrity_pkg::axi4_di_beat_targets_tracked_slot32(
         tracked_base, ar_addr_q, r_index_q, tracked_beat);
   wire w_targets_tracked_slot =
      amba_axi4_data_integrity_pkg::axi4_di_beat_targets_tracked_slot32(
         tracked_base, aw_addr_q, w_index_q, tracked_beat);
   wire [31:0] ar_read_word =
      ar_targets_tracked_slot ? core_read_word : 32'h0;
   wire [31:0] r_read_word =
      r_next_targets_tracked_slot ? core_read_word : 32'h0;
   assign tracked_word = core_tracked_word;

   amba_axi4_di_golden_memory_core memory_core (
      .clock(clock),
      .reset(reset),
      .init(!init_done_q),
      .base_addr(tracked_base),
      .tracked_beat(tracked_beat),
      .initial_tracked_word(initial_tracked_word),
      .write_fire(w_fire),
      .write_addr(core_write_addr),
      .write_data(w_data),
      .write_strb(effective_w_strb),
      .write_addr_in_window(core_write_addr_in_window),
      .write_targets_tracked_slot(core_write_targets_tracked_slot),
      .write_old_word(core_write_old_word),
      .write_expected_word(core_write_expected_word),
      .read_addr(core_read_addr),
      .read_addr_in_window(core_read_addr_in_window),
      .read_targets_tracked_slot(core_read_targets_tracked_slot),
      .read_word(core_read_word),
      .read1_addr(32'h0),
      .read1_addr_in_window(),
      .read1_targets_tracked_slot(),
      .read1_word(),
      .read2_addr(32'h0),
      .read2_addr_in_window(),
      .read2_targets_tracked_slot(),
      .read2_word(),
      .tracked_word(core_tracked_word)
   );

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         aw_seen_q <= 1'b0;
         aw_addr_q <= 32'h0;
         aw_len_q <= 8'h0;
         aw_size_q <= SIZE4B;
         aw_id_q <= 2'h0;
         w_index_q <= 3'h0;
         wlast_seen_q <= 1'b0;
         b_valid_q <= 1'b0;
         b_id_q <= 2'h0;
         r_valid_q <= 1'b0;
         r_data_q <= 32'h0;
         r_id_q <= 2'h0;
         r_last_q <= 1'b0;
         ar_addr_q <= 32'h0;
         ar_len_q <= 8'h0;
         ar_size_q <= SIZE4B;
         r_index_q <= 3'h0;
         r_out_index_q <= 3'h0;
         rd_active_q <= 1'b0;
         init_done_q <= 1'b0;
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
         aw_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
         w_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
         ar_stall_count_q <= 3'h0;
`endif
      end
      else begin
         if (!init_done_q) begin
            aw_seen_q <= 1'b0;
            aw_addr_q <= 32'h0;
            aw_len_q <= 8'h0;
            aw_size_q <= SIZE4B;
            aw_id_q <= 2'h0;
            w_index_q <= 3'h0;
            wlast_seen_q <= 1'b0;
            b_valid_q <= 1'b0;
            b_id_q <= 2'h0;
            r_valid_q <= 1'b0;
            r_data_q <= 32'h0;
            r_id_q <= 2'h0;
            r_last_q <= 1'b0;
            ar_addr_q <= 32'h0;
            ar_len_q <= 8'h0;
            ar_size_q <= SIZE4B;
            r_index_q <= 3'h0;
            r_out_index_q <= 3'h0;
            rd_active_q <= 1'b0;
            init_done_q <= 1'b1;
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
            aw_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
            w_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
            ar_stall_count_q <= 3'h0;
`endif
         end
         else begin
`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE
            if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                   aw_valid && aw_can_accept, aw_ready, 1'b0))
               aw_stall_count_q <= aw_stall_count_q + 3'h1;
            else
               aw_stall_count_q <= 3'h0;
`endif

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE
            if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                   w_valid && w_can_accept, w_ready, 1'b0))
               w_stall_count_q <= w_stall_count_q + 3'h1;
            else
               w_stall_count_q <= 3'h0;
`endif

`ifdef AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE
            if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                   ar_valid && ar_can_accept, ar_ready, 1'b0))
               ar_stall_count_q <= ar_stall_count_q + 3'h1;
            else
               ar_stall_count_q <= 3'h0;
`endif

            if (b_fire) begin
               b_valid_q <= 1'b0;
               aw_seen_q <= 1'b0;
               wlast_seen_q <= 1'b0;
               w_index_q <= 3'h0;
            end

            if (r_fire) begin
               r_valid_q <= 1'b0;
               r_last_q <= 1'b0;
               if (r_last_q) begin
                  rd_active_q <= 1'b0;
                  r_index_q <= 3'h0;
                  r_out_index_q <= 3'h0;
               end
            end

            if (aw_fire) begin
               aw_seen_q <= 1'b1;
               aw_addr_q <= aw_addr;
               aw_len_q <= aw_len;
               aw_size_q <= aw_size;
               aw_id_q <= aw_id;
               w_index_q <= 3'h0;
               wlast_seen_q <= 1'b0;
            end

            if (w_fire) begin
               if (w_last) begin
                  wlast_seen_q <= 1'b1;
                  b_valid_q <= 1'b1;
                  b_id_q <= commit_id;
               end
               else begin
                  w_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        w_index_q);
               end
            end

            if (ar_fire) begin
               r_valid_q <= 1'b1;
               r_id_q <= ar_id;
               r_data_q <= ar_read_word;
               r_last_q <= (ar_len == 8'h00);
               ar_addr_q <= ar_addr;
               ar_len_q <= ar_len;
               ar_size_q <= ar_size;
               r_index_q <= 3'h1;
               r_out_index_q <= 3'h0;
               rd_active_q <= (ar_len != 8'h00);
            end
            else if (!r_valid_q && rd_active_q) begin
               r_valid_q <= 1'b1;
               r_data_q <= r_read_word;
               r_last_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_is_last_beat(
                     {5'h0, r_index_q}, ar_len_q);
               r_out_index_q <= r_index_q;
               if (r_index_q != ar_len_q[2:0]) begin
                  r_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        r_index_q);
               end
            end
         end
      end
   end

   amba_axi4_di_window_axi_memory_properties mem_properties (
      .clock(clock),
      .reset(reset),
      .b_valid(b_valid),
      .aw_seen(aw_seen_q),
      .wlast_seen(wlast_seen_q),
      .w_fire(w_fire),
      .w_index(w_index_q),
      .aw_len(aw_len_q),
      .r_valid(r_valid),
      .r_index(r_out_index_q),
      .ar_len(ar_len_q),
      .r_is_tracked_slot(r_is_tracked_slot),
      .r_data(r_data),
      .tracked_word(core_tracked_word),
      .aw_valid(aw_valid),
      .aw_can_accept(aw_can_accept),
      .aw_ready(aw_ready),
      .aw_fire(aw_fire),
      .w_valid(w_valid),
      .w_can_accept(w_can_accept),
      .w_ready(w_ready),
      .ar_valid(ar_valid),
      .ar_can_accept(ar_can_accept),
      .ar_ready(ar_ready),
      .ar_fire(ar_fire)
   );
endmodule

module amba_axi4_di_window_observer (
   input  wire        clock,
   input  wire        reset,
   input  wire [31:0] initial_tracked_word,
   input  wire [2:0]  tracked_beat,
   input  wire [2:0]  transfer_size,

   input  wire        aw_valid,
   input  wire        aw_ready,
   input  wire [31:0] aw_addr,
   input  wire [7:0]  aw_len,
   input  wire [2:0]  aw_size,
   input  wire [1:0]  aw_burst,

   input  wire        w_valid,
   input  wire        w_ready,
   input  wire [31:0] w_data,
   input  wire [3:0]  w_strb,
   input  wire        w_last,

   input  wire        b_valid,
   input  wire        b_ready,
   input  wire [1:0]  b_resp,

   input  wire        ar_valid,
   input  wire        ar_ready,
   input  wire [31:0] ar_addr,
   input  wire [7:0]  ar_len,
   input  wire [2:0]  ar_size,
   input  wire [1:0]  ar_burst,

   input  wire        r_valid,
   input  wire        r_ready,
   input  wire [31:0] r_data,
   input  wire [1:0]  r_resp,
   input  wire        r_last,

   input  wire [31:0] tracked_base,
   output wire        write_committed,
   output wire        read_compared,
   output wire [31:0] golden_tracked_word,
   output wire [31:0] expected_read_tracked_word,
   output wire        read_snapshot_valid
);

   reg [31:0]  golden_tracked_word_q = 32'h0;
   reg [31:0]  pending_tracked_write_word_q = 32'h0;
   reg [3:0]   pending_tracked_write_strb_q = 4'h0;
   reg [7:0]   pending_aw_len_q = 8'h0;
   reg [2:0]   w_index_q = 3'h0;
   reg [2:0]   r_index_q = 3'h0;
   reg [2:0]   compared_index_q = 3'h0;
   reg         pending_write_seen_q = 1'b0;
   reg         pending_wlast_seen_q = 1'b0;
   reg        write_committed_q = 1'b0;
   reg [31:0]  expected_read_tracked_word_q = 32'h0;
   reg [7:0]   read_len_q = 8'h0;
   reg        read_snapshot_valid_q = 1'b0;
   reg        read_compared_q = 1'b0;
   reg        init_done_q = 1'b0;

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire  = w_valid && w_ready;
   wire b_fire  = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire  = r_valid && r_ready;

   assign write_committed = write_committed_q;
   assign read_compared = read_compared_q;
   assign golden_tracked_word = golden_tracked_word_q;
   assign expected_read_tracked_word = expected_read_tracked_word_q;
   assign read_snapshot_valid = read_snapshot_valid_q;

   wire r_is_tracked_beat = read_snapshot_valid_q &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         r_index_q, tracked_beat);

   amba_axi4_di_word_properties word_properties (
      .clock(clock),
      .reset(reset),
      .active(1'b1),
      .model_initialized(init_done_q),
      .write_fire(w_fire),
      .write_strb(w_strb),
      .write_len(pending_aw_len_q),
      .commit_fire(b_fire),
      .commit_cover_valid(pending_write_seen_q),
      .commit_is_single_beat(pending_aw_len_q == 8'h00),
      .tracked_word(golden_tracked_word_q),
      .pending_write_word(pending_tracked_write_word_q),
      .pending_write_strb(pending_tracked_write_strb_q),
      .snapshot_fire(ar_fire),
      .snapshot_cover_valid(write_committed_q),
      .snapshot_len(ar_len),
      .snapshot_valid(read_snapshot_valid_q),
      .expected_read_word(expected_read_tracked_word_q),
      .read_fire(r_fire),
      .read_is_tracked_beat(r_is_tracked_beat),
      .read_data(r_data),
      .read_index(r_index_q),
      .read_len(read_len_q),
      .read_last(r_last)
   );

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         golden_tracked_word_q <= 32'h0;
         pending_tracked_write_word_q <= 32'h0;
         pending_tracked_write_strb_q <= 4'h0;
         pending_aw_len_q <= 8'h0;
         w_index_q <= 3'h0;
         r_index_q <= 3'h0;
         compared_index_q <= 3'h0;
         pending_write_seen_q <= 1'b0;
         pending_wlast_seen_q <= 1'b0;
         write_committed_q <= 1'b0;
         expected_read_tracked_word_q <= 32'h0;
         read_len_q <= 8'h0;
         read_snapshot_valid_q <= 1'b0;
         read_compared_q <= 1'b0;
         init_done_q <= 1'b0;
      end
      else begin
         if (!init_done_q) begin
            golden_tracked_word_q <= initial_tracked_word;
            pending_tracked_write_word_q <= 32'h0;
            pending_tracked_write_strb_q <= 4'h0;
            pending_aw_len_q <= 8'h0;
            w_index_q <= 3'h0;
            r_index_q <= 3'h0;
            compared_index_q <= 3'h0;
            pending_write_seen_q <= 1'b0;
            pending_wlast_seen_q <= 1'b0;
            write_committed_q <= 1'b0;
            expected_read_tracked_word_q <= 32'h0;
            read_len_q <= 8'h0;
            read_snapshot_valid_q <= 1'b0;
            read_compared_q <= 1'b0;
            init_done_q <= 1'b1;
         end
         else begin
            if (aw_fire) begin
               pending_aw_len_q <= aw_len;
               w_index_q <= 3'h0;
               pending_write_seen_q <= 1'b0;
               pending_wlast_seen_q <= 1'b0;
               pending_tracked_write_word_q <= 32'h0;
               pending_tracked_write_strb_q <= 4'h0;
            end

            if (w_fire) begin
               if (amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
                      w_index_q, tracked_beat)) begin
                  pending_tracked_write_word_q <= w_data;
                  pending_tracked_write_strb_q <= w_strb;
               end
               pending_write_seen_q <= 1'b1;
               if (w_last) begin
                  pending_wlast_seen_q <= 1'b1;
               end
               else begin
                  w_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        w_index_q);
               end
            end

            if (b_fire) begin
               golden_tracked_word_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
                     golden_tracked_word_q,
                     pending_tracked_write_word_q,
                     pending_tracked_write_strb_q);
               write_committed_q <= 1'b1;
            end

            if (ar_fire) begin
               expected_read_tracked_word_q <= golden_tracked_word_q;
               read_len_q <= ar_len;
               r_index_q <= 3'h0;
               read_snapshot_valid_q <= 1'b1;
            end

            if (r_fire) begin
               read_compared_q <= 1'b1;
               compared_index_q <= r_index_q;
               if (r_last) begin
                  read_snapshot_valid_q <= 1'b0;
                  r_index_q <= 3'h0;
               end
               else begin
                  r_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        r_index_q);
               end
            end
         end
      end
   end

   amba_axi4_di_window_observer_properties obs_properties (
      .clock(clock),
      .reset(reset),
      .aw_fire(aw_fire),
      .aw_addr(aw_addr),
      .aw_len(aw_len),
      .aw_size(aw_size),
      .aw_burst(aw_burst),
      .tracked_base(tracked_base),
      .transfer_size(transfer_size),
      .w_fire(w_fire),
      .w_index(w_index_q),
      .pending_aw_len(pending_aw_len_q),
      .w_last(w_last),
      .b_fire(b_fire),
      .pending_write_seen(pending_write_seen_q),
      .pending_wlast_seen(pending_wlast_seen_q),
      .b_resp(b_resp),
      .ar_fire(ar_fire),
      .write_committed(write_committed_q),
      .ar_addr(ar_addr),
      .ar_len(ar_len),
      .ar_size(ar_size),
      .ar_burst(ar_burst),
      .read_snapshot_valid(read_snapshot_valid_q),
      .r_fire(r_fire),
      .r_resp(r_resp)
   );
endmodule


`default_nettype wire
