`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_crossbar_downstream_golden_memory (
   input wire        clock,
   input wire        reset,
   input wire [31:0] initial_tracked_word,
   input wire [2:0]  tracked_beat,
   output wire [31:0] tracked_word,
   output wire       proof_write_aw_seen,
   output wire       proof_write_wlast_seen,
   output wire [7:0] proof_saved_aw_len,
   output wire       proof_read_active,
   output wire [7:0] proof_read_beat_index,
   output wire       proof_read_targets_tracked_slot,
   output wire [31:0] proof_r_expected_word,
   output wire [31:0] proof_read_current_profile_word,
   input wire [31:0] cfg_source0_write_addr,
   input wire [31:0] cfg_source0_read_addr,
   input wire [31:0] cfg_source1_write_addr,
   input wire [31:0] cfg_source1_read_addr,

   input wire        aw_valid,
   output wire       aw_ready,
   input wire [31:0] aw_addr,
   input wire [1:0]  aw_id,
   input wire [7:0]  aw_len,
   input wire [2:0]  aw_size,

   input wire        w_valid,
   output wire       w_ready,
   input wire [31:0] w_data,
   input wire [3:0]  w_strb,
   input wire        w_last,

   output wire       b_valid,
   input wire        b_ready,
   output wire [1:0] b_resp,
   output wire [1:0] b_id,

   input wire        ar_valid,
   output wire       ar_ready,
   input wire [31:0] ar_addr,
   input wire [1:0]  ar_id,
   input wire [7:0]  ar_len,
   input wire [2:0]  ar_size,

   output wire       r_valid,
   input wire        r_ready,
   output wire [31:0] r_data,
   output wire [1:0] r_resp,
   output wire       r_last,
   output wire [1:0] r_id
);

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BACKPRESSURE
`define AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
`define AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
`define AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RESPONSE_DELAY
`define AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
`define AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
`define AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
`define AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
`define AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
`define AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
`define AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`endif

`ifdef AXI4_DI_CROSSBAR_ANY_DOWNSTREAM_BACKPRESSURE
`ifndef AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL
`define AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL 2
`endif
`endif

   localparam logic [1:0] RESP_OKAY = 2'b00;
   localparam logic [1:0] RESP_SLVERR = 2'b10;

   reg        aw_ready_q = 1'b0;
   reg        w_ready_q = 1'b0;
   reg        ar_ready_q = 1'b0;
   reg        b_valid_q = 1'b0;
   reg [1:0]  b_id_q = 2'b00;
   reg        r_valid_q = 1'b0;
   reg [31:0] r_data_q = 32'h0;
   reg        r_last_q = 1'b0;
   reg [1:0]  r_id_q = 2'b00;
   reg [31:0] r_expected_q = 32'h0;

   reg        write_aw_seen = 1'b0;
   reg        write_wlast_seen = 1'b0;
   reg [31:0] saved_aw_addr = 32'h0;
   reg [1:0]  saved_aw_id = 2'b00;
   reg [7:0]  saved_aw_len = 8'h00;
   reg [2:0]  saved_aw_size = 3'b010;
   reg [7:0]  write_beat_index = 8'h00;

   reg        read_active = 1'b0;
   reg [31:0] saved_ar_addr = 32'h0;
   reg [1:0]  saved_ar_id = 2'b00;
   reg [7:0]  saved_ar_len = 8'h00;
   reg [2:0]  saved_ar_size = 3'b010;
   reg [7:0]  read_beat_index = 8'h00;

   reg        write_check_pending = 1'b0;
   reg [31:0] write_check_addr = 32'h0;
   reg [31:0] write_check_expected = 32'h0;
   reg [31:0] write_check_old = 32'h0;
   reg [31:0] write_check_data = 32'h0;
   reg [3:0]  write_check_strb = 4'h0;
   reg        init_done_q = 1'b0;

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
   reg [2:0] aw_stall_count_q = 3'h0;
   (* anyseq *) wire f_aw_ready_choice;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
   reg [2:0] w_stall_count_q = 3'h0;
   (* anyseq *) wire f_w_ready_choice;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
   reg [2:0] ar_stall_count_q = 3'h0;
   (* anyseq *) wire f_ar_ready_choice;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
   reg [2:0] bvalid_delay_count_q = 3'h0;
   (* anyseq *) wire f_bvalid_issue_choice;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
   reg [2:0] rvalid_delay_count_q = 3'h0;
   (* anyseq *) wire f_rvalid_issue_choice;
`endif

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire = w_valid && w_ready;
   wire b_fire = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire = r_valid && r_ready;
   wire read_busy = read_active || r_valid_q;

