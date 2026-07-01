`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module data_integrity_crossbar_tb (
   input wire clock,
   input wire reset
);

   localparam int unsigned CL1_ID_WIDTH      = 2;
   localparam int unsigned CL1_ADDRESS_WIDTH = 32;
   localparam int unsigned CL1_DATA_WIDTH    = 32;
   localparam int unsigned CL1_USER_WIDTH    = 1;
   localparam int unsigned CL1_MAX_BURSTS    = 1;
   localparam int unsigned CL1_MAX_LENGTH    = 8;
   localparam logic [2:0]  CL1_DATA_PROT     = 3'b000;
   localparam logic [2:0]  CL1_INSTR_PROT    = 3'b100;

`ifdef CL1_XBAR_READ_ARBITRATION_SCENARIO
   localparam bit CL1_SOURCE0_ENABLE_WRITE = 1'b0;
   localparam bit CL1_SOURCE1_ENABLE_WRITE = 1'b0;
   localparam logic [31:0] CL1_SHARED_ADDR = 32'h0000_1000;
   localparam logic [31:0] CL1_SOURCE0_WRITE_ADDR = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE0_READ_ADDR  = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE1_WRITE_ADDR = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE1_READ_ADDR  = CL1_SHARED_ADDR;
`elsif CL1_XBAR_WINDOWED_ADDRESS_MODE
   localparam bit CL1_SOURCE0_ENABLE_WRITE = 1'b1;
   localparam bit CL1_SOURCE1_ENABLE_WRITE = 1'b1;
   localparam logic [31:0] CL1_SOURCE0_WRITE_ADDR = 32'h0000_1000;
   localparam logic [31:0] CL1_SOURCE0_READ_ADDR  = 32'h0000_2000;
   localparam logic [31:0] CL1_SOURCE1_WRITE_ADDR = 32'h0000_3000;
   localparam logic [31:0] CL1_SOURCE1_READ_ADDR  = 32'h0000_4000;
`else
   localparam bit CL1_SOURCE0_ENABLE_WRITE = 1'b0;
   localparam bit CL1_SOURCE1_ENABLE_WRITE = 1'b1;
   localparam logic [31:0] CL1_SHARED_ADDR = 32'h0000_1000;
   localparam logic [31:0] CL1_SOURCE0_WRITE_ADDR = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE0_READ_ADDR  = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE1_WRITE_ADDR = CL1_SHARED_ADDR;
   localparam logic [31:0] CL1_SOURCE1_READ_ADDR  = CL1_SHARED_ADDR;
`endif

   reg f_past_valid = 1'b0;
`ifdef CL1_XBAR_DI_ENABLE
   (* anyconst *) wire [31:0] f_cl1_xbar_initial_tracked_word;
   (* anyconst *) wire [2:0]  f_cl1_xbar_tracked_beat;
`endif
`ifdef CL1_XBAR_SYMBOLIC_ADDR_MODE
`ifdef CL1_XBAR_DI_UNCACHE_SINGLE_BEAT
`define CL1_XBAR_DI_SYMBOLIC_BYTE_ADDR_PROFILE
`endif
`ifdef CL1_XBAR_DI_MIXED_SINGLE_BURST
`define CL1_XBAR_DI_SYMBOLIC_BYTE_ADDR_PROFILE
`endif
`ifdef CL1_XBAR_DI_SYMBOLIC_BYTE_ADDR_PROFILE
   (* anyconst *) wire [29:0] f_cl1_xbar_uncache_word_addr;
   (* anyconst *) wire [1:0]  f_cl1_xbar_uncache_addr_offset;
   (* anyconst *) wire [1:0]  f_cl1_xbar_uncache_size_choice;
   (* anyconst *) wire [26:0] f_cl1_symbolic_shared_window;
`ifdef CL1_XBAR_DI_MIXED_SINGLE_BURST
`ifdef CL1_XBAR_DI_MIXED_TRANSITION
   (* anyconst *) wire        f_cl1_xbar_mixed_write_uncache_mode;
   (* anyconst *) wire        f_cl1_xbar_mixed_read_uncache_mode;
`else
   (* anyconst *) wire        f_cl1_xbar_mixed_uncache_mode;
