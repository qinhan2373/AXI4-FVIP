`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_crossbar_axi_source_driver #(
   parameter bit ENABLE_WRITE = 1'b1,
   parameter logic [31:0] WRITE_ADDR = 32'h0000_1000,
   parameter logic [31:0] READ_ADDR  = 32'h0000_2000,
   parameter logic [2:0] WRITE_PROT = 3'b000,
   parameter logic [2:0] READ_PROT  = 3'b000
) (
   input wire        clock,
   input wire        reset,
   input wire        start,
   input wire [31:0] symbolic_addr,
   input wire [31:0] symbolic_write_addr,
   input wire [31:0] symbolic_read_addr,
   input wire [2:0]  symbolic_size,
   input wire [2:0]  symbolic_write_size,
   input wire [2:0]  symbolic_read_size,
   input wire        symbolic_write_single_beat,
   input wire        symbolic_read_single_beat,
   output wire       done,

   input wire        aw_ready,
   output wire       aw_valid,
   output wire [1:0] aw_id,
   output wire [31:0] aw_addr,
   output wire [7:0] aw_len,
   output wire [2:0] aw_size,
   output wire [1:0] aw_burst,
   output wire       aw_lock,
   output wire [3:0] aw_cache,
   output wire [2:0] aw_prot,

   input wire        w_ready,
   output wire       w_valid,
   output wire [31:0] w_data,
   output wire [3:0] w_strb,
   output wire       w_last,

   input wire        b_valid,
   input wire [1:0]  b_id,
   input wire [1:0]  b_resp,
   output wire       b_ready,

   input wire        ar_ready,
   output wire       ar_valid,
   output wire [1:0] ar_id,
   output wire [31:0] ar_addr,
   output wire [7:0] ar_len,
   output wire [2:0] ar_size,
   output wire [1:0] ar_burst,
   output wire       ar_lock,
   output wire [3:0] ar_cache,
   output wire [2:0] ar_prot,

   input wire        r_valid,
   input wire [1:0]  r_id,
   input wire [31:0] r_data,
   input wire [1:0]  r_resp,
   input wire        r_last,
   output wire       r_ready,

   output wire       traffic_started,
   output wire [1:0] phase,
   output wire       write_aw_done,
   output wire [3:0] write_req_beat,
   output wire [3:0] read_rsp_beat,
   output wire [3:0] write_burst_len,
   output wire [3:0] read_burst_len,
   output wire [1:0] write_axi_burst,
   output wire [1:0] read_axi_burst,
   output wire [1:0] write_axi_id,
   output wire [1:0] read_axi_id,
   output wire [3:0] write_axi_cache,
   output wire [3:0] read_axi_cache,
   output wire [2:0] write_axi_prot,
   output wire [2:0] read_axi_prot
);

`ifdef AXI4_DI_CROSSBAR_UPSTREAM_BACKPRESSURE
`ifndef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
`define AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
`endif
`ifndef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
`define AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
`endif
`endif

`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
`define AXI4_DI_CROSSBAR_ANY_UPSTREAM_BACKPRESSURE
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
`define AXI4_DI_CROSSBAR_ANY_UPSTREAM_BACKPRESSURE
`endif

`ifdef AXI4_DI_CROSSBAR_ANY_UPSTREAM_BACKPRESSURE
`ifndef AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL
`define AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL 2
`endif
`endif

   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
   localparam logic [1:0] PH_READ_REQ  = 2'd2;
   localparam logic [1:0] PH_READ_RSP  = 2'd3;

   (* anyseq *) wire [2:0] f_next_write_burst_len;
   (* anyseq *) wire [2:0] f_next_read_burst_len;

`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
   (* anyseq *) wire [31:0] f_symbolic_wdata_0;
   (* anyseq *) wire [31:0] f_symbolic_wdata_1;
   (* anyseq *) wire [31:0] f_symbolic_wdata_2;
   (* anyseq *) wire [31:0] f_symbolic_wdata_3;
   (* anyseq *) wire [31:0] f_symbolic_wdata_4;
   (* anyseq *) wire [31:0] f_symbolic_wdata_5;
   (* anyseq *) wire [31:0] f_symbolic_wdata_6;
   (* anyseq *) wire [31:0] f_symbolic_wdata_7;
   reg [31:0] symbolic_wdata_0_q = 32'h0;
   reg [31:0] symbolic_wdata_1_q = 32'h0;
   reg [31:0] symbolic_wdata_2_q = 32'h0;
   reg [31:0] symbolic_wdata_3_q = 32'h0;
   reg [31:0] symbolic_wdata_4_q = 32'h0;
   reg [31:0] symbolic_wdata_5_q = 32'h0;
   reg [31:0] symbolic_wdata_6_q = 32'h0;
   reg [31:0] symbolic_wdata_7_q = 32'h0;
`endif