`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   (* anyconst *) wire f_cl1_bresp_slverr;
   (* anyconst *) wire f_cl1_rresp_slverr;
`endif

`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
`define AXI4_DI_CROSSBAR_ALLOW_SINGLE_BEAT_WRITE_CONTEXT
`endif
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
`define AXI4_DI_CROSSBAR_ALLOW_SINGLE_BEAT_WRITE_CONTEXT
`endif

`ifdef AXI4_DI_CROSSBAR_ALLOW_SINGLE_BEAT_WRITE_CONTEXT
   wire write_context_valid = write_aw_seen || aw_fire || w_fire;
   wire [31:0] write_context_addr =
      write_aw_seen ? saved_aw_addr :
      aw_fire ? aw_addr :
      cfg_source1_write_addr;
`else
   wire write_context_valid = write_aw_seen || aw_fire;
   wire [31:0] write_context_addr = write_aw_seen ? saved_aw_addr : aw_addr;
`endif
   wire [1:0]  write_context_id = write_aw_seen ? saved_aw_id : aw_id;
   wire [7:0]  write_context_len = write_aw_seen ? saved_aw_len : aw_len;
   wire [2:0]  write_context_size = write_aw_seen ? saved_aw_size : aw_size;
   wire [31:0] write_beat_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         write_context_addr, write_beat_index, write_context_size);

   wire [7:0] read_issue_index = ar_fire ? 8'h00 : read_beat_index;
   wire [7:0] read_issue_len = ar_fire ? ar_len : saved_ar_len;
   wire [2:0] read_issue_size = ar_fire ? ar_size : saved_ar_size;
   wire [31:0] read_issue_base = ar_fire ? ar_addr : saved_ar_addr;
   wire [1:0] read_issue_id = ar_fire ? ar_id : saved_ar_id;
   wire [31:0] read_issue_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         read_issue_base, read_issue_index, read_issue_size);
   wire [7:0] read_next_index =
      amba_axi4_data_integrity_pkg::axi4_di_next_beat_index8(read_beat_index);
   wire [31:0] read_current_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         saved_ar_addr, read_beat_index, saved_ar_size);
   wire [31:0] read_next_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         saved_ar_addr, read_next_index, saved_ar_size);

   wire write_resp_ready_to_issue =
      !b_valid_q &&
      ((write_aw_seen || aw_fire) &&
       (write_wlast_seen || (w_fire && w_last && write_context_valid)));
   wire read_data_ready_to_issue = !r_valid_q && (read_active || ar_fire);

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
   wire aw_stall_limit_reached =
      (aw_stall_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
   wire w_stall_limit_reached =
      (w_stall_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
   wire ar_stall_limit_reached =
      (ar_stall_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
   wire bvalid_delay_limit_reached =
      (bvalid_delay_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
   wire rvalid_delay_limit_reached =
      (rvalid_delay_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif

   assign aw_ready = aw_ready_q;
   assign w_ready = w_ready_q;
   assign ar_ready = ar_ready_q;
   assign b_valid = b_valid_q;
`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   assign b_resp = f_cl1_bresp_slverr ? RESP_SLVERR : RESP_OKAY;
`else
   assign b_resp = RESP_OKAY;
`endif
   assign b_id = b_id_q;
   assign r_valid = r_valid_q;
   assign r_data = r_data_q;
`ifdef AXI4_CL1_PROTOCOL_SYMBOLIC_RESP
   assign r_resp = f_cl1_rresp_slverr ? RESP_SLVERR : RESP_OKAY;
`else
   assign r_resp = RESP_OKAY;
`endif
   assign r_last = r_last_q;
   assign r_id = r_id_q;
   assign proof_write_aw_seen = write_aw_seen;
   assign proof_write_wlast_seen = write_wlast_seen;
   assign proof_saved_aw_len = saved_aw_len;
   assign proof_read_active = read_active;
   assign proof_read_beat_index = read_beat_index;

   function automatic bit in_window(input logic [31:0] base, input logic [31:0] addr);
      in_window =
         amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(base, addr);
   endfunction

   function automatic bit tracked_write_addr(input logic [31:0] addr);
      tracked_write_addr = in_window(cfg_source0_write_addr, addr) ||
                           in_window(cfg_source1_write_addr, addr);
   endfunction

   function automatic bit tracked_read_addr(input logic [31:0] addr);
      tracked_read_addr = in_window(cfg_source0_read_addr, addr) ||
                          in_window(cfg_source1_read_addr, addr);
   endfunction

   function automatic bit read_addr_has_write_state(input logic [31:0] addr);
      read_addr_has_write_state = tracked_read_addr(addr) && tracked_write_addr(addr);
   endfunction

   function automatic [31:0] expected_write_word(input logic [31:0] addr);
      begin
         if (in_window(cfg_source0_write_addr, addr))
            expected_write_word = cfg_source0_write_addr ^ {29'h0, addr[4:2]};
         else if (in_window(cfg_source1_write_addr, addr))
            expected_write_word = cfg_source1_write_addr ^ {29'h0, addr[4:2]};
         else
            expected_write_word = 32'h0;
      end
   endfunction

   function automatic [31:0] expected_read_word(input logic [31:0] addr);
      begin
         if (in_window(cfg_source0_read_addr, addr))
            expected_read_word =
               amba_axi4_data_integrity_pkg::axi4_di_initial_word32(
                  cfg_source0_read_addr, addr[4:2]);
         else if (in_window(cfg_source1_read_addr, addr))
            expected_read_word =
               amba_axi4_data_integrity_pkg::axi4_di_initial_word32(
                  cfg_source1_read_addr, addr[4:2]);
         else
            expected_read_word = 32'h0;
      end
   endfunction

   wire s0_write_fire = w_fire && write_context_valid &&
                        in_window(cfg_source0_write_addr, write_beat_addr);
   wire s1_write_fire = w_fire && write_context_valid &&
                        in_window(cfg_source1_write_addr, write_beat_addr);
   wire s0_write_addr_in_window;
   wire s0_write_targets_tracked_slot;
   wire [31:0] s0_write_old_word;
   wire [31:0] s0_write_expected_word;
   wire s0_read_issue_addr_in_window;
   wire s0_read_issue_targets_tracked_slot;
   wire [31:0] s0_read_issue_word;
   wire s0_read_next_addr_in_window;
   wire s0_read_next_targets_tracked_slot;
   wire [31:0] s0_read_next_word;
   wire s0_write_check_addr_in_window;
   wire s0_write_check_targets_tracked_slot;
   wire [31:0] s0_write_check_word;
   wire [31:0] s0_tracked_word;

   wire s1_write_addr_in_window;
   wire s1_write_targets_tracked_slot;
   wire [31:0] s1_write_old_word;
   wire [31:0] s1_write_expected_word;
   wire s1_read_issue_addr_in_window;
   wire s1_read_issue_targets_tracked_slot;
   wire [31:0] s1_read_issue_word;
   wire s1_read_next_addr_in_window;
   wire s1_read_next_targets_tracked_slot;
   wire [31:0] s1_read_next_word;
   wire s1_write_check_addr_in_window;
   wire s1_write_check_targets_tracked_slot;
   wire [31:0] s1_write_check_word;
   wire [31:0] s1_tracked_word;

   amba_axi4_di_golden_memory_core source0_write_memory (
      .clock(clock),
      .reset(reset),
      .init(!init_done_q),
      .base_addr(cfg_source0_write_addr),
      .tracked_beat(tracked_beat),
      .initial_tracked_word(initial_tracked_word),
      .write_fire(s0_write_fire),
      .write_addr(write_beat_addr),
      .write_data(w_data),
      .write_strb(w_strb),
      .write_addr_in_window(s0_write_addr_in_window),
      .write_targets_tracked_slot(s0_write_targets_tracked_slot),
      .write_old_word(s0_write_old_word),
      .write_expected_word(s0_write_expected_word),
      .read_addr(read_issue_addr),
      .read_addr_in_window(s0_read_issue_addr_in_window),
      .read_targets_tracked_slot(s0_read_issue_targets_tracked_slot),
      .read_word(s0_read_issue_word),
      .read1_addr(read_next_addr),
      .read1_addr_in_window(s0_read_next_addr_in_window),
      .read1_targets_tracked_slot(s0_read_next_targets_tracked_slot),
      .read1_word(s0_read_next_word),
      .read2_addr(write_check_addr),
      .read2_addr_in_window(s0_write_check_addr_in_window),
      .read2_targets_tracked_slot(s0_write_check_targets_tracked_slot),
      .read2_word(s0_write_check_word),
      .tracked_word(s0_tracked_word)
   );

   amba_axi4_di_golden_memory_core source1_write_memory (
      .clock(clock),
      .reset(reset),
      .init(!init_done_q),
      .base_addr(cfg_source1_write_addr),
      .tracked_beat(tracked_beat),
      .initial_tracked_word(initial_tracked_word),
      .write_fire(s1_write_fire),
      .write_addr(write_beat_addr),
      .write_data(w_data),
      .write_strb(w_strb),
      .write_addr_in_window(s1_write_addr_in_window),
      .write_targets_tracked_slot(s1_write_targets_tracked_slot),
      .write_old_word(s1_write_old_word),
      .write_expected_word(s1_write_expected_word),
      .read_addr(read_issue_addr),
      .read_addr_in_window(s1_read_issue_addr_in_window),
      .read_targets_tracked_slot(s1_read_issue_targets_tracked_slot),
      .read_word(s1_read_issue_word),
      .read1_addr(read_next_addr),
      .read1_addr_in_window(s1_read_next_addr_in_window),
      .read1_targets_tracked_slot(s1_read_next_targets_tracked_slot),
      .read1_word(s1_read_next_word),
      .read2_addr(write_check_addr),
      .read2_addr_in_window(s1_write_check_addr_in_window),
      .read2_targets_tracked_slot(s1_write_check_targets_tracked_slot),
      .read2_word(s1_write_check_word),
      .tracked_word(s1_tracked_word)
   );

   wire write_targets_tracked_slot =
      s1_write_targets_tracked_slot;
   wire [31:0] read_issue_profile_word =
      s1_read_issue_addr_in_window ? s1_read_issue_word :
      s0_read_issue_addr_in_window ? s0_read_issue_word :
      tracked_read_addr(read_issue_addr) ? expected_read_word(read_issue_addr) :
      (32'h5a5a_0000 ^ read_issue_addr);
   wire [31:0] read_next_profile_word =
      s1_read_next_addr_in_window ? s1_read_next_word :
      s0_read_next_addr_in_window ? s0_read_next_word :
      tracked_read_addr(read_next_addr) ? expected_read_word(read_next_addr) :
      (32'h5a5a_0000 ^ read_next_addr);
   wire [31:0] write_check_profile_word =
      s1_write_check_addr_in_window ? s1_write_check_word :
      s0_write_check_addr_in_window ? s0_write_check_word :
      tracked_read_addr(write_check_addr) ? expected_read_word(write_check_addr) :
      (32'h5a5a_0000 ^ write_check_addr);
   wire [31:0] current_write_old_word =
      s1_write_addr_in_window ? s1_write_old_word :
      s0_write_addr_in_window ? s0_write_old_word :
      tracked_read_addr(write_beat_addr) ? expected_read_word(write_beat_addr) :
      (32'h5a5a_0000 ^ write_beat_addr);
   wire [31:0] current_write_expected_word =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         current_write_old_word, w_data, w_strb);

   wire [31:0] write_check_current = write_check_profile_word;
   wire write_beat_addr_tracked = tracked_write_addr(write_beat_addr);
   wire [31:0] write_beat_expected_word = expected_write_word(write_beat_addr);
   wire ar_addr_tracked_read = tracked_read_addr(ar_addr);
   wire read_current_addr_tracked = tracked_read_addr(read_current_addr);
   wire read_current_addr_has_write_state = read_addr_has_write_state(read_current_addr);
   wire [31:0] read_current_expected_word = expected_read_word(read_current_addr);
   wire ar_addr_source0_read_window = in_window(cfg_source0_read_addr, ar_addr);
   wire ar_addr_source1_read_window = in_window(cfg_source1_read_addr, ar_addr);
   wire ar_addr_shared_read_write_window = read_addr_has_write_state(ar_addr);
   assign tracked_word = s1_tracked_word;
   assign proof_read_targets_tracked_slot =
      read_current_addr_tracked &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         read_beat_index[2:0], tracked_beat);
   assign proof_r_expected_word = r_expected_q;
   assign proof_read_current_profile_word = read_issue_profile_word;

   always @(posedge clock) begin
      if (reset) begin
         aw_ready_q <= 1'b0;
         w_ready_q <= 1'b0;
         ar_ready_q <= 1'b0;
         b_valid_q <= 1'b0;
         b_id_q <= 2'b00;
         r_valid_q <= 1'b0;
         r_data_q <= 32'h0;
         r_last_q <= 1'b0;
         r_id_q <= 2'b00;
         r_expected_q <= 32'h0;
         write_aw_seen <= 1'b0;
         write_wlast_seen <= 1'b0;
         saved_aw_addr <= 32'h0;
         saved_aw_id <= 2'b00;
         saved_aw_len <= 8'h00;
         saved_aw_size <= 3'b010;
         write_beat_index <= 8'h00;
         read_active <= 1'b0;
         saved_ar_addr <= 32'h0;
         saved_ar_id <= 2'b00;
         saved_ar_len <= 8'h00;
         saved_ar_size <= 3'b010;
         read_beat_index <= 8'h00;
         write_check_pending <= 1'b0;
         write_check_addr <= 32'h0;
         write_check_expected <= 32'h0;
         write_check_old <= 32'h0;
         write_check_data <= 32'h0;
         write_check_strb <= 4'h0;
         init_done_q <= 1'b0;
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
         aw_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
         w_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
         ar_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
         bvalid_delay_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
         rvalid_delay_count_q <= 3'h0;
`endif

      end
      else begin
         if (!init_done_q) begin
            init_done_q <= 1'b1;
         end
         else begin
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE
         if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                aw_valid, aw_ready_q, aw_stall_limit_reached))
            aw_stall_count_q <= aw_stall_count_q + 3'h1;
         else
            aw_stall_count_q <= 3'h0;

         aw_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               aw_ready_q, aw_valid, 1'b1,
               f_aw_ready_choice, aw_stall_limit_reached);
`else
         aw_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               aw_ready_q, aw_valid, 1'b1, 1'b1, 1'b0);
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE
         if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                w_valid, w_ready_q, w_stall_limit_reached))
            w_stall_count_q <= w_stall_count_q + 3'h1;
         else
            w_stall_count_q <= 3'h0;

         w_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               w_ready_q, w_valid, 1'b1,
               f_w_ready_choice, w_stall_limit_reached);
`else
         w_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               w_ready_q, w_valid, 1'b1, 1'b1, 1'b0);
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE
         if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                ar_valid, ar_ready_q, ar_stall_limit_reached))
            ar_stall_count_q <= ar_stall_count_q + 3'h1;
         else
            ar_stall_count_q <= 3'h0;

         ar_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               ar_ready_q, ar_valid, !read_busy,
               f_ar_ready_choice, ar_stall_limit_reached);
`else
         ar_ready_q <=
            amba_axi4_data_integrity_pkg::axi4_di_ready_pulse_next(
               ar_ready_q, ar_valid, !read_busy, 1'b1, 1'b0);
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
         if (write_resp_ready_to_issue &&
             !f_bvalid_issue_choice && !bvalid_delay_limit_reached)
            bvalid_delay_count_q <= bvalid_delay_count_q + 3'h1;
         else
            bvalid_delay_count_q <= 3'h0;
`endif

`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
         if (read_data_ready_to_issue &&
             !f_rvalid_issue_choice && !rvalid_delay_limit_reached)
            rvalid_delay_count_q <= rvalid_delay_count_q + 3'h1;
         else
            rvalid_delay_count_q <= 3'h0;
`endif

         if (aw_fire) begin
            write_aw_seen <= 1'b1;
            saved_aw_addr <= aw_addr;
            saved_aw_id <= aw_id;
            saved_aw_len <= aw_len;
            saved_aw_size <= aw_size;
            write_beat_index <= 8'h00;
         end

         if (w_fire && write_context_valid) begin
            write_check_pending <= tracked_write_addr(write_beat_addr);
            write_check_addr <= write_beat_addr;
            write_check_expected <= current_write_expected_word;
            write_check_old <= current_write_old_word;
            write_check_data <= w_data;
            write_check_strb <= w_strb;
            if (w_last)
               write_wlast_seen <= 1'b1;
            else
               write_beat_index <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index8(
                     write_beat_index);
         end
         else begin
            write_check_pending <= 1'b0;
         end

         if (write_resp_ready_to_issue
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_BVALID_DELAY
             && (f_bvalid_issue_choice || bvalid_delay_limit_reached)
`endif
         ) begin
            b_valid_q <= 1'b1;
            b_id_q <= write_context_id;
         end
         else if (b_fire) begin
            b_valid_q <= 1'b0;
            write_aw_seen <= 1'b0;
            write_wlast_seen <= 1'b0;
            write_beat_index <= 8'h00;
         end

         if (ar_fire) begin
            read_active <= 1'b1;
            saved_ar_addr <= ar_addr;
            saved_ar_id <= ar_id;
            saved_ar_len <= ar_len;
            saved_ar_size <= ar_size;
            read_beat_index <= 8'h00;
         end

         if (read_data_ready_to_issue
`ifdef AXI4_DI_CROSSBAR_DOWNSTREAM_RVALID_DELAY
             && (f_rvalid_issue_choice || rvalid_delay_limit_reached)
`endif
         ) begin
            r_valid_q <= 1'b1;
`ifdef AXI4_DI_CROSSBAR_DI_ENABLE
            r_data_q <= read_issue_profile_word;
            r_expected_q <= read_issue_profile_word;
`else
            r_data_q <= read_issue_profile_word;
            r_expected_q <= read_issue_profile_word;
`endif
            r_last_q <= read_issue_index == read_issue_len;
            r_id_q <= read_issue_id;
         end
         else if (r_fire && r_last_q) begin
            r_valid_q <= 1'b0;
            r_last_q <= 1'b0;
            read_active <= 1'b0;
            read_beat_index <= 8'h00;
         end
         else if (r_fire) begin
            read_beat_index <= read_next_index;
`ifdef AXI4_DI_CROSSBAR_DI_ENABLE
            r_data_q <= read_next_profile_word;
            r_expected_q <= read_next_profile_word;
`else
            r_data_q <= read_next_profile_word;
            r_expected_q <= read_next_profile_word;
`endif
            r_last_q <= read_next_index == saved_ar_len;
         end
         end
      end
   end

   amba_axi4_di_crossbar_downstream_memory_properties mem_properties (.*);

endmodule

`default_nettype wire