`endif
`endif
   wire [1:0] cl1_xbar_uncache_size =
      (f_cl1_xbar_uncache_size_choice == 2'h3) ?
      2'h2 : f_cl1_xbar_uncache_size_choice;
   wire [1:0] cl1_xbar_uncache_offset =
      (cl1_xbar_uncache_size == 2'h0) ? f_cl1_xbar_uncache_addr_offset :
      (cl1_xbar_uncache_size == 2'h1) ? {f_cl1_xbar_uncache_addr_offset[1], 1'b0} :
      2'b00;
   wire [31:0] cl1_xbar_uncache_addr =
      {f_cl1_xbar_uncache_word_addr, cl1_xbar_uncache_offset};
   wire [31:0] cl1_xbar_burst_addr = {f_cl1_symbolic_shared_window, 5'h0};
`ifdef CL1_XBAR_DI_MIXED_SINGLE_BURST
`ifdef CL1_XBAR_DI_MIXED_TRANSITION
   wire cl1_xbar_mixed_write_uncache_mode =
      f_cl1_xbar_mixed_write_uncache_mode;
   wire cl1_xbar_mixed_read_uncache_mode =
      f_cl1_xbar_mixed_read_uncache_mode;
   always @(*) begin
      assume(cl1_xbar_mixed_write_uncache_mode !=
             cl1_xbar_mixed_read_uncache_mode);
      assume(f_cl1_xbar_uncache_word_addr[29:3] ==
             f_cl1_symbolic_shared_window);
      assume(f_cl1_xbar_uncache_word_addr[2:0] == 3'h0);
   end
   wire [31:0] cl1_xbar_symbolic_write_addr =
      cl1_xbar_mixed_write_uncache_mode ? cl1_xbar_uncache_addr :
      cl1_xbar_burst_addr;
   wire [31:0] cl1_xbar_symbolic_read_addr =
      cl1_xbar_mixed_read_uncache_mode ? cl1_xbar_uncache_addr :
      cl1_xbar_burst_addr;
   wire [2:0] cl1_xbar_symbolic_write_size =
      cl1_xbar_mixed_write_uncache_mode ? {1'b0, cl1_xbar_uncache_size} :
      SIZE4B;
   wire [2:0] cl1_xbar_symbolic_read_size =
      cl1_xbar_mixed_read_uncache_mode ? {1'b0, cl1_xbar_uncache_size} :
      SIZE4B;
   wire [31:0] cl1_symbolic_shared_addr_q = cl1_xbar_symbolic_write_addr;
   wire [2:0] cl1_xbar_symbolic_size = cl1_xbar_symbolic_write_size;
`else
   wire cl1_xbar_mixed_uncache_mode = f_cl1_xbar_mixed_uncache_mode;
`ifdef CL1_XBAR_DI_MIXED_FORCE_UNCACHE
   always @(*) assume(cl1_xbar_mixed_uncache_mode);
`endif
`ifdef CL1_XBAR_DI_MIXED_FORCE_BURST
   always @(*) assume(!cl1_xbar_mixed_uncache_mode);
`endif
   wire [31:0] cl1_symbolic_shared_addr_q =
      cl1_xbar_mixed_uncache_mode ? cl1_xbar_uncache_addr : cl1_xbar_burst_addr;
   wire [2:0] cl1_xbar_symbolic_size =
      cl1_xbar_mixed_uncache_mode ? {1'b0, cl1_xbar_uncache_size} : SIZE4B;
   wire [31:0] cl1_xbar_symbolic_write_addr = cl1_symbolic_shared_addr_q;
   wire [31:0] cl1_xbar_symbolic_read_addr = cl1_symbolic_shared_addr_q;
   wire [2:0] cl1_xbar_symbolic_write_size = cl1_xbar_symbolic_size;
   wire [2:0] cl1_xbar_symbolic_read_size = cl1_xbar_symbolic_size;
   wire cl1_xbar_mixed_write_uncache_mode = cl1_xbar_mixed_uncache_mode;
   wire cl1_xbar_mixed_read_uncache_mode = cl1_xbar_mixed_uncache_mode;
`endif
`else
   wire [31:0] cl1_symbolic_shared_addr_q = cl1_xbar_uncache_addr;
   wire [2:0] cl1_xbar_symbolic_size = {1'b0, cl1_xbar_uncache_size};
   wire [31:0] cl1_xbar_symbolic_write_addr = cl1_symbolic_shared_addr_q;
   wire [31:0] cl1_xbar_symbolic_read_addr = cl1_symbolic_shared_addr_q;
   wire [2:0] cl1_xbar_symbolic_write_size = cl1_xbar_symbolic_size;
   wire [2:0] cl1_xbar_symbolic_read_size = cl1_xbar_symbolic_size;
   wire cl1_xbar_mixed_write_uncache_mode = 1'b1;
   wire cl1_xbar_mixed_read_uncache_mode = 1'b1;
`endif
`else
   (* anyconst *) wire [26:0] f_cl1_symbolic_shared_window;
   wire [31:0] cl1_symbolic_shared_addr_q = {f_cl1_symbolic_shared_window, 5'h0};
   wire [2:0] cl1_xbar_symbolic_size = SIZE4B;
   wire [31:0] cl1_xbar_symbolic_write_addr = cl1_symbolic_shared_addr_q;
   wire [31:0] cl1_xbar_symbolic_read_addr = cl1_symbolic_shared_addr_q;
   wire [2:0] cl1_xbar_symbolic_write_size = cl1_xbar_symbolic_size;
   wire [2:0] cl1_xbar_symbolic_read_size = cl1_xbar_symbolic_size;
   wire cl1_xbar_mixed_write_uncache_mode = 1'b0;
   wire cl1_xbar_mixed_read_uncache_mode = 1'b0;
`endif
   wire [31:0] cl1_selected_source0_write_addr = cl1_xbar_symbolic_write_addr;
   wire [31:0] cl1_selected_source0_read_addr = cl1_xbar_symbolic_read_addr;
   wire [31:0] cl1_selected_source1_write_addr = cl1_xbar_symbolic_write_addr;
   wire [31:0] cl1_selected_source1_read_addr = cl1_xbar_symbolic_read_addr;
`else
   wire [31:0] cl1_symbolic_shared_addr_q = CL1_SOURCE1_WRITE_ADDR;
   wire [2:0] cl1_xbar_symbolic_size = SIZE4B;
   wire [2:0] cl1_xbar_symbolic_write_size = cl1_xbar_symbolic_size;
   wire [2:0] cl1_xbar_symbolic_read_size = cl1_xbar_symbolic_size;
   wire cl1_xbar_mixed_write_uncache_mode = 1'b0;
   wire cl1_xbar_mixed_read_uncache_mode = 1'b0;
   wire [31:0] cl1_selected_source0_write_addr = CL1_SOURCE0_WRITE_ADDR;
   wire [31:0] cl1_selected_source0_read_addr = CL1_SOURCE0_READ_ADDR;
   wire [31:0] cl1_selected_source1_write_addr = CL1_SOURCE1_WRITE_ADDR;
   wire [31:0] cl1_selected_source1_read_addr = CL1_SOURCE1_READ_ADDR;
`endif

   always @(posedge clock) begin
      f_past_valid <= 1'b1;
      if (!f_past_valid)
         as_di_xbar_initial_reset: assume(reset);
      else
         as_di_xbar_reset_released: assume(!reset);

`ifdef CL1_XBAR_SYMBOLIC_ADDR_MODE
      if (!reset) begin
`ifdef CL1_XBAR_DI_SYMBOLIC_BYTE_ADDR_PROFILE
         assume(f_cl1_xbar_uncache_word_addr == $past(f_cl1_xbar_uncache_word_addr));
         assume(f_cl1_xbar_uncache_addr_offset == $past(f_cl1_xbar_uncache_addr_offset));
         assume(f_cl1_xbar_uncache_size_choice == $past(f_cl1_xbar_uncache_size_choice));
         assume(f_cl1_symbolic_shared_window == $past(f_cl1_symbolic_shared_window));
`ifdef CL1_XBAR_DI_MIXED_SINGLE_BURST
`ifdef CL1_XBAR_DI_MIXED_TRANSITION
         assume(f_cl1_xbar_mixed_write_uncache_mode ==
                $past(f_cl1_xbar_mixed_write_uncache_mode));
         assume(f_cl1_xbar_mixed_read_uncache_mode ==
                $past(f_cl1_xbar_mixed_read_uncache_mode));
         if (cl1_xbar_mixed_write_uncache_mode) begin
            assume(cl1_xbar_symbolic_write_addr[11:0] <= 12'hffc);
         end
         else begin
            assume(cl1_xbar_symbolic_write_addr[1:0] == 2'b00);
            assume(cl1_xbar_symbolic_write_addr[4:0] == 5'h0);
            assume(cl1_xbar_symbolic_write_addr[11:0] <= 12'hfe0);
         end
         if (cl1_xbar_mixed_read_uncache_mode) begin
            assume(cl1_xbar_symbolic_read_addr[11:0] <= 12'hffc);
         end
         else begin
            assume(cl1_xbar_symbolic_read_addr[1:0] == 2'b00);
            assume(cl1_xbar_symbolic_read_addr[4:0] == 5'h0);
            assume(cl1_xbar_symbolic_read_addr[11:0] <= 12'hfe0);
         end
`else
         assume(f_cl1_xbar_mixed_uncache_mode == $past(f_cl1_xbar_mixed_uncache_mode));
         if (cl1_xbar_mixed_uncache_mode)
            assume(cl1_symbolic_shared_addr_q[11:0] <= 12'hffc);
         else begin
            assume(cl1_symbolic_shared_addr_q[1:0] == 2'b00);
            assume(cl1_symbolic_shared_addr_q[4:0] == 5'h0);
            assume(cl1_symbolic_shared_addr_q[11:0] <= 12'hfe0);
         end
`endif
`else
         assume(cl1_symbolic_shared_addr_q[11:0] <= 12'hffc);
`endif
`else
         assume(f_cl1_symbolic_shared_window == $past(f_cl1_symbolic_shared_window));
         assume(cl1_symbolic_shared_addr_q[1:0] == 2'b00);
         assume(cl1_symbolic_shared_addr_q[4:0] == 5'h0);
         assume(cl1_symbolic_shared_addr_q[11:0] <= 12'hfe0);
`endif
      end
`endif
   end

`ifdef CL1_XBAR_DI_ENABLE
   reg [31:0] cl1_xbar_initial_tracked_word_q = 32'h0;
   reg [2:0]  cl1_xbar_tracked_beat_q = 3'h0;
   reg        cl1_xbar_tracked_loaded_q = 1'b0;

   always @(posedge clock) begin
      if (reset) begin
         cl1_xbar_initial_tracked_word_q <= 32'h0;
         cl1_xbar_tracked_beat_q <= 3'h0;
         cl1_xbar_tracked_loaded_q <= 1'b0;
      end
      else if (!cl1_xbar_tracked_loaded_q) begin
         cl1_xbar_initial_tracked_word_q <= f_cl1_xbar_initial_tracked_word;
`ifdef CL1_XBAR_DI_MIXED_TRANSITION
         cl1_xbar_tracked_beat_q <=
            (cl1_xbar_mixed_write_uncache_mode ||
             cl1_xbar_mixed_read_uncache_mode) ? 3'h0 :
            f_cl1_xbar_tracked_beat;
`elsif CL1_XBAR_DI_MIXED_SINGLE_BURST
         cl1_xbar_tracked_beat_q <= cl1_xbar_mixed_uncache_mode ?
            3'h0 : f_cl1_xbar_tracked_beat;
`elsif CL1_XBAR_DI_UNCACHE_SINGLE_BEAT
         cl1_xbar_tracked_beat_q <= 3'h0;
`else
         cl1_xbar_tracked_beat_q <= f_cl1_xbar_tracked_beat;
`endif
         cl1_xbar_tracked_loaded_q <= 1'b1;
      end
   end

   wire cl1_xbar_model_reset = reset || !cl1_xbar_tracked_loaded_q;
   wire [31:0] cl1_xbar_initial_tracked_word = cl1_xbar_initial_tracked_word_q;
   wire [2:0]  cl1_xbar_tracked_beat = cl1_xbar_tracked_beat_q;
`else
   wire cl1_xbar_model_reset = reset;
   wire [31:0] cl1_xbar_initial_tracked_word = 32'h0;
   wire [2:0]  cl1_xbar_tracked_beat = 3'h0;
`endif

   wire p0_done, p1_done;

   wire        p0_aw_ready, p0_aw_valid;
   wire [1:0]  p0_aw_id;
   wire [31:0] p0_aw_addr;
   wire [7:0]  p0_aw_len;
   wire [2:0]  p0_aw_size;
   wire [1:0]  p0_aw_burst;
   wire        p0_aw_lock;
   wire [3:0]  p0_aw_cache;
   wire [2:0]  p0_aw_prot;
   wire        p0_w_ready, p0_w_valid;
   wire [31:0] p0_w_data;
   wire [3:0]  p0_w_strb;
   wire        p0_w_last;
   wire        p0_b_valid, p0_b_ready;
   wire [1:0]  p0_b_id, p0_b_resp;
   wire        p0_ar_ready, p0_ar_valid;
   wire [1:0]  p0_ar_id;
   wire [31:0] p0_ar_addr;
   wire [7:0]  p0_ar_len;
   wire [2:0]  p0_ar_size;
   wire [1:0]  p0_ar_burst;
   wire        p0_ar_lock;
   wire [3:0]  p0_ar_cache;
   wire [2:0]  p0_ar_prot;
   wire        p0_r_valid, p0_r_ready;
   wire [1:0]  p0_r_id, p0_r_resp;
   wire [31:0] p0_r_data;
   wire        p0_r_last;

   wire        p1_aw_ready, p1_aw_valid;
   wire [1:0]  p1_aw_id;
   wire [31:0] p1_aw_addr;
   wire [7:0]  p1_aw_len;
   wire [2:0]  p1_aw_size;
   wire [1:0]  p1_aw_burst;
   wire        p1_aw_lock;
   wire [3:0]  p1_aw_cache;
   wire [2:0]  p1_aw_prot;
   wire        p1_w_ready, p1_w_valid;
   wire [31:0] p1_w_data;
   wire [3:0]  p1_w_strb;
   wire        p1_w_last;
   wire        p1_b_valid, p1_b_ready;
   wire [1:0]  p1_b_id, p1_b_resp;
   wire        p1_ar_ready, p1_ar_valid;
   wire [1:0]  p1_ar_id;
   wire [31:0] p1_ar_addr;
   wire [7:0]  p1_ar_len;
   wire [2:0]  p1_ar_size;
   wire [1:0]  p1_ar_burst;
   wire        p1_ar_lock;
   wire [3:0]  p1_ar_cache;
   wire [2:0]  p1_ar_prot;
   wire        p1_r_valid, p1_r_ready;
   wire [1:0]  p1_r_id, p1_r_resp;
   wire [31:0] p1_r_data;
   wire        p1_r_last;

   wire        p0_traffic_started;
   wire [1:0]  p0_phase;
   wire        p0_write_aw_done;
   wire [3:0]  p0_write_req_beat;
   wire [3:0]  p0_read_rsp_beat;
   wire [3:0]  p0_write_burst_len, p0_read_burst_len;
   wire [1:0]  p0_write_axi_burst, p0_read_axi_burst;
   wire [1:0]  p0_write_axi_id, p0_read_axi_id;
   wire [3:0]  p0_write_axi_cache, p0_read_axi_cache;
   wire [2:0]  p0_write_axi_prot, p0_read_axi_prot;
   wire [2:0]  p0_axi2cb_state;
   wire        p0_axi2cb_aw_pending;
   wire [31:0] p0_axi2cb_aw_addr;
   wire [7:0]  p0_axi2cb_aw_len;
   wire [7:0]  p0_axi2cb_write_index;
   wire [31:0] p0_axi2cb_req_addr;
   wire        p0_axi2cb_w_buf_valid;
   wire        p0_axi2cb_w_buf_last;
   wire        p0_axi2cb_ar_pending;
   wire [7:0]  p0_axi2cb_ar_len;
   wire        p0_axi2cb_rsp_last;

   wire        p1_traffic_started;
   wire [1:0]  p1_phase;
   wire        p1_write_aw_done;
   wire [3:0]  p1_write_req_beat;
   wire [3:0]  p1_read_rsp_beat;
   wire [3:0]  p1_write_burst_len, p1_read_burst_len;
   wire [1:0]  p1_write_axi_burst, p1_read_axi_burst;
   wire [1:0]  p1_write_axi_id, p1_read_axi_id;
   wire [3:0]  p1_write_axi_cache, p1_read_axi_cache;
   wire [2:0]  p1_write_axi_prot, p1_read_axi_prot;
   wire [2:0]  p1_axi2cb_state;
   wire        p1_axi2cb_aw_pending;
   wire [31:0] p1_axi2cb_aw_addr;
   wire [7:0]  p1_axi2cb_aw_len;
   wire [7:0]  p1_axi2cb_write_index;
   wire [31:0] p1_axi2cb_req_addr;
   wire        p1_axi2cb_w_buf_valid;
   wire        p1_axi2cb_w_buf_last;
   wire        p1_axi2cb_ar_pending;
   wire [7:0]  p1_axi2cb_ar_len;
   wire        p1_axi2cb_rsp_last;

`ifdef CL1_XBAR_SYMBOLIC_WDATA_SOURCE0_AFTER_WRITE_COVER
   reg cl1_xbar_s2_source1_write_done_q = 1'b0;
   always @(posedge clock) begin
      if (reset)
         cl1_xbar_s2_source1_write_done_q <= 1'b0;
      else if (p1_b_valid && p1_b_ready)
         cl1_xbar_s2_source1_write_done_q <= 1'b1;
   end
   wire cl1_source0_start = cl1_xbar_s2_source1_write_done_q;
`else
   wire cl1_source0_start = !reset;
`endif
   wire cl1_source1_start = !reset;

   amba_axi4_di_crossbar_axi_source_driver #(
      .ENABLE_WRITE(CL1_SOURCE0_ENABLE_WRITE),
      .WRITE_ADDR(CL1_SOURCE0_WRITE_ADDR),
      .READ_ADDR(CL1_SOURCE0_READ_ADDR),
      .WRITE_PROT(CL1_DATA_PROT),
      .READ_PROT(CL1_DATA_PROT)
   ) source0 (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .start(cl1_source0_start),
      .symbolic_addr(cl1_selected_source0_read_addr),
      .symbolic_write_addr(cl1_selected_source0_write_addr),
      .symbolic_read_addr(cl1_selected_source0_read_addr),
      .symbolic_size(cl1_xbar_symbolic_size),
      .symbolic_write_size(cl1_xbar_symbolic_write_size),
      .symbolic_read_size(cl1_xbar_symbolic_read_size),
      .symbolic_write_single_beat(cl1_xbar_mixed_write_uncache_mode),
      .symbolic_read_single_beat(cl1_xbar_mixed_read_uncache_mode),
      .done(p0_done),
      .aw_ready(p0_aw_ready),
      .aw_valid(p0_aw_valid),
      .aw_id(p0_aw_id),
      .aw_addr(p0_aw_addr),
      .aw_len(p0_aw_len),
      .aw_size(p0_aw_size),
      .aw_burst(p0_aw_burst),
      .aw_lock(p0_aw_lock),
      .aw_cache(p0_aw_cache),
      .aw_prot(p0_aw_prot),
      .w_ready(p0_w_ready),
      .w_valid(p0_w_valid),
      .w_data(p0_w_data),
      .w_strb(p0_w_strb),
      .w_last(p0_w_last),
      .b_valid(p0_b_valid),
      .b_id(p0_b_id),
      .b_resp(p0_b_resp),
      .b_ready(p0_b_ready),
      .ar_ready(p0_ar_ready),
      .ar_valid(p0_ar_valid),
      .ar_id(p0_ar_id),
      .ar_addr(p0_ar_addr),
      .ar_len(p0_ar_len),
      .ar_size(p0_ar_size),
      .ar_burst(p0_ar_burst),
      .ar_lock(p0_ar_lock),
      .ar_cache(p0_ar_cache),
      .ar_prot(p0_ar_prot),
      .r_valid(p0_r_valid),
      .r_id(p0_r_id),
      .r_data(p0_r_data),
      .r_resp(p0_r_resp),
      .r_last(p0_r_last),
      .r_ready(p0_r_ready),
      .traffic_started(p0_traffic_started),
      .phase(p0_phase),
      .write_aw_done(p0_write_aw_done),
      .write_req_beat(p0_write_req_beat),
      .read_rsp_beat(p0_read_rsp_beat),
      .write_burst_len(p0_write_burst_len),
      .read_burst_len(p0_read_burst_len),
      .write_axi_burst(p0_write_axi_burst),
      .read_axi_burst(p0_read_axi_burst),
      .write_axi_id(p0_write_axi_id),
      .read_axi_id(p0_read_axi_id),
      .write_axi_cache(p0_write_axi_cache),
      .read_axi_cache(p0_read_axi_cache),
      .write_axi_prot(p0_write_axi_prot),
      .read_axi_prot(p0_read_axi_prot)
   );

   amba_axi4_di_crossbar_axi_source_driver #(
      .ENABLE_WRITE(CL1_SOURCE1_ENABLE_WRITE),
      .WRITE_ADDR(CL1_SOURCE1_WRITE_ADDR),
      .READ_ADDR(CL1_SOURCE1_READ_ADDR),
      .WRITE_PROT(CL1_DATA_PROT),
      .READ_PROT(CL1_INSTR_PROT)
   ) source1 (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .start(cl1_source1_start),
      .symbolic_addr(cl1_selected_source1_write_addr),
      .symbolic_write_addr(cl1_selected_source1_write_addr),
      .symbolic_read_addr(cl1_selected_source1_read_addr),
      .symbolic_size(cl1_xbar_symbolic_size),
      .symbolic_write_size(cl1_xbar_symbolic_write_size),
      .symbolic_read_size(cl1_xbar_symbolic_read_size),
      .symbolic_write_single_beat(cl1_xbar_mixed_write_uncache_mode),
      .symbolic_read_single_beat(cl1_xbar_mixed_read_uncache_mode),
      .done(p1_done),
      .aw_ready(p1_aw_ready),
      .aw_valid(p1_aw_valid),
      .aw_id(p1_aw_id),
      .aw_addr(p1_aw_addr),
      .aw_len(p1_aw_len),
      .aw_size(p1_aw_size),
      .aw_burst(p1_aw_burst),
      .aw_lock(p1_aw_lock),
      .aw_cache(p1_aw_cache),
      .aw_prot(p1_aw_prot),
      .w_ready(p1_w_ready),
      .w_valid(p1_w_valid),
      .w_data(p1_w_data),
      .w_strb(p1_w_strb),
      .w_last(p1_w_last),
      .b_valid(p1_b_valid),
      .b_id(p1_b_id),
      .b_resp(p1_b_resp),
      .b_ready(p1_b_ready),
      .ar_ready(p1_ar_ready),
      .ar_valid(p1_ar_valid),
      .ar_id(p1_ar_id),
      .ar_addr(p1_ar_addr),
      .ar_len(p1_ar_len),
      .ar_size(p1_ar_size),
      .ar_burst(p1_ar_burst),
      .ar_lock(p1_ar_lock),
      .ar_cache(p1_ar_cache),
      .ar_prot(p1_ar_prot),
      .r_valid(p1_r_valid),
      .r_id(p1_r_id),
      .r_data(p1_r_data),
      .r_resp(p1_r_resp),
      .r_last(p1_r_last),
      .r_ready(p1_r_ready),
      .traffic_started(p1_traffic_started),
      .phase(p1_phase),
      .write_aw_done(p1_write_aw_done),
      .write_req_beat(p1_write_req_beat),
      .read_rsp_beat(p1_read_rsp_beat),
      .write_burst_len(p1_write_burst_len),
      .read_burst_len(p1_read_burst_len),
      .write_axi_burst(p1_write_axi_burst),
      .read_axi_burst(p1_read_axi_burst),
      .write_axi_id(p1_write_axi_id),
      .read_axi_id(p1_read_axi_id),
      .write_axi_cache(p1_write_axi_cache),
      .read_axi_cache(p1_read_axi_cache),
      .write_axi_prot(p1_write_axi_prot),
      .read_axi_prot(p1_read_axi_prot)
   );

   wire        cb0_req_ready, cb0_req_valid;
   wire [31:0] cb0_req_addr, cb0_req_data;
   wire        cb0_req_wen, cb0_req_burst;
   wire        cb0_req_instr;
   wire [3:0]  cb0_req_mask, cb0_req_len;
   wire [1:0]  cb0_req_size;
   wire        cb0_req_last;
   wire        cb0_rsp_ready, cb0_rsp_valid;
   wire [31:0] cb0_rsp_data;
   wire        cb0_rsp_last, cb0_rsp_err;

   wire        cb1_req_ready, cb1_req_valid;
   wire [31:0] cb1_req_addr, cb1_req_data;
   wire        cb1_req_wen, cb1_req_burst;
   wire        cb1_req_instr;
   wire [3:0]  cb1_req_mask, cb1_req_len;
   wire [1:0]  cb1_req_size;
   wire        cb1_req_last;
   wire        cb1_rsp_ready, cb1_rsp_valid;
   wire [31:0] cb1_rsp_data;
   wire        cb1_rsp_last, cb1_rsp_err;

   assign cb0_req_instr = 1'b0;
   assign cb1_req_instr = 1'b0;

   Axi4ToCacheBus axi4_to_cachebus0 (
      .clock(clock),
      .reset(reset),
      .io_in_aw_ready(p0_aw_ready),
      .io_in_aw_valid(p0_aw_valid),
      .io_in_aw_bits_awid(p0_aw_id),
      .io_in_aw_bits_awaddr(p0_aw_addr),
      .io_in_aw_bits_awlen(p0_aw_len),
      .io_in_aw_bits_awsize(p0_aw_size),
      .io_in_aw_bits_awburst(p0_aw_burst),
      .io_in_aw_bits_awlock(p0_aw_lock),
      .io_in_aw_bits_awcache(p0_aw_cache),
      .io_in_aw_bits_awprot(p0_aw_prot),
      .io_in_w_ready(p0_w_ready),
      .io_in_w_valid(p0_w_valid),
      .io_in_w_bits_wdata(p0_w_data),
      .io_in_w_bits_wstrb(p0_w_strb),
      .io_in_w_bits_wlast(p0_w_last),
      .io_in_b_ready(p0_b_ready),
      .io_in_b_valid(p0_b_valid),
      .io_in_b_bits_bid(p0_b_id),
      .io_in_b_bits_bresp(p0_b_resp),
      .io_in_ar_ready(p0_ar_ready),
      .io_in_ar_valid(p0_ar_valid),
      .io_in_ar_bits_arid(p0_ar_id),
      .io_in_ar_bits_araddr(p0_ar_addr),
      .io_in_ar_bits_arlen(p0_ar_len),
      .io_in_ar_bits_arsize(p0_ar_size),
      .io_in_ar_bits_arburst(p0_ar_burst),
      .io_in_ar_bits_arlock(p0_ar_lock),
      .io_in_ar_bits_arcache(p0_ar_cache),
      .io_in_ar_bits_arprot(p0_ar_prot),
      .io_in_r_ready(p0_r_ready),
      .io_in_r_valid(p0_r_valid),
      .io_in_r_bits_rid(p0_r_id),
      .io_in_r_bits_rdata(p0_r_data),
      .io_in_r_bits_rresp(p0_r_resp),
      .io_in_r_bits_rlast(p0_r_last),
      .io_out_req_ready(cb0_req_ready),
      .io_out_req_valid(cb0_req_valid),
      .io_out_req_bits_addr(cb0_req_addr),
      .io_out_req_bits_data(cb0_req_data),
      .io_out_req_bits_wen(cb0_req_wen),
      .io_out_req_bits_burst(cb0_req_burst),
      .io_out_req_bits_mask(cb0_req_mask),
      .io_out_req_bits_len(cb0_req_len),
      .io_out_req_bits_size(cb0_req_size),
      .io_out_req_bits_last(cb0_req_last),
      .io_out_rsp_ready(cb0_rsp_ready),
      .io_out_rsp_valid(cb0_rsp_valid),
      .io_out_rsp_bits_data(cb0_rsp_data),
      .io_out_rsp_bits_last(cb0_rsp_last),
      .io_out_rsp_bits_err(cb0_rsp_err),
      .proof_state(p0_axi2cb_state),
      .proof_aw_pending(p0_axi2cb_aw_pending),
      .proof_aw_addr(p0_axi2cb_aw_addr),
      .proof_aw_len(p0_axi2cb_aw_len),
      .proof_write_index(p0_axi2cb_write_index),
      .proof_req_addr(p0_axi2cb_req_addr),
      .proof_w_buf_valid(p0_axi2cb_w_buf_valid),
      .proof_w_buf_last(p0_axi2cb_w_buf_last),
      .proof_ar_pending(p0_axi2cb_ar_pending),
      .proof_ar_len(p0_axi2cb_ar_len),
      .proof_rsp_last(p0_axi2cb_rsp_last)
   );

   Axi4ToCacheBus axi4_to_cachebus1 (
      .clock(clock),
      .reset(reset),
      .io_in_aw_ready(p1_aw_ready),
      .io_in_aw_valid(p1_aw_valid),
      .io_in_aw_bits_awid(p1_aw_id),
      .io_in_aw_bits_awaddr(p1_aw_addr),
      .io_in_aw_bits_awlen(p1_aw_len),
      .io_in_aw_bits_awsize(p1_aw_size),
      .io_in_aw_bits_awburst(p1_aw_burst),
      .io_in_aw_bits_awlock(p1_aw_lock),
      .io_in_aw_bits_awcache(p1_aw_cache),
      .io_in_aw_bits_awprot(p1_aw_prot),
      .io_in_w_ready(p1_w_ready),
      .io_in_w_valid(p1_w_valid),
      .io_in_w_bits_wdata(p1_w_data),
      .io_in_w_bits_wstrb(p1_w_strb),
      .io_in_w_bits_wlast(p1_w_last),
      .io_in_b_ready(p1_b_ready),
      .io_in_b_valid(p1_b_valid),
      .io_in_b_bits_bid(p1_b_id),
      .io_in_b_bits_bresp(p1_b_resp),
      .io_in_ar_ready(p1_ar_ready),
      .io_in_ar_valid(p1_ar_valid),
      .io_in_ar_bits_arid(p1_ar_id),
      .io_in_ar_bits_araddr(p1_ar_addr),
      .io_in_ar_bits_arlen(p1_ar_len),
      .io_in_ar_bits_arsize(p1_ar_size),
      .io_in_ar_bits_arburst(p1_ar_burst),
      .io_in_ar_bits_arlock(p1_ar_lock),
      .io_in_ar_bits_arcache(p1_ar_cache),
      .io_in_ar_bits_arprot(p1_ar_prot),
      .io_in_r_ready(p1_r_ready),
      .io_in_r_valid(p1_r_valid),
      .io_in_r_bits_rid(p1_r_id),
      .io_in_r_bits_rdata(p1_r_data),
      .io_in_r_bits_rresp(p1_r_resp),
      .io_in_r_bits_rlast(p1_r_last),
      .io_out_req_ready(cb1_req_ready),
      .io_out_req_valid(cb1_req_valid),
      .io_out_req_bits_addr(cb1_req_addr),
      .io_out_req_bits_data(cb1_req_data),
      .io_out_req_bits_wen(cb1_req_wen),
      .io_out_req_bits_burst(cb1_req_burst),
      .io_out_req_bits_mask(cb1_req_mask),
      .io_out_req_bits_len(cb1_req_len),
      .io_out_req_bits_size(cb1_req_size),
      .io_out_req_bits_last(cb1_req_last),
      .io_out_rsp_ready(cb1_rsp_ready),
      .io_out_rsp_valid(cb1_rsp_valid),
      .io_out_rsp_bits_data(cb1_rsp_data),
      .io_out_rsp_bits_last(cb1_rsp_last),
      .io_out_rsp_bits_err(cb1_rsp_err),
      .proof_state(p1_axi2cb_state),
      .proof_aw_pending(p1_axi2cb_aw_pending),
      .proof_aw_addr(p1_axi2cb_aw_addr),
      .proof_aw_len(p1_axi2cb_aw_len),
      .proof_write_index(p1_axi2cb_write_index),
      .proof_req_addr(p1_axi2cb_req_addr),
      .proof_w_buf_valid(p1_axi2cb_w_buf_valid),
      .proof_w_buf_last(p1_axi2cb_w_buf_last),
      .proof_ar_pending(p1_axi2cb_ar_pending),
      .proof_ar_len(p1_axi2cb_ar_len),
      .proof_rsp_last(p1_axi2cb_rsp_last)
   );

   wire        dn_aw_valid, dn_aw_ready;
   wire [31:0] dn_aw_addr;
   wire [1:0]  dn_aw_id;
   wire [7:0]  dn_aw_len;
   wire [2:0]  dn_aw_size;
   wire [1:0]  dn_aw_burst;
   wire        dn_aw_lock;
   wire [3:0]  dn_aw_cache;
   wire [2:0]  dn_aw_prot;
   wire        dn_w_valid, dn_w_ready;
   wire [31:0] dn_w_data;
   wire [3:0]  dn_w_strb;
   wire        dn_w_last;
   wire        dn_b_valid, dn_b_ready;
   wire [1:0]  dn_b_resp, dn_b_id;
   wire        dn_ar_valid, dn_ar_ready;
   wire [31:0] dn_ar_addr;
   wire [1:0]  dn_ar_id;
   wire [7:0]  dn_ar_len;
   wire [2:0]  dn_ar_size;
   wire [1:0]  dn_ar_burst;
   wire        dn_ar_lock;
   wire [3:0]  dn_ar_cache;
   wire [2:0]  dn_ar_prot;
   wire        dn_r_valid, dn_r_ready;
   wire [1:0]  dn_r_resp, dn_r_id;
   wire [31:0] dn_r_data;
   wire        dn_r_last;
   wire [1:0]  crossbar_arbiter_state;
   wire        crossbar_arbiter_input_sel_0;
   wire        crossbar_arbiter_input_sel_1;
   wire [3:0]  crossbar_arbiter_req_len;
   wire [3:0]  crossbar_arbiter_req_mask;
   wire [1:0]  crossbar_arbiter_req_size;
   wire        crossbar_arbiter_req_wen;
   wire        crossbar_arbiter_req_valid;
   wire [3:0]  crossbar_buscut_buffer_len;
   wire [3:0]  crossbar_buscut_buffer_mask;
   wire [1:0]  crossbar_buscut_buffer_size;
   wire        crossbar_buscut_buffer_wen;
   wire        crossbar_buscut_buffer_last;
   wire        crossbar_buscut_buffer_valid;
   wire        crossbar_buscut_rsp_buffer_last;
   wire        crossbar_buscut_rsp_buffer_valid;
   wire [3:0]  crossbar_buscut_out_req_len;
   wire [3:0]  crossbar_buscut_out_req_mask;
   wire [1:0]  crossbar_buscut_out_req_size;
   wire        crossbar_buscut_out_req_wen;
   wire        crossbar_buscut_out_req_last;
   wire        crossbar_buscut_out_req_valid;
   wire        crossbar_buscut_out_req_ready;
   wire [3:0]  crossbar_bridge_reqbuf_len;
   wire [3:0]  crossbar_bridge_reqbuf_mask;
   wire [1:0]  crossbar_bridge_reqbuf_size;
   wire        crossbar_bridge_reqbuf_wen;
   wire        crossbar_bridge_reqbuf_valid;
   wire        crossbar_bridge_reqbuf_last;
   wire        crossbar_bridge_pend_aw;
   wire        crossbar_bridge_pend_w;
   wire        crossbar_bridge_pend_ar;
   wire        crossbar_bridge_write_burst_active;

   CrossbarCacheTop dut (
      .clock(clock),
      .reset(reset),
      .io_in_0_req_ready(cb0_req_ready),
      .io_in_0_req_valid(cb0_req_valid),
      .io_in_0_req_bits_addr(cb0_req_addr),
      .io_in_0_req_bits_data(cb0_req_data),
      .io_in_0_req_bits_wen(cb0_req_wen),
`ifdef CL1_XBAR_HAS_REQ_INSTR
      .io_in_0_req_bits_instr(cb0_req_instr),
`endif
      .io_in_0_req_bits_burst(cb0_req_burst),
      .io_in_0_req_bits_mask(cb0_req_mask),
      .io_in_0_req_bits_len(cb0_req_len),
      .io_in_0_req_bits_size(cb0_req_size),
      .io_in_0_req_bits_last(cb0_req_last),
      .io_in_0_rsp_ready(cb0_rsp_ready),
      .io_in_0_rsp_valid(cb0_rsp_valid),
      .io_in_0_rsp_bits_data(cb0_rsp_data),
      .io_in_0_rsp_bits_last(cb0_rsp_last),
      .io_in_0_rsp_bits_err(cb0_rsp_err),
      .io_in_1_req_ready(cb1_req_ready),
      .io_in_1_req_valid(cb1_req_valid),
      .io_in_1_req_bits_addr(cb1_req_addr),
      .io_in_1_req_bits_data(cb1_req_data),
      .io_in_1_req_bits_wen(cb1_req_wen),
`ifdef CL1_XBAR_HAS_REQ_INSTR
      .io_in_1_req_bits_instr(cb1_req_instr),
`endif
      .io_in_1_req_bits_burst(cb1_req_burst),
      .io_in_1_req_bits_mask(cb1_req_mask),
      .io_in_1_req_bits_len(cb1_req_len),
      .io_in_1_req_bits_size(cb1_req_size),
      .io_in_1_req_bits_last(cb1_req_last),
      .io_in_1_rsp_ready(cb1_rsp_ready),
      .io_in_1_rsp_valid(cb1_rsp_valid),
      .io_in_1_rsp_bits_data(cb1_rsp_data),
      .io_in_1_rsp_bits_last(cb1_rsp_last),
      .io_in_1_rsp_bits_err(cb1_rsp_err),
      .io_out_aw_ready(dn_aw_ready),
      .io_out_aw_valid(dn_aw_valid),
      .io_out_aw_bits_awaddr(dn_aw_addr),
      .io_out_aw_bits_awid(dn_aw_id),
      .io_out_aw_bits_awlen(dn_aw_len),
      .io_out_aw_bits_awsize(dn_aw_size),
      .io_out_aw_bits_awburst(dn_aw_burst),
      .io_out_aw_bits_awlock(dn_aw_lock),
      .io_out_aw_bits_awcache(dn_aw_cache),
      .io_out_aw_bits_awprot(dn_aw_prot),
      .io_out_w_ready(dn_w_ready),
      .io_out_w_valid(dn_w_valid),
      .io_out_w_bits_wdata(dn_w_data),
      .io_out_w_bits_wstrb(dn_w_strb),
      .io_out_w_bits_wlast(dn_w_last),
      .io_out_b_ready(dn_b_ready),
      .io_out_b_valid(dn_b_valid),
      .io_out_b_bits_bresp(dn_b_resp),
      .io_out_b_bits_bid(dn_b_id),
      .io_out_ar_ready(dn_ar_ready),
      .io_out_ar_valid(dn_ar_valid),
      .io_out_ar_bits_araddr(dn_ar_addr),
      .io_out_ar_bits_arid(dn_ar_id),
      .io_out_ar_bits_arlen(dn_ar_len),
      .io_out_ar_bits_arsize(dn_ar_size),
      .io_out_ar_bits_arburst(dn_ar_burst),
      .io_out_ar_bits_arlock(dn_ar_lock),
      .io_out_ar_bits_arcache(dn_ar_cache),
      .io_out_ar_bits_arprot(dn_ar_prot),
      .io_out_r_ready(dn_r_ready),
      .io_out_r_valid(dn_r_valid),
      .io_out_r_bits_rresp(dn_r_resp),
      .io_out_r_bits_rdata(dn_r_data),
      .io_out_r_bits_rlast(dn_r_last),
      .io_out_r_bits_rid(dn_r_id),
      .proof_arbiter_state(crossbar_arbiter_state),
      .proof_arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .proof_arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .proof_arbiter_req_len(crossbar_arbiter_req_len),
      .proof_arbiter_req_mask(crossbar_arbiter_req_mask),
      .proof_arbiter_req_size(crossbar_arbiter_req_size),
      .proof_arbiter_req_wen(crossbar_arbiter_req_wen),
      .proof_arbiter_req_valid(crossbar_arbiter_req_valid),
      .proof_buscut_buffer_len(crossbar_buscut_buffer_len),
      .proof_buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .proof_buscut_buffer_size(crossbar_buscut_buffer_size),
      .proof_buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .proof_buscut_buffer_last(crossbar_buscut_buffer_last),
      .proof_buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .proof_buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .proof_buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .proof_buscut_out_req_len(crossbar_buscut_out_req_len),
      .proof_buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .proof_buscut_out_req_size(crossbar_buscut_out_req_size),
      .proof_buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .proof_buscut_out_req_last(crossbar_buscut_out_req_last),
      .proof_buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .proof_buscut_out_req_ready(crossbar_buscut_out_req_ready),
      .proof_bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .proof_bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .proof_bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .proof_bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .proof_bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .proof_bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .proof_bridge_pend_aw(crossbar_bridge_pend_aw),
      .proof_bridge_pend_w(crossbar_bridge_pend_w),
      .proof_bridge_pend_ar(crossbar_bridge_pend_ar),
      .proof_bridge_write_burst_active(crossbar_bridge_write_burst_active)
   );

   wire dn_aw_fire = dn_aw_valid && dn_aw_ready;
   wire dn_w_fire = dn_w_valid && dn_w_ready;
   wire dn_b_fire = dn_b_valid && dn_b_ready;
   wire dn_ar_fire = dn_ar_valid && dn_ar_ready;
   wire dn_r_fire = dn_r_valid && dn_r_ready;
   wire cb0_req_fire = cb0_req_valid && cb0_req_ready;
   wire cb1_req_fire = cb1_req_valid && cb1_req_ready;
   wire cb0_rsp_fire = cb0_rsp_valid && cb0_rsp_ready;
   wire cb1_rsp_fire = cb1_rsp_valid && cb1_rsp_ready;
   wire cl1_xbar_cb_req_fire = cb0_req_fire || cb1_req_fire;
   wire cl1_xbar_cb_req_source1 = cb1_req_fire;
   wire cl1_xbar_cb_req_wen = cb1_req_fire ? cb1_req_wen : cb0_req_wen;
   wire cl1_xbar_cb_req_instr = cb1_req_fire ? cb1_req_instr : cb0_req_instr;
   wire cl1_xbar_cb_rsp_fire = cb0_rsp_fire || cb1_rsp_fire;
   wire cl1_xbar_cb_rsp_last = cb1_rsp_fire ? cb1_rsp_last : cb0_rsp_last;
   wire cl1_xbar_cb_read_req_fire =
      cl1_xbar_cb_req_fire && !cl1_xbar_cb_req_wen;
   wire [2:0] cl1_xbar_cb_read_req_prot =
      {cl1_xbar_cb_req_instr, 2'b00};

   logic cl1_xbar_rsp_active;
   logic cl1_xbar_rsp_source1;
   logic cl1_xbar_rsp_is_write;
   logic cl1_xbar_rsp_err_pending;
   logic cl1_xbar_rsp_expected_err;
   logic cl1_xbar_arprot_pending;
   logic [2:0] cl1_xbar_arprot_expected;

   wire cl1_xbar_dn_rsp_fire =
      cl1_xbar_rsp_active &&
      ((cl1_xbar_rsp_is_write && dn_b_fire) ||
       (!cl1_xbar_rsp_is_write && dn_r_fire));
   wire cl1_xbar_dn_rsp_err =
      cl1_xbar_rsp_is_write ? (dn_b_resp != OKAY) : (dn_r_resp != OKAY);
   wire cl1_xbar_rsp_expected_valid =
      cl1_xbar_rsp_err_pending || cl1_xbar_dn_rsp_fire;
   wire cl1_xbar_rsp_expected_match =
      cl1_xbar_rsp_err_pending ?
      cl1_xbar_rsp_expected_err : cl1_xbar_dn_rsp_err;
   wire cl1_xbar_arprot_expected_valid =
      cl1_xbar_arprot_pending || cl1_xbar_cb_read_req_fire;
   wire [2:0] cl1_xbar_arprot_expected_match =
      cl1_xbar_arprot_pending ?
      cl1_xbar_arprot_expected : cl1_xbar_cb_read_req_prot;

   always @(posedge clock) begin
      if (reset) begin
         cl1_xbar_rsp_active <= 1'b0;
         cl1_xbar_rsp_source1 <= 1'b0;
         cl1_xbar_rsp_is_write <= 1'b0;
         cl1_xbar_rsp_err_pending <= 1'b0;
         cl1_xbar_rsp_expected_err <= 1'b0;
         cl1_xbar_arprot_pending <= 1'b0;
         cl1_xbar_arprot_expected <= CL1_DATA_PROT;
      end
      else begin
         if (!cl1_xbar_rsp_active && cl1_xbar_cb_req_fire) begin
            cl1_xbar_rsp_active <= 1'b1;
            cl1_xbar_rsp_source1 <= cl1_xbar_cb_req_source1;
            cl1_xbar_rsp_is_write <= cl1_xbar_cb_req_wen;
         end
         if (cl1_xbar_cb_rsp_fire && cl1_xbar_cb_rsp_last) begin
            cl1_xbar_rsp_active <= 1'b0;
         end

         if (cl1_xbar_dn_rsp_fire &&
             !(cl1_xbar_cb_rsp_fire && !cl1_xbar_rsp_err_pending)) begin
            cl1_xbar_rsp_err_pending <= 1'b1;
            cl1_xbar_rsp_expected_err <= cl1_xbar_dn_rsp_err;
         end
         else if (cl1_xbar_cb_rsp_fire && cl1_xbar_rsp_err_pending) begin
            cl1_xbar_rsp_err_pending <= 1'b0;
         end

         if (cl1_xbar_cb_read_req_fire &&
             !(dn_ar_fire && !cl1_xbar_arprot_pending)) begin
            cl1_xbar_arprot_pending <= 1'b1;
            cl1_xbar_arprot_expected <= cl1_xbar_cb_read_req_prot;
         end
         else if (dn_ar_fire && cl1_xbar_arprot_pending) begin
            cl1_xbar_arprot_pending <= 1'b0;
         end
      end
   end

`ifdef AXI4_CL1_PROTOCOL_RESP_MAPPING_CHECKS
   ap_cl1_xbar_bresp_maps_to_cachebus0_err:
      assert property (@(posedge clock) disable iff (reset)
                       cb0_rsp_fire &&
                       cl1_xbar_rsp_active &&
                       !cl1_xbar_rsp_source1 &&
                       cl1_xbar_rsp_is_write |->
                       cl1_xbar_rsp_expected_valid &&
                       cb0_rsp_err == cl1_xbar_rsp_expected_match);

   ap_cl1_xbar_bresp_maps_to_cachebus1_err:
      assert property (@(posedge clock) disable iff (reset)
                       cb1_rsp_fire &&
                       cl1_xbar_rsp_active &&
                       cl1_xbar_rsp_source1 &&
                       cl1_xbar_rsp_is_write |->
                       cl1_xbar_rsp_expected_valid &&
                       cb1_rsp_err == cl1_xbar_rsp_expected_match);

   ap_cl1_xbar_rresp_maps_to_cachebus0_err:
      assert property (@(posedge clock) disable iff (reset)
                       cb0_rsp_fire &&
                       cl1_xbar_rsp_active &&
                       !cl1_xbar_rsp_source1 &&
                       !cl1_xbar_rsp_is_write |->
                       cl1_xbar_rsp_expected_valid &&
                       cb0_rsp_err == cl1_xbar_rsp_expected_match);

   ap_cl1_xbar_rresp_maps_to_cachebus1_err:
      assert property (@(posedge clock) disable iff (reset)
                       cb1_rsp_fire &&
                       cl1_xbar_rsp_active &&
                       cl1_xbar_rsp_source1 &&
                       !cl1_xbar_rsp_is_write |->
                       cl1_xbar_rsp_expected_valid &&
                       cb1_rsp_err == cl1_xbar_rsp_expected_match);
`endif

`ifdef AXI4_CL1_PROTOCOL_PROT_MAPPING_CHECKS
   ap_cl1_xbar_awprot_data_access:
      assert property (@(posedge clock) disable iff (reset)
                       dn_aw_fire |-> dn_aw_prot == CL1_DATA_PROT);

   ap_cl1_xbar_arprot_maps_to_cachebus_instr:
      assert property (@(posedge clock) disable iff (reset)
                       dn_ar_fire |->
                       cl1_xbar_arprot_expected_valid &&
                       dn_ar_prot == cl1_xbar_arprot_expected_match);

   ap_cl1_xbar_source0_arprot_data_access:
      assert property (@(posedge clock) disable iff (reset)
                       p0_ar_valid && p0_ar_ready |-> p0_ar_prot == CL1_DATA_PROT);

   ap_cl1_xbar_source1_arprot_instruction_access:
      assert property (@(posedge clock) disable iff (reset)
                       p1_ar_valid && p1_ar_ready |-> p1_ar_prot == CL1_INSTR_PROT);
`endif

   wire [31:0] cl1_xbar_memory_tracked_word;
   wire        cl1_xbar_mem_write_aw_seen;
   wire        cl1_xbar_mem_write_wlast_seen;
   wire [7:0]  cl1_xbar_mem_saved_aw_len;
   wire        cl1_xbar_mem_read_active;
   wire [7:0]  cl1_xbar_mem_read_beat_index;
   wire        cl1_xbar_mem_read_targets_tracked_slot;
   wire [31:0] cl1_xbar_mem_r_expected_word;
   wire [31:0] cl1_xbar_mem_read_current_profile_word;

`ifdef AXI4_DI_USE_ALEXFORENCICH_AXI_RAM
   amba_axi4_di_alexforencich_axi_ram_crossbar_memory downstream_memory (
`else
   amba_axi4_di_crossbar_downstream_golden_memory downstream_memory (
`endif
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .initial_tracked_word(cl1_xbar_initial_tracked_word),
      .tracked_beat(cl1_xbar_tracked_beat),
      .tracked_word(cl1_xbar_memory_tracked_word),
      .proof_write_aw_seen(cl1_xbar_mem_write_aw_seen),
      .proof_write_wlast_seen(cl1_xbar_mem_write_wlast_seen),
      .proof_saved_aw_len(cl1_xbar_mem_saved_aw_len),
      .proof_read_active(cl1_xbar_mem_read_active),
      .proof_read_beat_index(cl1_xbar_mem_read_beat_index),
      .proof_read_targets_tracked_slot(cl1_xbar_mem_read_targets_tracked_slot),
      .proof_r_expected_word(cl1_xbar_mem_r_expected_word),
      .proof_read_current_profile_word(cl1_xbar_mem_read_current_profile_word),
      .cfg_source0_write_addr(cl1_selected_source0_write_addr),
      .cfg_source0_read_addr(cl1_selected_source0_read_addr),
      .cfg_source1_write_addr(cl1_selected_source1_write_addr),
      .cfg_source1_read_addr(cl1_selected_source1_read_addr),
      .aw_valid(dn_aw_valid),
      .aw_ready(dn_aw_ready),
      .aw_addr(dn_aw_addr),
      .aw_id(dn_aw_id),
      .aw_len(dn_aw_len),
      .aw_size(dn_aw_size),
      .w_valid(dn_w_valid),
      .w_ready(dn_w_ready),
      .w_data(dn_w_data),
      .w_strb(dn_w_strb),
      .w_last(dn_w_last),
      .b_valid(dn_b_valid),
      .b_ready(dn_b_ready),
      .b_resp(dn_b_resp),
      .b_id(dn_b_id),
      .ar_valid(dn_ar_valid),
      .ar_ready(dn_ar_ready),
      .ar_addr(dn_ar_addr),
      .ar_id(dn_ar_id),
      .ar_len(dn_ar_len),
      .ar_size(dn_ar_size),
      .r_valid(dn_r_valid),
      .r_ready(dn_r_ready),
      .r_data(dn_r_data),
      .r_resp(dn_r_resp),
      .r_last(dn_r_last),
      .r_id(dn_r_id)
   );

   amba_axi4_di_crossbar_di_aligned_observer di_aligned_observer (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .initial_tracked_word(cl1_xbar_initial_tracked_word),
      .tracked_beat(cl1_xbar_tracked_beat),
      .tracked_base(cl1_selected_source1_write_addr),
      .tracked_read_base(cl1_selected_source1_read_addr),
      .memory_tracked_word(cl1_xbar_memory_tracked_word),
      .downstream_memory_read_active(cl1_xbar_mem_read_active),
      .downstream_memory_read_beat_index(cl1_xbar_mem_read_beat_index),
      .downstream_memory_read_targets_tracked_slot(cl1_xbar_mem_read_targets_tracked_slot),
      .downstream_memory_r_expected_word(cl1_xbar_mem_r_expected_word),
      .source_aw_valid(p1_aw_valid),
      .source_aw_ready(p1_aw_ready),
      .source_aw_addr(p1_aw_addr),
      .source_aw_len(p1_aw_len),
      .source_aw_size(p1_aw_size),
      .source_aw_burst(p1_aw_burst),
      .source_w_valid(p1_w_valid),
      .source_w_ready(p1_w_ready),
      .source_w_data(p1_w_data),
      .source_w_strb(p1_w_strb),
      .source_w_last(p1_w_last),
      .source_b_valid(p1_b_valid),
      .source_b_ready(p1_b_ready),
      .source_b_resp(p1_b_resp),
      .source_ar_valid(p1_ar_valid),
      .source_ar_ready(p1_ar_ready),
      .source_ar_addr(p1_ar_addr),
      .source_ar_len(p1_ar_len),
      .source_ar_size(p1_ar_size),
      .source_ar_burst(p1_ar_burst),
      .source_r_valid(p1_r_valid),
      .source_r_ready(p1_r_ready),
      .source_r_data(p1_r_data),
      .source_r_resp(p1_r_resp),
      .source_r_last(p1_r_last),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_addr(dn_aw_addr),
      .downstream_aw_len(dn_aw_len),
      .downstream_aw_size(dn_aw_size),
      .downstream_aw_burst(dn_aw_burst),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_data(dn_w_data),
      .downstream_w_strb(dn_w_strb),
      .downstream_w_last(dn_w_last),
      .downstream_b_valid(dn_b_valid),
      .downstream_b_ready(dn_b_ready),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_ar_addr(dn_ar_addr),
      .downstream_ar_len(dn_ar_len),
      .downstream_ar_size(dn_ar_size),
      .downstream_ar_burst(dn_ar_burst),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_data(dn_r_data),
      .downstream_r_resp(dn_r_resp),
      .downstream_r_last(dn_r_last),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_wen(cb1_req_wen),
      .source1_req_data(cb1_req_data),
      .source1_req_mask(cb1_req_mask),
      .source1_req_last(cb1_req_last),
      .source1_rsp_valid(cb1_rsp_valid),
      .source1_rsp_ready(cb1_rsp_ready),
      .source1_rsp_data(cb1_rsp_data),
      .source1_rsp_last(cb1_rsp_last)
   );

   amba_axi4_di_crossbar_symbolic_addr_observer symbolic_addr_observer (
      .clock(clock),
      .reset(reset),
      .cfg_shared_addr(cl1_symbolic_shared_addr_q),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_addr(cb0_req_addr),
      .source0_req_wen(cb0_req_wen),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_addr(cb1_req_addr),
      .source1_req_wen(cb1_req_wen),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_addr(dn_aw_addr),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_ar_addr(dn_ar_addr)
   );

   amba_axi4_di_crossbar_symbolic_wdata_observer symbolic_wdata_observer (
      .clock(clock),
      .reset(reset),
      .cfg_shared_addr(cl1_symbolic_shared_addr_q),
      .source1_w_valid(p1_w_valid),
      .source1_w_ready(p1_w_ready),
      .source1_w_data(p1_w_data),
      .source1_w_strb(p1_w_strb),
      .source1_w_last(p1_w_last),
      .source1_b_valid(p1_b_valid),
      .source1_b_ready(p1_b_ready),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_wen(cb0_req_wen),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_wen(cb1_req_wen),
      .source0_ar_valid(p0_ar_valid),
      .source0_ar_ready(p0_ar_ready),
      .source0_r_valid(p0_r_valid),
      .source0_r_ready(p0_r_ready),
      .source0_r_last(p0_r_last),
      .source1_ar_valid(p1_ar_valid),
      .source1_ar_ready(p1_ar_ready),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_last(p1_r_last),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_addr(dn_aw_addr),
      .downstream_aw_len(dn_aw_len),
      .downstream_aw_size(dn_aw_size),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_data(dn_w_data),
      .downstream_w_strb(dn_w_strb),
      .downstream_w_last(dn_w_last),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_last(dn_r_last)
   );

   amba_axi4_di_crossbar_symbolic_wstrb_observer symbolic_wstrb_observer (
      .clock(clock),
      .reset(reset),
      .source1_w_valid(p1_w_valid),
      .source1_w_ready(p1_w_ready),
      .source1_w_strb(p1_w_strb),
      .source1_w_last(p1_w_last),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_last(p1_r_last),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_strb(dn_w_strb),
      .downstream_w_last(dn_w_last)
   );

   amba_axi4_di_crossbar_owner_scoreboard #(
      .SOURCE0_WRITE_ADDR(CL1_SOURCE0_WRITE_ADDR),
      .SOURCE0_READ_ADDR(CL1_SOURCE0_READ_ADDR),
      .SOURCE1_WRITE_ADDR(CL1_SOURCE1_WRITE_ADDR),
      .SOURCE1_READ_ADDR(CL1_SOURCE1_READ_ADDR)
   ) owner_scoreboard (
      .clock(clock),
      .reset(reset),
      .cfg_source0_write_addr(cl1_selected_source0_write_addr),
      .cfg_source0_read_addr(cl1_selected_source0_read_addr),
      .cfg_source1_write_addr(cl1_selected_source1_write_addr),
      .cfg_source1_read_addr(cl1_selected_source1_read_addr),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_addr(cb0_req_addr),
      .source0_req_data(cb0_req_data),
      .source0_req_wen(cb0_req_wen),
      .source0_req_last(cb0_req_last),
      .source0_rsp_valid(cb0_rsp_valid),
      .source0_rsp_ready(cb0_rsp_ready),
      .source0_rsp_last(cb0_rsp_last),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_addr(cb1_req_addr),
      .source1_req_data(cb1_req_data),
      .source1_req_wen(cb1_req_wen),
      .source1_req_last(cb1_req_last),
      .source1_rsp_valid(cb1_rsp_valid),
      .source1_rsp_ready(cb1_rsp_ready),
      .source1_rsp_last(cb1_rsp_last),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_addr(dn_aw_addr),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_data(dn_w_data),
      .downstream_b_valid(dn_b_valid),
      .downstream_b_ready(dn_b_ready),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_ar_addr(dn_ar_addr),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_last(dn_r_last),
      .source0_b_valid(p0_b_valid),
      .source0_b_ready(p0_b_ready),
      .source0_r_valid(p0_r_valid),
      .source0_r_ready(p0_r_ready),
      .source0_r_last(p0_r_last),
      .source1_b_valid(p1_b_valid),
      .source1_b_ready(p1_b_ready),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_last(p1_r_last)
   );

   amba_axi4_di_crossbar_source_readback_observer source_readback_observer (
      .clock(clock),
      .reset(reset),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_wen(cb0_req_wen),
      .source0_rsp_valid(cb0_rsp_valid),
      .source0_rsp_ready(cb0_rsp_ready),
      .source0_rsp_data(cb0_rsp_data),
      .source0_rsp_last(cb0_rsp_last),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_wen(cb1_req_wen),
      .source1_rsp_valid(cb1_rsp_valid),
      .source1_rsp_ready(cb1_rsp_ready),
      .source1_rsp_data(cb1_rsp_data),
      .source1_rsp_last(cb1_rsp_last),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_data(dn_r_data),
      .downstream_r_last(dn_r_last),
      .source0_r_valid(p0_r_valid),
      .source0_r_ready(p0_r_ready),
      .source0_r_data(p0_r_data),
      .source0_r_last(p0_r_last),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_data(p1_r_data),
      .source1_r_last(p1_r_last)
   );

`ifdef CL1_XBAR_ENABLE_PROOF_IF
   amba_axi4_di_crossbar_arbitration_backpressure_observer arbitration_backpressure_observer (
      .clock(clock),
      .reset(reset),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_addr(cb0_req_addr),
      .source0_req_data(cb0_req_data),
      .source0_req_wen(cb0_req_wen),
      .source0_req_mask(cb0_req_mask),
      .source0_req_len(cb0_req_len),
      .source0_req_size(cb0_req_size),
      .source0_req_last(cb0_req_last),
      .source0_rsp_valid(cb0_rsp_valid),
      .source0_rsp_ready(cb0_rsp_ready),
      .source0_rsp_last(cb0_rsp_last),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_addr(cb1_req_addr),
      .source1_req_data(cb1_req_data),
      .source1_req_wen(cb1_req_wen),
      .source1_req_mask(cb1_req_mask),
      .source1_req_len(cb1_req_len),
      .source1_req_size(cb1_req_size),
      .source1_req_last(cb1_req_last),
      .source1_rsp_valid(cb1_rsp_valid),
      .source1_rsp_ready(cb1_rsp_ready),
      .source1_rsp_last(cb1_rsp_last),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_addr(dn_aw_addr),
      .downstream_aw_len(dn_aw_len),
      .downstream_aw_size(dn_aw_size),
      .downstream_aw_burst(dn_aw_burst),
      .downstream_aw_lock(dn_aw_lock),
      .downstream_aw_cache(dn_aw_cache),
      .downstream_aw_prot(dn_aw_prot),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_data(dn_w_data),
      .downstream_w_strb(dn_w_strb),
      .downstream_w_last(dn_w_last),
      .downstream_b_valid(dn_b_valid),
      .downstream_b_ready(dn_b_ready),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_ar_addr(dn_ar_addr),
      .downstream_ar_len(dn_ar_len),
      .downstream_ar_size(dn_ar_size),
      .downstream_ar_burst(dn_ar_burst),
      .downstream_ar_lock(dn_ar_lock),
      .downstream_ar_cache(dn_ar_cache),
      .downstream_ar_prot(dn_ar_prot),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_last(dn_r_last),
      .arbiter_req_valid(crossbar_arbiter_req_valid),
      .arbiter_req_wen(crossbar_arbiter_req_wen),
      .arbiter_req_mask(crossbar_arbiter_req_mask),
      .arbiter_req_len(crossbar_arbiter_req_len),
      .arbiter_req_size(crossbar_arbiter_req_size)
   );
`endif

   amba_axi4_di_crossbar_phase5_cover_observer phase5_cover_observer (
      .clock(clock),
      .reset(reset),
      .source0_req_valid(cb0_req_valid),
      .source0_req_ready(cb0_req_ready),
      .source0_req_wen(cb0_req_wen),
      .source0_rsp_valid(cb0_rsp_valid),
      .source0_rsp_ready(cb0_rsp_ready),
      .source0_rsp_last(cb0_rsp_last),
      .source1_req_valid(cb1_req_valid),
      .source1_req_ready(cb1_req_ready),
      .source1_req_wen(cb1_req_wen),
      .source1_rsp_valid(cb1_rsp_valid),
      .source1_rsp_ready(cb1_rsp_ready),
      .source1_rsp_last(cb1_rsp_last),
      .source0_b_valid(p0_b_valid),
      .source0_b_ready(p0_b_ready),
      .source0_r_valid(p0_r_valid),
      .source0_r_ready(p0_r_ready),
      .source0_r_last(p0_r_last),
      .source1_b_valid(p1_b_valid),
      .source1_b_ready(p1_b_ready),
      .source1_r_valid(p1_r_valid),
      .source1_r_ready(p1_r_ready),
      .source1_r_last(p1_r_last),
      .downstream_aw_valid(dn_aw_valid),
      .downstream_aw_ready(dn_aw_ready),
      .downstream_aw_len(dn_aw_len),
      .downstream_w_valid(dn_w_valid),
      .downstream_w_ready(dn_w_ready),
      .downstream_w_last(dn_w_last),
      .downstream_b_valid(dn_b_valid),
      .downstream_b_ready(dn_b_ready),
      .downstream_ar_valid(dn_ar_valid),
      .downstream_ar_ready(dn_ar_ready),
      .downstream_ar_len(dn_ar_len),
      .downstream_r_valid(dn_r_valid),
      .downstream_r_ready(dn_r_ready),
      .downstream_r_last(dn_r_last)
   );

`ifdef CL1_XBAR_DI_ENABLE
`ifdef CL1_XBAR_ENABLE_PROOF_IF
   amba_axi4_di_crossbar_cachebus_len_unreachable_invariants xbar_cachebus_len_invariants (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .xbar_if_source0_req_valid(cb0_req_valid),
      .xbar_if_source0_req_len(cb0_req_len),
      .xbar_if_source0_req_size(cb0_req_size),
      .xbar_if_source0_rsp_valid(cb0_rsp_valid),
      .xbar_if_source0_rsp_last(cb0_rsp_last),
      .xbar_if_source1_req_valid(cb1_req_valid),
      .xbar_if_source1_req_len(cb1_req_len),
      .xbar_if_source1_req_size(cb1_req_size),
      .xbar_if_source1_rsp_valid(cb1_rsp_valid),
      .xbar_if_source1_rsp_last(cb1_rsp_last),
      .xbar_if_arbiter_state(crossbar_arbiter_state),
      .xbar_if_arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .xbar_if_arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .xbar_if_arbiter_req_valid(crossbar_arbiter_req_valid),
      .xbar_if_arbiter_req_len(crossbar_arbiter_req_len),
      .xbar_if_arbiter_req_mask(crossbar_arbiter_req_mask),
      .xbar_if_arbiter_req_size(crossbar_arbiter_req_size),
      .xbar_if_arbiter_req_wen(crossbar_arbiter_req_wen),
      .xbar_if_buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .xbar_if_buscut_buffer_len(crossbar_buscut_buffer_len),
      .xbar_if_buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .xbar_if_buscut_buffer_size(crossbar_buscut_buffer_size),
      .xbar_if_buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .xbar_if_buscut_buffer_last(crossbar_buscut_buffer_last),
      .xbar_if_buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .xbar_if_buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .xbar_if_buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .xbar_if_buscut_out_req_len(crossbar_buscut_out_req_len),
      .xbar_if_buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .xbar_if_buscut_out_req_size(crossbar_buscut_out_req_size),
      .xbar_if_buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .xbar_if_buscut_out_req_last(crossbar_buscut_out_req_last),
      .xbar_if_buscut_out_req_ready(crossbar_buscut_out_req_ready),
      .xbar_if_bridge_write_burst_active(crossbar_bridge_write_burst_active),
      .xbar_if_bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .xbar_if_bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .xbar_if_bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .xbar_if_bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .xbar_if_bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .xbar_if_bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .xbar_if_bridge_pend_aw(crossbar_bridge_pend_aw),
      .xbar_if_bridge_pend_w(crossbar_bridge_pend_w),
      .xbar_if_bridge_pend_ar(crossbar_bridge_pend_ar),
      .memory_if_write_aw_seen(cl1_xbar_mem_write_aw_seen),
      .memory_if_write_wlast_seen(cl1_xbar_mem_write_wlast_seen),
      .memory_if_saved_aw_len(cl1_xbar_mem_saved_aw_len),
      .memory_if_read_active(cl1_xbar_mem_read_active),
      .memory_if_read_beat_index(cl1_xbar_mem_read_beat_index),
      .memory_if_read_targets_tracked_slot(cl1_xbar_mem_read_targets_tracked_slot),
      .memory_if_r_expected_word(cl1_xbar_mem_r_expected_word),
      .memory_if_read_current_profile_word(cl1_xbar_mem_read_current_profile_word)
   );
`endif

   amba_axi4_di_crossbar_axi4_to_cachebus_unreachable_invariants axi2cb0_invariants (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .source_if_phase(p0_phase),
      .source_if_write_aw_done(p0_write_aw_done),
      .source_if_write_req_beat(p0_write_req_beat),
      .source_if_read_rsp_beat(p0_read_rsp_beat),
      .source_if_write_burst_len(p0_write_burst_len),
      .source_if_read_burst_len(p0_read_burst_len),
      .source_if_aw_addr(p0_aw_addr),
      .source_if_aw_size(p0_aw_size),
      .source_if_w_valid(p0_w_valid),
      .source_if_w_ready(p0_w_ready),
      .source_if_w_last(p0_w_last),
      .source_if_r_valid(p0_r_valid),
      .source_if_r_ready(p0_r_ready),
      .source_if_r_last(p0_r_last),
      .bridge_if_state(p0_axi2cb_state),
      .bridge_if_aw_pending(p0_axi2cb_aw_pending),
      .bridge_if_aw_addr(p0_axi2cb_aw_addr),
      .bridge_if_aw_len(p0_axi2cb_aw_len),
      .bridge_if_write_index(p0_axi2cb_write_index),
      .bridge_if_req_addr(p0_axi2cb_req_addr),
      .bridge_if_w_buf_valid(p0_axi2cb_w_buf_valid),
      .bridge_if_w_buf_last(p0_axi2cb_w_buf_last),
      .bridge_if_ar_pending(p0_axi2cb_ar_pending),
      .bridge_if_ar_len(p0_axi2cb_ar_len),
      .bridge_if_rsp_last(p0_axi2cb_rsp_last),
      .bridge_if_in_rsp_valid(cb0_rsp_valid),
      .bridge_if_in_rsp_last(cb0_rsp_last)
   );

   amba_axi4_di_crossbar_axi4_to_cachebus_unreachable_invariants axi2cb1_invariants (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .source_if_phase(p1_phase),
      .source_if_write_aw_done(p1_write_aw_done),
      .source_if_write_req_beat(p1_write_req_beat),
      .source_if_read_rsp_beat(p1_read_rsp_beat),
      .source_if_write_burst_len(p1_write_burst_len),
      .source_if_read_burst_len(p1_read_burst_len),
      .source_if_aw_addr(p1_aw_addr),
      .source_if_aw_size(p1_aw_size),
      .source_if_w_valid(p1_w_valid),
      .source_if_w_ready(p1_w_ready),
      .source_if_w_last(p1_w_last),
      .source_if_r_valid(p1_r_valid),
      .source_if_r_ready(p1_r_ready),
      .source_if_r_last(p1_r_last),
      .bridge_if_state(p1_axi2cb_state),
      .bridge_if_aw_pending(p1_axi2cb_aw_pending),
      .bridge_if_aw_addr(p1_axi2cb_aw_addr),
      .bridge_if_aw_len(p1_axi2cb_aw_len),
      .bridge_if_write_index(p1_axi2cb_write_index),
      .bridge_if_req_addr(p1_axi2cb_req_addr),
      .bridge_if_w_buf_valid(p1_axi2cb_w_buf_valid),
      .bridge_if_w_buf_last(p1_axi2cb_w_buf_last),
      .bridge_if_ar_pending(p1_axi2cb_ar_pending),
      .bridge_if_ar_len(p1_axi2cb_ar_len),
      .bridge_if_rsp_last(p1_axi2cb_rsp_last),
      .bridge_if_in_rsp_valid(cb1_rsp_valid),
      .bridge_if_in_rsp_last(cb1_rsp_last)
   );

`ifdef CL1_XBAR_ENABLE_PROOF_IF
   amba_axi4_di_crossbar_write_pipeline_unreachable_invariants xbar_write_pipeline_invariants (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .source0_if_phase(p0_phase),
      .source0_if_write_aw_done(p0_write_aw_done),
      .source0_if_write_req_beat(p0_write_req_beat),
      .source0_if_read_rsp_beat(p0_read_rsp_beat),
      .source0_if_write_burst_len(p0_write_burst_len),
      .source0_if_read_burst_len(p0_read_burst_len),
      .source0_if_aw_addr(p0_aw_addr),
      .source0_if_aw_size(p0_aw_size),
      .source0_if_w_valid(p0_w_valid),
      .source0_if_w_ready(p0_w_ready),
      .source0_if_w_last(p0_w_last),
      .source0_if_r_valid(p0_r_valid),
      .source0_if_r_ready(p0_r_ready),
      .source0_if_r_last(p0_r_last),
      .source1_if_phase(p1_phase),
      .source1_if_write_aw_done(p1_write_aw_done),
      .source1_if_write_req_beat(p1_write_req_beat),
      .source1_if_read_rsp_beat(p1_read_rsp_beat),
      .source1_if_write_burst_len(p1_write_burst_len),
      .source1_if_read_burst_len(p1_read_burst_len),
      .source1_if_aw_addr(p1_aw_addr),
      .source1_if_aw_size(p1_aw_size),
      .source1_if_w_valid(p1_w_valid),
      .source1_if_w_ready(p1_w_ready),
      .source1_if_w_last(p1_w_last),
      .source1_if_r_valid(p1_r_valid),
      .source1_if_r_ready(p1_r_ready),
      .source1_if_r_last(p1_r_last),
      .source1_axi2cb_if_state(p1_axi2cb_state),
      .source1_axi2cb_if_aw_pending(p1_axi2cb_aw_pending),
      .source1_axi2cb_if_aw_addr(p1_axi2cb_aw_addr),
      .source1_axi2cb_if_aw_len(p1_axi2cb_aw_len),
      .source1_axi2cb_if_write_index(p1_axi2cb_write_index),
      .source1_axi2cb_if_req_addr(p1_axi2cb_req_addr),
      .source1_axi2cb_if_w_buf_valid(p1_axi2cb_w_buf_valid),
      .source1_axi2cb_if_w_buf_last(p1_axi2cb_w_buf_last),
      .source1_axi2cb_if_ar_pending(p1_axi2cb_ar_pending),
      .source1_axi2cb_if_ar_len(p1_axi2cb_ar_len),
      .source1_axi2cb_if_rsp_last(p1_axi2cb_rsp_last),
      .source1_axi2cb_if_in_rsp_valid(cb1_rsp_valid),
      .source1_axi2cb_if_in_rsp_last(cb1_rsp_last),
      .xbar_if_source0_req_valid(cb0_req_valid),
      .xbar_if_source0_req_len(cb0_req_len),
      .xbar_if_source0_req_size(cb0_req_size),
      .xbar_if_source0_rsp_valid(cb0_rsp_valid),
      .xbar_if_source0_rsp_last(cb0_rsp_last),
      .xbar_if_source1_req_valid(cb1_req_valid),
      .xbar_if_source1_req_len(cb1_req_len),
      .xbar_if_source1_req_size(cb1_req_size),
      .xbar_if_source1_rsp_valid(cb1_rsp_valid),
      .xbar_if_source1_rsp_last(cb1_rsp_last),
      .xbar_if_arbiter_state(crossbar_arbiter_state),
      .xbar_if_arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .xbar_if_arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .xbar_if_arbiter_req_valid(crossbar_arbiter_req_valid),
      .xbar_if_arbiter_req_len(crossbar_arbiter_req_len),
      .xbar_if_arbiter_req_mask(crossbar_arbiter_req_mask),
      .xbar_if_arbiter_req_size(crossbar_arbiter_req_size),
      .xbar_if_arbiter_req_wen(crossbar_arbiter_req_wen),
      .xbar_if_buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .xbar_if_buscut_buffer_len(crossbar_buscut_buffer_len),
      .xbar_if_buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .xbar_if_buscut_buffer_size(crossbar_buscut_buffer_size),
      .xbar_if_buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .xbar_if_buscut_buffer_last(crossbar_buscut_buffer_last),
      .xbar_if_buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .xbar_if_buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .xbar_if_buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .xbar_if_buscut_out_req_len(crossbar_buscut_out_req_len),
      .xbar_if_buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .xbar_if_buscut_out_req_size(crossbar_buscut_out_req_size),
      .xbar_if_buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .xbar_if_buscut_out_req_last(crossbar_buscut_out_req_last),
      .xbar_if_buscut_out_req_ready(crossbar_buscut_out_req_ready),
      .xbar_if_bridge_write_burst_active(crossbar_bridge_write_burst_active),
      .xbar_if_bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .xbar_if_bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .xbar_if_bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .xbar_if_bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .xbar_if_bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .xbar_if_bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .xbar_if_bridge_pend_aw(crossbar_bridge_pend_aw),
      .xbar_if_bridge_pend_w(crossbar_bridge_pend_w),
      .xbar_if_bridge_pend_ar(crossbar_bridge_pend_ar),
      .memory_if_write_aw_seen(cl1_xbar_mem_write_aw_seen),
      .memory_if_write_wlast_seen(cl1_xbar_mem_write_wlast_seen),
      .memory_if_saved_aw_len(cl1_xbar_mem_saved_aw_len),
      .memory_if_read_active(cl1_xbar_mem_read_active),
      .memory_if_read_beat_index(cl1_xbar_mem_read_beat_index),
      .memory_if_read_targets_tracked_slot(cl1_xbar_mem_read_targets_tracked_slot),
      .memory_if_r_expected_word(cl1_xbar_mem_r_expected_word),
      .memory_if_read_current_profile_word(cl1_xbar_mem_read_current_profile_word),
      .dn_w_valid(dn_w_valid),
      .dn_w_ready(dn_w_ready),
      .dn_w_last(dn_w_last),
      .dn_b_fire(dn_b_fire)
   );

   amba_axi4_di_crossbar_read_pipeline_unreachable_invariants xbar_read_pipeline_invariants (
      .clock(clock),
      .reset(cl1_xbar_model_reset),
      .source0_if_phase(p0_phase),
      .source0_if_write_aw_done(p0_write_aw_done),
      .source0_if_write_req_beat(p0_write_req_beat),
      .source0_if_read_rsp_beat(p0_read_rsp_beat),
      .source0_if_write_burst_len(p0_write_burst_len),
      .source0_if_read_burst_len(p0_read_burst_len),
      .source0_if_aw_addr(p0_aw_addr),
      .source0_if_aw_size(p0_aw_size),
      .source0_if_w_valid(p0_w_valid),
      .source0_if_w_ready(p0_w_ready),
      .source0_if_w_last(p0_w_last),
      .source0_if_r_valid(p0_r_valid),
      .source0_if_r_ready(p0_r_ready),
      .source0_if_r_last(p0_r_last),
      .source1_if_phase(p1_phase),
      .source1_if_write_aw_done(p1_write_aw_done),
      .source1_if_write_req_beat(p1_write_req_beat),
      .source1_if_read_rsp_beat(p1_read_rsp_beat),
      .source1_if_write_burst_len(p1_write_burst_len),
      .source1_if_read_burst_len(p1_read_burst_len),
      .source1_if_aw_addr(p1_aw_addr),
      .source1_if_aw_size(p1_aw_size),
      .source1_if_w_valid(p1_w_valid),
      .source1_if_w_ready(p1_w_ready),
      .source1_if_w_last(p1_w_last),
      .source1_if_r_valid(p1_r_valid),
      .source1_if_r_ready(p1_r_ready),
      .source1_if_r_last(p1_r_last),
      .xbar_if_source0_req_valid(cb0_req_valid),
      .xbar_if_source0_req_len(cb0_req_len),
      .xbar_if_source0_req_size(cb0_req_size),
      .xbar_if_source0_rsp_valid(cb0_rsp_valid),
      .xbar_if_source0_rsp_last(cb0_rsp_last),
      .xbar_if_source1_req_valid(cb1_req_valid),
      .xbar_if_source1_req_len(cb1_req_len),
      .xbar_if_source1_req_size(cb1_req_size),
      .xbar_if_source1_rsp_valid(cb1_rsp_valid),
      .xbar_if_source1_rsp_last(cb1_rsp_last),
      .xbar_if_arbiter_state(crossbar_arbiter_state),
      .xbar_if_arbiter_input_sel_0(crossbar_arbiter_input_sel_0),
      .xbar_if_arbiter_input_sel_1(crossbar_arbiter_input_sel_1),
      .xbar_if_arbiter_req_valid(crossbar_arbiter_req_valid),
      .xbar_if_arbiter_req_len(crossbar_arbiter_req_len),
      .xbar_if_arbiter_req_mask(crossbar_arbiter_req_mask),
      .xbar_if_arbiter_req_size(crossbar_arbiter_req_size),
      .xbar_if_arbiter_req_wen(crossbar_arbiter_req_wen),
      .xbar_if_buscut_buffer_valid(crossbar_buscut_buffer_valid),
      .xbar_if_buscut_buffer_len(crossbar_buscut_buffer_len),
      .xbar_if_buscut_buffer_mask(crossbar_buscut_buffer_mask),
      .xbar_if_buscut_buffer_size(crossbar_buscut_buffer_size),
      .xbar_if_buscut_buffer_wen(crossbar_buscut_buffer_wen),
      .xbar_if_buscut_buffer_last(crossbar_buscut_buffer_last),
      .xbar_if_buscut_rsp_buffer_valid(crossbar_buscut_rsp_buffer_valid),
      .xbar_if_buscut_rsp_buffer_last(crossbar_buscut_rsp_buffer_last),
      .xbar_if_buscut_out_req_valid(crossbar_buscut_out_req_valid),
      .xbar_if_buscut_out_req_len(crossbar_buscut_out_req_len),
      .xbar_if_buscut_out_req_mask(crossbar_buscut_out_req_mask),
      .xbar_if_buscut_out_req_size(crossbar_buscut_out_req_size),
      .xbar_if_buscut_out_req_wen(crossbar_buscut_out_req_wen),
      .xbar_if_buscut_out_req_last(crossbar_buscut_out_req_last),
      .xbar_if_buscut_out_req_ready(crossbar_buscut_out_req_ready),
      .xbar_if_bridge_write_burst_active(crossbar_bridge_write_burst_active),
      .xbar_if_bridge_reqbuf_valid(crossbar_bridge_reqbuf_valid),
      .xbar_if_bridge_reqbuf_len(crossbar_bridge_reqbuf_len),
      .xbar_if_bridge_reqbuf_mask(crossbar_bridge_reqbuf_mask),
      .xbar_if_bridge_reqbuf_size(crossbar_bridge_reqbuf_size),
      .xbar_if_bridge_reqbuf_wen(crossbar_bridge_reqbuf_wen),
      .xbar_if_bridge_reqbuf_last(crossbar_bridge_reqbuf_last),
      .xbar_if_bridge_pend_aw(crossbar_bridge_pend_aw),
      .xbar_if_bridge_pend_w(crossbar_bridge_pend_w),
      .xbar_if_bridge_pend_ar(crossbar_bridge_pend_ar),
      .memory_if_write_aw_seen(cl1_xbar_mem_write_aw_seen),
      .memory_if_write_wlast_seen(cl1_xbar_mem_write_wlast_seen),
      .memory_if_saved_aw_len(cl1_xbar_mem_saved_aw_len),
      .memory_if_read_active(cl1_xbar_mem_read_active),
      .memory_if_read_beat_index(cl1_xbar_mem_read_beat_index),
      .memory_if_read_targets_tracked_slot(cl1_xbar_mem_read_targets_tracked_slot),
      .memory_if_r_expected_word(cl1_xbar_mem_r_expected_word),
      .memory_if_read_current_profile_word(cl1_xbar_mem_read_current_profile_word),
      .dn_r_valid(dn_r_valid),
      .dn_r_ready(dn_r_ready),
      .dn_r_last(dn_r_last)
   );
`endif
`endif

`define CL1_OSS_DI_CHECKER_PARAMS(AGENT) \
      .ID_WIDTH(CL1_ID_WIDTH), \
      .ADDRESS_WIDTH(CL1_ADDRESS_WIDTH), \
      .DATA_WIDTH(CL1_DATA_WIDTH), \
      .AWUSER_WIDTH(CL1_USER_WIDTH), \
      .WUSER_WIDTH(CL1_USER_WIDTH), \
      .BUSER_WIDTH(CL1_USER_WIDTH), \
      .ARUSER_WIDTH(CL1_USER_WIDTH), \
      .RUSER_WIDTH(CL1_USER_WIDTH), \
      .MAX_WR_BURSTS(CL1_MAX_BURSTS), \
      .MAX_RD_BURSTS(CL1_MAX_BURSTS), \
      .MAX_WR_LENGTH(CL1_MAX_LENGTH), \
      .MAX_RD_LENGTH(CL1_MAX_LENGTH), \
      .MAXWAIT(8), \
      .VERIFY_AGENT_TYPE(AGENT), \
      .PROTOCOL_TYPE(AXI4FULL), \
      .INTERFACE_REQS(1'b1), \
      .ENABLE_COVER(1'b1), \
      .ENABLE_XPROP(1'b0), \
      .ARM_RECOMMENDED(1'b1), \
      .CHECK_PARAMETERS(1'b1), \
      .OPTIONAL_WSTRB(1'b1), \
      .FULL_WR_STRB(1'b0), \
      .OPTIONAL_RESET(1'b1), \
      .EXCLUSIVE_ACCESS(1'b0), \
      .OPTIONAL_LP(1'b0)

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_DI_CHECKER_PARAMS(DESTINATION)
   )
   input0_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(p0_aw_id), .AWADDR(p0_aw_addr), .AWLEN(p0_aw_len), .AWSIZE(p0_aw_size),
      .AWBURST(p0_aw_burst), .AWLOCK(p0_aw_lock), .AWCACHE(p0_aw_cache),
      .AWPROT(p0_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(p0_aw_valid), .AWREADY(p0_aw_ready),
      .WDATA(p0_w_data), .WSTRB(p0_w_strb), .WLAST(p0_w_last), .WUSER(1'b0),
      .WVALID(p0_w_valid), .WREADY(p0_w_ready),
      .BID(p0_b_id), .BRESP(p0_b_resp), .BUSER(1'b0), .BVALID(p0_b_valid), .BREADY(p0_b_ready),
      .ARID(p0_ar_id), .ARADDR(p0_ar_addr), .ARLEN(p0_ar_len), .ARSIZE(p0_ar_size),
      .ARBURST(p0_ar_burst), .ARLOCK(p0_ar_lock), .ARCACHE(p0_ar_cache),
      .ARPROT(p0_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(p0_ar_valid), .ARREADY(p0_ar_ready),
      .RID(p0_r_id), .RDATA(p0_r_data), .RRESP(p0_r_resp), .RLAST(p0_r_last),
      .RUSER(1'b0), .RVALID(p0_r_valid), .RREADY(p0_r_ready),
      .CSYSREQ(1'b1), .CSYSACK(1'b1), .CACTIVE(1'b1)
   );

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_DI_CHECKER_PARAMS(DESTINATION)
   )
   input1_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(p1_aw_id), .AWADDR(p1_aw_addr), .AWLEN(p1_aw_len), .AWSIZE(p1_aw_size),
      .AWBURST(p1_aw_burst), .AWLOCK(p1_aw_lock), .AWCACHE(p1_aw_cache),
      .AWPROT(p1_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(p1_aw_valid), .AWREADY(p1_aw_ready),
      .WDATA(p1_w_data), .WSTRB(p1_w_strb), .WLAST(p1_w_last), .WUSER(1'b0),
      .WVALID(p1_w_valid), .WREADY(p1_w_ready),
      .BID(p1_b_id), .BRESP(p1_b_resp), .BUSER(1'b0), .BVALID(p1_b_valid), .BREADY(p1_b_ready),
      .ARID(p1_ar_id), .ARADDR(p1_ar_addr), .ARLEN(p1_ar_len), .ARSIZE(p1_ar_size),
      .ARBURST(p1_ar_burst), .ARLOCK(p1_ar_lock), .ARCACHE(p1_ar_cache),
      .ARPROT(p1_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(p1_ar_valid), .ARREADY(p1_ar_ready),
      .RID(p1_r_id), .RDATA(p1_r_data), .RRESP(p1_r_resp), .RLAST(p1_r_last),
      .RUSER(1'b0), .RVALID(p1_r_valid), .RREADY(p1_r_ready),
      .CSYSREQ(1'b1), .CSYSACK(1'b1), .CACTIVE(1'b1)
   );

   amba_axi4_protocol_checker_oss #(
      `CL1_OSS_DI_CHECKER_PARAMS(SOURCE)
   )
   output_axi_checker (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(dn_aw_id), .AWADDR(dn_aw_addr), .AWLEN(dn_aw_len), .AWSIZE(dn_aw_size),
      .AWBURST(dn_aw_burst), .AWLOCK(dn_aw_lock), .AWCACHE(dn_aw_cache),
      .AWPROT(dn_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(dn_aw_valid), .AWREADY(dn_aw_ready),
      .WDATA(dn_w_data), .WSTRB(dn_w_strb), .WLAST(dn_w_last), .WUSER(1'b0),
      .WVALID(dn_w_valid), .WREADY(dn_w_ready),
      .BID(dn_b_id), .BRESP(dn_b_resp), .BUSER(1'b0), .BVALID(dn_b_valid), .BREADY(dn_b_ready),
      .ARID(dn_ar_id), .ARADDR(dn_ar_addr), .ARLEN(dn_ar_len), .ARSIZE(dn_ar_size),
      .ARBURST(dn_ar_burst), .ARLOCK(dn_ar_lock), .ARCACHE(dn_ar_cache),
      .ARPROT(dn_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(dn_ar_valid), .ARREADY(dn_ar_ready),
      .RID(dn_r_id), .RDATA(dn_r_data), .RRESP(dn_r_resp), .RLAST(dn_r_last),
      .RUSER(1'b0), .RVALID(dn_r_valid), .RREADY(dn_r_ready),
      .CSYSREQ(1'b1), .CSYSACK(1'b1), .CACTIVE(1'b1)
   );

`undef CL1_OSS_DI_CHECKER_PARAMS

   amba_axi4_di_crossbar_smoke_covers smoke_covers (
      .clock(clock),
      .reset(reset),
      .source0_aw_valid(p0_aw_valid),
      .source0_aw_ready(p0_aw_ready),
      .source1_aw_valid(p1_aw_valid),
      .source1_aw_ready(p1_aw_ready),
      .source0_done(p0_done),
      .source1_done(p1_done),
      .downstream_aw_fire(dn_aw_fire),
      .downstream_ar_fire(dn_ar_fire),
      .downstream_r_fire(dn_r_fire),
      .downstream_r_last(dn_r_last)
   );
endmodule

`default_nettype wire
