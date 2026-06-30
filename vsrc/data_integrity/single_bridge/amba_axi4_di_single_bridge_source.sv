`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_single_bridge_burst_source (
   input  wire        clock,
   input  wire        reset,
   input  wire [2:0]  tracked_beat,

   input  wire        aw_ready,
   output wire        aw_valid,
   output wire [1:0]  aw_id,
   output wire [31:0] aw_addr,
   output wire [7:0]  aw_len,
   output wire [2:0]  aw_size,
   output wire [1:0]  aw_burst,
   output wire        aw_lock,
   output wire [3:0]  aw_cache,
   output wire [2:0]  aw_prot,

   input  wire        w_ready,
   output wire        w_valid,
   output wire [31:0] w_data,
   output wire [3:0]  w_strb,
   output wire        w_last,

   input  wire        b_valid,
   input  wire [1:0]  b_resp,
   output wire        b_ready,

   input  wire        ar_ready,
   output wire        ar_valid,
   output wire [1:0]  ar_id,
   output wire [31:0] ar_addr,
   output wire [7:0]  ar_len,
   output wire [2:0]  ar_size,
   output wire [1:0]  ar_burst,
   output wire        ar_lock,
   output wire [3:0]  ar_cache,
   output wire [2:0]  ar_prot,

   input  wire        r_valid,
   input  wire [31:0] r_data,
   input  wire [1:0]  r_resp,
   input  wire        r_last,
   output wire        r_ready,

   output wire [31:0] tracked_base,
   output wire [7:0]  burst_len,
   output wire [2:0]  transfer_size,
   output wire [31:0] tracked_write_data,
   output wire [3:0]  tracked_write_strb,
   output wire        write_done,
   output wire        compare_done
);

`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
`ifndef AXI4_DI_SINGLE_BRIDGE_BACKPRESSURE_MAX_STALL
`define AXI4_DI_SINGLE_BRIDGE_BACKPRESSURE_MAX_STALL 2
`endif
`endif

   localparam logic [2:0] PH_AW   = 3'd0;
   localparam logic [2:0] PH_W    = 3'd1;
   localparam logic [2:0] PH_B    = 3'd2;
   localparam logic [2:0] PH_AR   = 3'd3;
   localparam logic [2:0] PH_R    = 3'd4;
   localparam logic [2:0] PH_DONE = 3'd5;

   (* anyconst *) wire [26:0]  f_tracked_window_addr;
   (* anyconst *) wire [2:0]   f_burst_len;
`ifdef AXI4_DI_SINGLE_BRIDGE_UNCACHE_SINGLE_BEAT
   (* anyconst *) wire [29:0]  f_uncache_word_addr;
   (* anyconst *) wire [1:0]   f_uncache_addr_offset;
   (* anyconst *) wire [1:0]   f_uncache_size;
`endif
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
   (* anyconst *) wire [31:0]  f_tracked_write_data;
   (* anyconst *) wire [31:0]  f_other_write_data;
   (* anyconst *) wire [3:0]   f_tracked_write_strb;
   (* anyconst *) wire [3:0]   f_other_write_strb;
`else
   (* anyconst *) wire [255:0] f_write_data_flat;
   (* anyconst *) wire [31:0]  f_write_strb_flat;
`endif

   reg [2:0]  phase_q = PH_AW;
   reg [31:0] tracked_base_q = 32'h0;
   reg [2:0]  tracked_beat_q = 3'h0;
   reg [2:0]  burst_len_q = 3'h0;
   reg [1:0]  transfer_size_q = 2'h2;
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
   reg [31:0] tracked_write_data_q = 32'h0;
   reg [31:0] other_write_data_q = 32'h0;
   reg [3:0]  tracked_write_strb_q = 4'h0;
   reg [3:0]  other_write_strb_q = 4'h0;
`else
   reg [255:0] write_data_flat_q = 256'h0;
   reg [31:0]  write_strb_flat_q = 32'h0;
`endif
   reg [2:0]  write_index_q = 3'h0;
   reg        reset_released_q = 1'b0;
   reg        write_done_q = 1'b0;
   reg        compare_done_q = 1'b0;