`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
   (* anyseq *) wire [3:0] f_symbolic_wstrb_0;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_1;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_2;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_3;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_4;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_5;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_6;
   (* anyseq *) wire [3:0] f_symbolic_wstrb_7;
   reg [3:0] symbolic_wstrb_0_q = 4'h0;
   reg [3:0] symbolic_wstrb_1_q = 4'h0;
   reg [3:0] symbolic_wstrb_2_q = 4'h0;
   reg [3:0] symbolic_wstrb_3_q = 4'h0;
   reg [3:0] symbolic_wstrb_4_q = 4'h0;
   reg [3:0] symbolic_wstrb_5_q = 4'h0;
   reg [3:0] symbolic_wstrb_6_q = 4'h0;
   reg [3:0] symbolic_wstrb_7_q = 4'h0;
`endif

   reg       started_q = 1'b0;
   reg       done_q = 1'b0;
   reg [1:0] phase_q = PH_WRITE_REQ;
   reg       write_aw_done_q = 1'b0;
   reg [3:0] write_req_beat_q = 4'd0;
   reg [3:0] read_rsp_beat_q = 4'd0;
   reg [3:0] write_burst_len_q = 4'd0;
   reg [3:0] read_burst_len_q = 4'd0;
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
   reg [2:0] b_stall_count_q = 3'h0;
   (* anyseq *) wire f_b_ready_choice;
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
   reg [2:0] r_stall_count_q = 3'h0;
   (* anyseq *) wire f_r_ready_choice;
`endif

   wire aw_fire = aw_valid && aw_ready;
   wire w_fire  = w_valid && w_ready;
   wire b_fire  = b_valid && b_ready;
   wire ar_fire = ar_valid && ar_ready;
   wire r_fire  = r_valid && r_ready;
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
   wire b_stall_limit_reached =
      (b_stall_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
   wire r_stall_limit_reached =
      (r_stall_count_q >= `AXI4_DI_CROSSBAR_BACKPRESSURE_MAX_STALL);
`endif

`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_ADDR_MODE
   wire [31:0] selected_write_addr = symbolic_write_addr;
   wire [31:0] selected_read_addr = symbolic_read_addr;
`else
   wire [31:0] selected_write_addr = WRITE_ADDR;
   wire [31:0] selected_read_addr = READ_ADDR;
`endif
`ifdef AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
   wire mixed_write_single_beat_mode = symbolic_write_single_beat;
   wire mixed_read_single_beat_mode = symbolic_read_single_beat;
`endif
   wire [2:0] write_transfer_size =
`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
      symbolic_write_size;
`elsif AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
      symbolic_size;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
      symbolic_size;
`else
      3'b010;
`endif
   wire [2:0] read_transfer_size =
`ifdef AXI4_DI_CROSSBAR_MIXED_TRANSITION
      symbolic_read_size;
`elsif AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
      symbolic_size;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
      symbolic_size;
`else
      3'b010;
`endif
   wire write_single_beat_mode =
`ifdef AXI4_DI_CROSSBAR_FORCE_SINGLE_BEAT
      1'b1;
`elsif AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
      1'b1;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
      mixed_write_single_beat_mode;
`else
      1'b0;
`endif
   wire read_single_beat_mode =
`ifdef AXI4_DI_CROSSBAR_FORCE_SINGLE_BEAT
      1'b1;
`elsif AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
      1'b1;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
      mixed_read_single_beat_mode;
`else
      1'b0;
`endif
   wire [3:0] active_write_burst_len =
      write_single_beat_mode ? 4'd0 : write_burst_len_q;
   wire [3:0] active_read_burst_len =
      read_single_beat_mode ? 4'd0 : read_burst_len_q;

   assign done = done_q;
   assign traffic_started = started_q;
   assign phase = phase_q;
   assign write_aw_done = write_aw_done_q;
   assign write_req_beat = write_req_beat_q;
   assign read_rsp_beat = read_rsp_beat_q;
   assign write_burst_len = active_write_burst_len;
   assign read_burst_len = active_read_burst_len;
   assign write_axi_burst = INCR;
   assign read_axi_burst = INCR;
   assign write_axi_id = 2'd0;
   assign read_axi_id = 2'd0;
   assign write_axi_cache = 4'd0;
   assign read_axi_cache = 4'd0;
   assign write_axi_prot = WRITE_PROT;
   assign read_axi_prot = READ_PROT;

   assign aw_valid = ENABLE_WRITE && started_q && !done_q && (phase_q == PH_WRITE_REQ) && !write_aw_done_q;
   assign aw_id = write_axi_id;
   assign aw_addr = selected_write_addr;
   assign aw_len = {4'h0, active_write_burst_len};
   assign aw_size = write_transfer_size;
   assign aw_burst = write_axi_burst;
   assign aw_lock = 1'b0;
   assign aw_cache = write_axi_cache;
   assign aw_prot = write_axi_prot;

   assign w_valid = ENABLE_WRITE && started_q && !done_q && (phase_q == PH_WRITE_REQ) && write_aw_done_q;
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
   function automatic [31:0] symbolic_wdata_for_beat(input logic [3:0] beat);
      begin
         case (beat[2:0])
            3'd0: symbolic_wdata_for_beat = symbolic_wdata_0_q;
            3'd1: symbolic_wdata_for_beat = symbolic_wdata_1_q;
            3'd2: symbolic_wdata_for_beat = symbolic_wdata_2_q;
            3'd3: symbolic_wdata_for_beat = symbolic_wdata_3_q;
            3'd4: symbolic_wdata_for_beat = symbolic_wdata_4_q;
            3'd5: symbolic_wdata_for_beat = symbolic_wdata_5_q;
            3'd6: symbolic_wdata_for_beat = symbolic_wdata_6_q;
            default: symbolic_wdata_for_beat = symbolic_wdata_7_q;
         endcase
      end
   endfunction

   assign w_data = symbolic_wdata_for_beat(write_req_beat_q);
`else
   assign w_data = selected_write_addr ^ {28'h0, write_req_beat_q};
`endif
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
   function automatic [3:0] uncache_wstrb_for_transfer(
      input logic [2:0] size,
      input logic [1:0] offset
   );
      begin
         case (size[1:0])
            2'h0: uncache_wstrb_for_transfer = 4'b0001 << offset;
            2'h1: uncache_wstrb_for_transfer = offset[1] ? 4'b1100 : 4'b0011;
            default: uncache_wstrb_for_transfer = 4'b1111;
         endcase
      end
   endfunction

   assign w_strb = uncache_wstrb_for_transfer(write_transfer_size, selected_write_addr[1:0]);
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
   function automatic [3:0] uncache_wstrb_for_transfer(
      input logic [2:0] size,
      input logic [1:0] offset
   );
      begin
         case (size[1:0])
            2'h0: uncache_wstrb_for_transfer = 4'b0001 << offset;
            2'h1: uncache_wstrb_for_transfer = offset[1] ? 4'b1100 : 4'b0011;
            default: uncache_wstrb_for_transfer = 4'b1111;
         endcase
      end
   endfunction

   assign w_strb = uncache_wstrb_for_transfer(write_transfer_size, selected_write_addr[1:0]);
`else
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
   function automatic [3:0] symbolic_wstrb_for_beat(input logic [3:0] beat);
      begin
         case (beat[2:0])
            3'd0: symbolic_wstrb_for_beat = symbolic_wstrb_0_q;
            3'd1: symbolic_wstrb_for_beat = symbolic_wstrb_1_q;
            3'd2: symbolic_wstrb_for_beat = symbolic_wstrb_2_q;
            3'd3: symbolic_wstrb_for_beat = symbolic_wstrb_3_q;
            3'd4: symbolic_wstrb_for_beat = symbolic_wstrb_4_q;
            3'd5: symbolic_wstrb_for_beat = symbolic_wstrb_5_q;
            3'd6: symbolic_wstrb_for_beat = symbolic_wstrb_6_q;
            default: symbolic_wstrb_for_beat = symbolic_wstrb_7_q;
         endcase
      end
   endfunction

   assign w_strb = symbolic_wstrb_for_beat(write_req_beat_q);
`else
   assign w_strb = 4'hf;
`endif
`endif
   assign w_last = write_req_beat_q == active_write_burst_len;

`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
   assign b_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         !reset, b_valid, f_b_ready_choice, b_stall_limit_reached);
`else
   assign b_ready = !reset;
`endif

   assign ar_valid = started_q && !done_q && (phase_q == PH_READ_REQ);
   assign ar_id = read_axi_id;
   assign ar_addr = selected_read_addr;
   assign ar_len = {4'h0, active_read_burst_len};
   assign ar_size = read_transfer_size;
   assign ar_burst = read_axi_burst;
   assign ar_lock = 1'b0;
   assign ar_cache = read_axi_cache;
   assign ar_prot = read_axi_prot;

`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
   assign r_ready =
      amba_axi4_data_integrity_pkg::axi4_di_ready_with_bounded_stall(
         !reset, r_valid, f_r_ready_choice, r_stall_limit_reached);
`else
   assign r_ready = !reset;
`endif

	   always @(posedge clock) begin
	      if (reset) begin
	         started_q <= 1'b0;
	         done_q <= 1'b0;
	         phase_q <= ENABLE_WRITE ? PH_WRITE_REQ : PH_READ_REQ;
	         write_aw_done_q <= 1'b0;
	         write_req_beat_q <= 4'd0;
	         read_rsp_beat_q <= 4'd0;
`ifdef AXI4_DI_CROSSBAR_FORCE_SINGLE_BEAT
	         write_burst_len_q <= 4'd0;
	         read_burst_len_q <= 4'd0;
`else
	         write_burst_len_q <= {1'b0, f_next_write_burst_len};
`ifdef AXI4_DI_CROSSBAR_DI_ENABLE
	         read_burst_len_q <= {1'b0, f_next_write_burst_len};
`else
	         read_burst_len_q <= {1'b0, f_next_read_burst_len};
`endif
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
         b_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
         r_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
         symbolic_wdata_0_q <= f_symbolic_wdata_0;
         symbolic_wdata_1_q <= f_symbolic_wdata_1;
         symbolic_wdata_2_q <= f_symbolic_wdata_2;
         symbolic_wdata_3_q <= f_symbolic_wdata_3;
         symbolic_wdata_4_q <= f_symbolic_wdata_4;
         symbolic_wdata_5_q <= f_symbolic_wdata_5;
         symbolic_wdata_6_q <= f_symbolic_wdata_6;
         symbolic_wdata_7_q <= f_symbolic_wdata_7;
`endif
`ifdef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         symbolic_wstrb_0_q <= f_symbolic_wstrb_0;
         symbolic_wstrb_1_q <= f_symbolic_wstrb_1;
         symbolic_wstrb_2_q <= f_symbolic_wstrb_2;
         symbolic_wstrb_3_q <= f_symbolic_wstrb_3;
         symbolic_wstrb_4_q <= f_symbolic_wstrb_4;
         symbolic_wstrb_5_q <= f_symbolic_wstrb_5;
         symbolic_wstrb_6_q <= f_symbolic_wstrb_6;
         symbolic_wstrb_7_q <= f_symbolic_wstrb_7;
`endif
      end
      else begin
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_B_BACKPRESSURE
         if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                b_valid, b_ready, 1'b0))
            b_stall_count_q <= b_stall_count_q + 3'h1;
         else
            b_stall_count_q <= 3'h0;
`endif
`ifdef AXI4_DI_CROSSBAR_UPSTREAM_R_BACKPRESSURE
         if (amba_axi4_data_integrity_pkg::axi4_di_stall_counter_increments(
                r_valid, r_ready, 1'b0))
            r_stall_count_q <= r_stall_count_q + 3'h1;
         else
            r_stall_count_q <= 3'h0;
`endif

         if (!started_q && start)
            started_q <= 1'b1;

         if (aw_fire)
            write_aw_done_q <= 1'b1;

         case (phase_q)
            PH_WRITE_REQ:
               if (w_fire) begin
                  if (w_last)
                     phase_q <= PH_WRITE_RSP;
                  else
                     write_req_beat_q <= write_req_beat_q + 4'd1;
               end
            PH_WRITE_RSP:
               if (b_fire) begin
`ifdef AXI4_DI_CROSSBAR_DI_WRITE_ONLY_TRANSACTION
                  done_q <= 1'b1;
`else
                  phase_q <= PH_READ_REQ;
`endif
                  write_aw_done_q <= 1'b0;
                  write_req_beat_q <= 4'd0;
               end
            PH_READ_REQ:
               if (ar_fire) begin
                  read_rsp_beat_q <= 4'd0;
                  phase_q <= PH_READ_RSP;
               end
            PH_READ_RSP:
               if (r_fire && r_last)
                  done_q <= 1'b1;
               else if (r_fire)
                  read_rsp_beat_q <= read_rsp_beat_q + 4'd1;
            default:
               phase_q <= PH_WRITE_REQ;
         endcase
      end
   end

`ifdef AXI4_DI_CROSSBAR_EXTRA_SANITY
   amba_axi4_di_crossbar_source_driver_properties source_driver_properties (.*);
`endif

endmodule