`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
   reg [2:0]  b_stall_count_q = 3'h0;
   reg [2:0]  r_stall_count_q = 3'h0;

   (* anyseq *) wire f_b_ready_choice;
   (* anyseq *) wire f_r_ready_choice;
`endif

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire  = w_valid && w_ready;
   wire b_fire  = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire  = r_valid && r_ready;

   assign tracked_base = tracked_base_q;
   assign burst_len = {5'h0, burst_len_q};
   assign transfer_size = {1'b0, transfer_size_q};
   assign write_done = write_done_q;
   assign compare_done = compare_done_q;

`ifdef AXI4_DI_SINGLE_BRIDGE_UNCACHE_SINGLE_BEAT
   wire [1:0] uncache_size =
      (f_uncache_size == 2'h3) ? 2'h2 : f_uncache_size;
   wire [1:0] uncache_addr_offset =
      (uncache_size == 2'h0) ? f_uncache_addr_offset :
      (uncache_size == 2'h1) ? {f_uncache_addr_offset[1], 1'b0} :
      2'b00;
   wire [31:0] uncache_addr =
      {f_uncache_word_addr, uncache_addr_offset};
   wire [3:0] uncache_write_strb =
      (uncache_size == 2'h0) ? (4'b0001 << uncache_addr_offset) :
      (uncache_size == 2'h1) ? (uncache_addr_offset[1] ? 4'b1100 : 4'b0011) :
      4'b1111;
`endif

   function automatic [31:0] select_write_data;
      input [2:0]   index;
      begin
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
         select_write_data =
            (index == tracked_beat_q) ? tracked_write_data_q : other_write_data_q;
`else
         select_write_data = write_data_flat_q[(index << 5) +: 32];
`endif
      end
   endfunction

   function automatic [3:0] select_write_strb;
      input [2:0]  index;
      begin
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
         select_write_strb =
            (index == tracked_beat_q) ? tracked_write_strb_q : other_write_strb_q;
`else
         select_write_strb = write_strb_flat_q[(index << 2) +: 4];
`endif
      end
   endfunction

   assign tracked_write_data = select_write_data(tracked_beat_q);
   assign tracked_write_strb = select_write_strb(tracked_beat_q);

   assign aw_valid = !reset && reset_released_q && (phase_q == PH_AW);
   assign aw_id = 2'h0;
   assign aw_addr = tracked_base_q;
   assign aw_len = {5'h0, burst_len_q};
   assign aw_size = {1'b0, transfer_size_q};
   assign aw_burst = INCR;
   assign aw_lock = NORMAL;
   assign aw_cache = 4'h0;
   assign aw_prot = 3'h0;

   assign w_valid = !reset && reset_released_q && (phase_q == PH_W);
   assign w_data = select_write_data(write_index_q);
   assign w_strb = select_write_strb(write_index_q);
   assign w_last = (write_index_q == burst_len_q);

`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
   wire b_stall_limit_reached =
      (b_stall_count_q >= `AXI4_DI_SINGLE_BRIDGE_BACKPRESSURE_MAX_STALL);
   wire r_stall_limit_reached =
      (r_stall_count_q >= `AXI4_DI_SINGLE_BRIDGE_BACKPRESSURE_MAX_STALL);

   assign b_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         !reset, b_valid, f_b_ready_choice, b_stall_limit_reached);
`else
   assign b_ready = !reset;
`endif

   assign ar_valid = !reset && reset_released_q && (phase_q == PH_AR);
   assign ar_id = 2'h0;
   assign ar_addr = tracked_base_q;
   assign ar_len = {5'h0, burst_len_q};
   assign ar_size = {1'b0, transfer_size_q};
   assign ar_burst = INCR;
   assign ar_lock = NORMAL;
   assign ar_cache = 4'h0;
   assign ar_prot = 3'h0;

`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
   assign r_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         !reset, r_valid, f_r_ready_choice, r_stall_limit_reached);
`else
   assign r_ready = !reset;
`endif

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         phase_q <= PH_AW;
         tracked_base_q <= 32'h0;
         tracked_beat_q <= 3'h0;
         burst_len_q <= 3'h0;
         transfer_size_q <= 2'h2;
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
         tracked_write_data_q <= 32'h0;
         other_write_data_q <= 32'h0;
         tracked_write_strb_q <= 4'h0;
         other_write_strb_q <= 4'h0;
`else
         write_data_flat_q <= 256'h0;
         write_strb_flat_q <= 32'h0;
`endif
         write_index_q <= 3'h0;
         reset_released_q <= 1'b0;
         write_done_q <= 1'b0;
         compare_done_q <= 1'b0;
`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
         b_stall_count_q <= 3'h0;
         r_stall_count_q <= 3'h0;
`endif
      end
      else begin
         if (!reset_released_q) begin
            phase_q <= PH_AW;
`ifdef AXI4_DI_SINGLE_BRIDGE_UNCACHE_SINGLE_BEAT
            tracked_base_q <= uncache_addr;
            tracked_beat_q <= 3'h0;
            burst_len_q <= 3'h0;
            transfer_size_q <= uncache_size;
`else
            tracked_base_q <= {f_tracked_window_addr, 5'b00000};
            tracked_beat_q <= tracked_beat;
`ifdef AXI4_DI_SINGLE_BRIDGE_FORCE_SINGLE_BEAT
            burst_len_q <= 3'h0;
`else
            burst_len_q <= f_burst_len;
`endif
            transfer_size_q <= 2'h2;
`endif
`ifdef AXI4_DI_SINGLE_BRIDGE_OPT_TRACKED_PAYLOAD
            tracked_write_data_q <= f_tracked_write_data;
            other_write_data_q <= f_other_write_data;
`ifdef AXI4_DI_SINGLE_BRIDGE_UNCACHE_SINGLE_BEAT
            tracked_write_strb_q <= uncache_write_strb;
            other_write_strb_q <= uncache_write_strb;
`else
            tracked_write_strb_q <= f_tracked_write_strb;
            other_write_strb_q <= f_other_write_strb;
`endif
`else
            write_data_flat_q <= f_write_data_flat;
`ifdef AXI4_DI_SINGLE_BRIDGE_UNCACHE_SINGLE_BEAT
            write_strb_flat_q <= {8{uncache_write_strb}};
`else
            write_strb_flat_q <= f_write_strb_flat;
`endif
`endif
            write_index_q <= 3'h0;
            reset_released_q <= 1'b1;
            write_done_q <= 1'b0;
            compare_done_q <= 1'b0;
`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
            b_stall_count_q <= 3'h0;
            r_stall_count_q <= 3'h0;
`endif
         end
         else begin
`ifdef AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE
            if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                   b_valid, b_ready, 1'b0))
               b_stall_count_q <= b_stall_count_q + 3'h1;
            else
               b_stall_count_q <= 3'h0;

            if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                   r_valid, r_ready, 1'b0))
               r_stall_count_q <= r_stall_count_q + 3'h1;
            else
               r_stall_count_q <= 3'h0;
`endif

            case (phase_q)
               PH_AW:
                  if (aw_fire)
                     phase_q <= PH_W;
               PH_W:
                  if (w_fire) begin
                     if (write_index_q == burst_len_q) begin
                        phase_q <= PH_B;
                     end
                     else begin
                        write_index_q <=
                           amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                              write_index_q);
                     end
                  end
               PH_B:
                  if (b_fire) begin
                     write_done_q <= 1'b1;
`ifdef AXI4_DI_SINGLE_BRIDGE_WRITE_ONLY_TRANSACTION
                     phase_q <= PH_DONE;
`else
                     phase_q <= PH_AR;
`endif
                  end
               PH_AR:
                  if (ar_fire)
                     phase_q <= PH_R;
               PH_R:
                  if (r_fire && r_last) begin
                     compare_done_q <= 1'b1;
                     phase_q <= PH_DONE;
                  end
               default:
                  phase_q <= PH_DONE;
            endcase
         end
      end
   end

   // OSS flow attaches properties explicitly because Yosys does not elaborate
   // the bind wrapper for this data-integrity model.
   amba_axi4_di_single_bridge_source_properties source_properties (
      .clock(clock),
      .reset(reset),
      .aw_fire(aw_fire),
      .w_fire(w_fire),
      .b_fire(b_fire),
      .ar_fire(ar_fire),
      .r_fire(r_fire),
      .compare_done_q(compare_done_q),
      .burst_len_q(burst_len_q),
      .b_valid(b_valid),
      .b_ready(b_ready),
      .r_valid(r_valid),
      .r_ready(r_ready),
      .r_last(r_last)
   );

endmodule

`default_nettype wire
