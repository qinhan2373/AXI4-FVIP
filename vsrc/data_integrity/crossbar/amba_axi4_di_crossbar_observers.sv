`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_crossbar_symbolic_addr_observer (
   input wire        clock,
   input wire        reset,
   input wire [31:0] cfg_shared_addr,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire [31:0] source0_req_addr,
   input wire        source0_req_wen,
   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire [31:0] source1_req_addr,
   input wire        source1_req_wen,

   input wire        downstream_aw_valid,
   input wire        downstream_aw_ready,
   input wire [31:0] downstream_aw_addr,
   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire [31:0] downstream_ar_addr
);

   amba_axi4_di_crossbar_symbolic_addr_properties addr_properties (.*);

endmodule

module amba_axi4_di_crossbar_symbolic_wdata_observer #(
   parameter int unsigned FIFO_DEPTH = 8
) (
   input wire        clock,
   input wire        reset,
   input wire [31:0] cfg_shared_addr,

   input wire        source1_w_valid,
   input wire        source1_w_ready,
   input wire [31:0] source1_w_data,
   input wire [3:0]  source1_w_strb,
   input wire        source1_w_last,
   input wire        source1_b_valid,
   input wire        source1_b_ready,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire        source0_req_wen,
   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire        source1_req_wen,

   input wire        source0_ar_valid,
   input wire        source0_ar_ready,
   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire        source0_r_last,

   input wire        source1_ar_valid,
   input wire        source1_ar_ready,
   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire        source1_r_last,

   input wire        downstream_aw_valid,
   input wire        downstream_aw_ready,
   input wire [31:0] downstream_aw_addr,
   input wire [7:0]  downstream_aw_len,
   input wire [2:0]  downstream_aw_size,
   input wire        downstream_w_valid,
   input wire        downstream_w_ready,
   input wire [31:0] downstream_w_data,
   input wire [3:0]  downstream_w_strb,
   input wire        downstream_w_last,
   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire        downstream_r_last
);

   localparam int unsigned WINDOW_WORDS = 8;
   localparam logic [3:0] FIFO_DEPTH_COUNT = 4'(FIFO_DEPTH);
   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;

   reg [31:0] expected_w_fifo_data [0:FIFO_DEPTH-1];
   reg [3:0]  expected_w_fifo_strb [0:FIFO_DEPTH-1];
   reg        expected_w_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  expected_w_fifo_rd = 3'h0;
   reg [2:0]  expected_w_fifo_wr = 3'h0;
   reg [3:0]  expected_w_fifo_count = 4'h0;

   reg [31:0] committed_mem [0:WINDOW_WORDS-1];
   reg        source0_expected_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  source0_expected_fifo_rd = 3'h0;
   reg [2:0]  source0_expected_fifo_wr = 3'h0;
   reg [3:0]  source0_expected_fifo_count = 4'h0;

   reg        source1_expected_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  source1_expected_fifo_rd = 3'h0;
   reg [2:0]  source1_expected_fifo_wr = 3'h0;
   reg [3:0]  source1_expected_fifo_count = 4'h0;

   reg        source_w_wait_q = 1'b0;
   reg [31:0] source_w_data_q = 32'h0;
   reg [3:0]  source_w_strb_q = 4'h0;
   reg        source_w_last_q = 1'b0;

   reg        downstream_aw_seen_q = 1'b0;
   reg [31:0] downstream_aw_addr_q = 32'h0;
   reg [7:0]  downstream_aw_len_q = 8'h0;
   reg [2:0]  downstream_aw_size_q = 3'b010;
   reg [7:0]  downstream_w_index_q = 8'h0;

   reg        write_check_pending_q = 1'b0;
   reg [2:0]  write_check_index_q = 3'h0;
   reg [31:0] write_check_expected_q = 32'h0;

   reg        read_owner_valid_q = 1'b0;
   reg        read_owner_q = OWNER0;
   reg        active_read_valid_q = 1'b0;
   reg        active_read_owner_q = OWNER0;

   reg        saw_first_wdata_q = 1'b0;
   reg [31:0] first_wdata_q = 32'h0;
   reg        saw_distinct_wdata_q = 1'b0;
   reg        saw_downstream_write_q = 1'b0;

   wire source1_w_fire = source1_w_valid && source1_w_ready;
   wire source1_b_fire = source1_b_valid && source1_b_ready;
   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source0_ar_fire = source0_ar_valid && source0_ar_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_ar_fire = source1_ar_valid && source1_ar_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   wire expected_w_fifo_empty = expected_w_fifo_count == 4'h0;
   wire expected_w_fifo_full = expected_w_fifo_count == FIFO_DEPTH_COUNT;
   wire expected_w_valid = !expected_w_fifo_empty || source1_w_fire;
   wire [31:0] expected_w_data =
      !expected_w_fifo_empty ? expected_w_fifo_data[expected_w_fifo_rd] : source1_w_data;
   wire [3:0] expected_w_strb =
      !expected_w_fifo_empty ? expected_w_fifo_strb[expected_w_fifo_rd] : source1_w_strb;
   wire expected_w_last =
      !expected_w_fifo_empty ? expected_w_fifo_last[expected_w_fifo_rd] : source1_w_last;

   wire downstream_write_context_valid = downstream_aw_seen_q || downstream_aw_fire;
   wire [31:0] downstream_write_base =
      downstream_aw_seen_q ? downstream_aw_addr_q : downstream_aw_addr;
   wire [7:0] downstream_write_len =
      downstream_aw_seen_q ? downstream_aw_len_q : downstream_aw_len;
   wire [2:0] downstream_write_size =
      downstream_aw_seen_q ? downstream_aw_size_q : downstream_aw_size;
   wire [31:0] downstream_write_addr =
      amba_axi4_data_integrity_pkg::axi4_di_incr_beat_addr32(
         downstream_write_base, downstream_w_index_q, downstream_write_size);
   wire [2:0] downstream_write_word_index = downstream_write_addr[4:2];
   wire read_owner_now_valid = read_owner_valid_q || source0_read_req_fire || source1_read_req_fire;
   wire read_owner_now =
      read_owner_valid_q ? read_owner_q : (source1_read_req_fire ? OWNER1 : OWNER0);

   wire source0_expected_fifo_empty = source0_expected_fifo_count == 4'h0;
   wire source0_expected_fifo_full = source0_expected_fifo_count == FIFO_DEPTH_COUNT;
   wire source0_expected_direct =
      downstream_r_fire && active_read_valid_q && (active_read_owner_q == OWNER0);
   wire source0_expected_valid = !source0_expected_fifo_empty || source0_expected_direct;
   wire source0_expected_last =
      !source0_expected_fifo_empty ? source0_expected_fifo_last[source0_expected_fifo_rd] :
                                     downstream_r_last;

   wire source1_expected_fifo_empty = source1_expected_fifo_count == 4'h0;
   wire source1_expected_fifo_full = source1_expected_fifo_count == FIFO_DEPTH_COUNT;
   wire source1_expected_direct =
      downstream_r_fire && active_read_valid_q && (active_read_owner_q == OWNER1);
   wire source1_expected_valid = !source1_expected_fifo_empty || source1_expected_direct;
   wire source1_expected_last =
      !source1_expected_fifo_empty ? source1_expected_fifo_last[source1_expected_fifo_rd] :
                                     downstream_r_last;
   wire [31:0] write_check_actual_word =
      committed_mem[write_check_index_q];

   function automatic [31:0] initial_word(input logic [31:0] base, input logic [2:0] index);
      initial_word = 32'ha5a5_0000 ^ base ^ {29'h0, index};
   endfunction

   integer init_i;
   always @(posedge clock) begin
      if (reset) begin
         expected_w_fifo_rd <= 3'h0;
         expected_w_fifo_wr <= 3'h0;
         expected_w_fifo_count <= 4'h0;
         source_w_wait_q <= 1'b0;
         source_w_data_q <= 32'h0;
         source_w_strb_q <= 4'h0;
         source_w_last_q <= 1'b0;
         downstream_aw_seen_q <= 1'b0;
         downstream_aw_addr_q <= 32'h0;
         downstream_aw_len_q <= 8'h0;
         downstream_aw_size_q <= 3'b010;
         downstream_w_index_q <= 8'h0;
         write_check_pending_q <= 1'b0;
         write_check_index_q <= 3'h0;
         write_check_expected_q <= 32'h0;
         source0_expected_fifo_rd <= 3'h0;
         source0_expected_fifo_wr <= 3'h0;
         source0_expected_fifo_count <= 4'h0;
         source1_expected_fifo_rd <= 3'h0;
         source1_expected_fifo_wr <= 3'h0;
         source1_expected_fifo_count <= 4'h0;
         read_owner_valid_q <= 1'b0;
         read_owner_q <= OWNER0;
         active_read_valid_q <= 1'b0;
         active_read_owner_q <= OWNER0;
         saw_first_wdata_q <= 1'b0;
         first_wdata_q <= 32'h0;
         saw_distinct_wdata_q <= 1'b0;
         saw_downstream_write_q <= 1'b0;

         for (init_i = 0; init_i < WINDOW_WORDS; init_i = init_i + 1) begin
            committed_mem[init_i] <= initial_word(cfg_shared_addr, init_i[2:0]);
         end
         for (init_i = 0; init_i < FIFO_DEPTH; init_i = init_i + 1) begin
            expected_w_fifo_data[init_i] <= 32'h0;
            expected_w_fifo_strb[init_i] <= 4'h0;
            expected_w_fifo_last[init_i] <= 1'b0;
            source0_expected_fifo_last[init_i] <= 1'b0;
            source1_expected_fifo_last[init_i] <= 1'b0;
         end
      end
      else begin
         source_w_wait_q <= source1_w_valid && !source1_w_ready;
         source_w_data_q <= source1_w_data;
         source_w_strb_q <= source1_w_strb;
         source_w_last_q <= source1_w_last;

         if (source1_w_fire) begin
            if (!saw_first_wdata_q) begin
               saw_first_wdata_q <= 1'b1;
               first_wdata_q <= source1_w_data;
            end
            else if (source1_w_data != first_wdata_q) begin
               saw_distinct_wdata_q <= 1'b1;
            end
         end

         if (source1_w_fire && (!downstream_w_fire || !expected_w_fifo_empty)) begin
            expected_w_fifo_data[expected_w_fifo_wr] <= source1_w_data;
            expected_w_fifo_strb[expected_w_fifo_wr] <= source1_w_strb;
            expected_w_fifo_last[expected_w_fifo_wr] <= source1_w_last;
         end

         if (source1_w_fire && downstream_w_fire) begin
            if (!expected_w_fifo_empty) begin
               expected_w_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_rd);
               expected_w_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_wr);
            end
         end
         else if (source1_w_fire) begin
            if (!expected_w_fifo_full) begin
               expected_w_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_wr);
               expected_w_fifo_count <= expected_w_fifo_count + 4'h1;
            end
         end
         else if (downstream_w_fire) begin
            if (!expected_w_fifo_empty) begin
               expected_w_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_rd);
               expected_w_fifo_count <= expected_w_fifo_count - 4'h1;
            end
         end

         if (downstream_aw_fire) begin
            downstream_aw_seen_q <= 1'b1;
            downstream_aw_addr_q <= downstream_aw_addr;
            downstream_aw_len_q <= downstream_aw_len;
            downstream_aw_size_q <= downstream_aw_size;
            downstream_w_index_q <= 8'h0;
         end

         if (downstream_w_fire && expected_w_valid && downstream_write_context_valid) begin
            committed_mem[downstream_write_word_index] <=
               amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
                  committed_mem[downstream_write_word_index],
                  expected_w_data,
                  expected_w_strb);
            write_check_pending_q <= 1'b1;
            write_check_index_q <= downstream_write_word_index;
            write_check_expected_q <=
               amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
                  committed_mem[downstream_write_word_index],
                  expected_w_data,
                  expected_w_strb);
            saw_downstream_write_q <= 1'b1;

            if (downstream_w_last) begin
               downstream_aw_seen_q <= 1'b0;
               downstream_w_index_q <= 8'h0;
            end
            else begin
               downstream_w_index_q <= downstream_w_index_q + 8'h1;
            end
         end
         else begin
            write_check_pending_q <= 1'b0;
         end

         if (!read_owner_valid_q) begin
            if (source0_read_req_fire) begin
               read_owner_valid_q <= 1'b1;
               read_owner_q <= OWNER0;
            end
            else if (source1_read_req_fire) begin
               read_owner_valid_q <= 1'b1;
               read_owner_q <= OWNER1;
            end
         end

         if (downstream_ar_fire && read_owner_now_valid) begin
            active_read_valid_q <= 1'b1;
            active_read_owner_q <= read_owner_now;
         end

         if (downstream_r_fire && active_read_valid_q &&
             (active_read_owner_q == OWNER0) &&
             (!source0_r_fire || !source0_expected_fifo_empty)) begin
            source0_expected_fifo_last[source0_expected_fifo_wr] <= downstream_r_last;
         end
         if (downstream_r_fire && active_read_valid_q &&
             (active_read_owner_q == OWNER0) && source0_r_fire) begin
            if (!source0_expected_fifo_empty) begin
               source0_expected_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_expected_fifo_rd);
               source0_expected_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_expected_fifo_wr);
            end
         end
         else if (downstream_r_fire && active_read_valid_q &&
                  (active_read_owner_q == OWNER0)) begin
            if (!source0_expected_fifo_full) begin
               source0_expected_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_expected_fifo_wr);
               source0_expected_fifo_count <= source0_expected_fifo_count + 4'h1;
            end
         end
         else if (source0_r_fire) begin
            if (!source0_expected_fifo_empty) begin
               source0_expected_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_expected_fifo_rd);
               source0_expected_fifo_count <= source0_expected_fifo_count - 4'h1;
            end
         end

         if (downstream_r_fire && active_read_valid_q &&
             (active_read_owner_q == OWNER1) &&
             (!source1_r_fire || !source1_expected_fifo_empty)) begin
            source1_expected_fifo_last[source1_expected_fifo_wr] <= downstream_r_last;
         end
         if (downstream_r_fire && active_read_valid_q &&
             (active_read_owner_q == OWNER1) && source1_r_fire) begin
            if (!source1_expected_fifo_empty) begin
               source1_expected_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_expected_fifo_rd);
               source1_expected_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_expected_fifo_wr);
            end
         end
         else if (downstream_r_fire && active_read_valid_q &&
                  (active_read_owner_q == OWNER1)) begin
            if (!source1_expected_fifo_full) begin
               source1_expected_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_expected_fifo_wr);
               source1_expected_fifo_count <= source1_expected_fifo_count + 4'h1;
            end
         end
         else if (source1_r_fire) begin
            if (!source1_expected_fifo_empty) begin
               source1_expected_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_expected_fifo_rd);
               source1_expected_fifo_count <= source1_expected_fifo_count - 4'h1;
            end
         end

         if (downstream_r_fire && active_read_valid_q) begin
            if (downstream_r_last) begin
               active_read_valid_q <= 1'b0;
               read_owner_valid_q <= 1'b0;
            end
         end

      end
   end

   amba_axi4_di_crossbar_symbolic_wdata_properties wdata_properties (.*);

endmodule

module amba_axi4_di_crossbar_symbolic_wstrb_observer #(
   parameter int unsigned FIFO_DEPTH = 8
) (
   input wire       clock,
   input wire       reset,

   input wire       source1_w_valid,
   input wire       source1_w_ready,
   input wire [3:0] source1_w_strb,
   input wire       source1_w_last,

   input wire       source1_r_valid,
   input wire       source1_r_ready,
   input wire       source1_r_last,

   input wire       downstream_w_valid,
   input wire       downstream_w_ready,
   input wire [3:0] downstream_w_strb,
   input wire       downstream_w_last
);

   localparam logic [3:0] FIFO_DEPTH_COUNT = 4'(FIFO_DEPTH);

   reg [3:0] expected_w_fifo_strb [0:FIFO_DEPTH-1];
   reg       expected_w_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0] expected_w_fifo_rd = 3'h0;
   reg [2:0] expected_w_fifo_wr = 3'h0;
   reg [3:0] expected_w_fifo_count = 4'h0;

   reg       source_w_wait_q = 1'b0;
   reg [3:0] source_w_strb_q = 4'h0;
   reg       source_w_last_q = 1'b0;

   reg       saw_partial_downstream_wstrb_q = 1'b0;
   reg       saw_8beat_partial_wstrb_q = 1'b0;
   reg [3:0] source1_write_beat_count_q = 4'h0;

   wire source1_w_fire = source1_w_valid && source1_w_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;

   wire expected_w_fifo_empty = expected_w_fifo_count == 4'h0;
   wire expected_w_fifo_full = expected_w_fifo_count == FIFO_DEPTH_COUNT;
   wire expected_w_valid = !expected_w_fifo_empty || source1_w_fire;
   wire [3:0] expected_w_strb =
      !expected_w_fifo_empty ? expected_w_fifo_strb[expected_w_fifo_rd] : source1_w_strb;
   wire expected_w_last =
      !expected_w_fifo_empty ? expected_w_fifo_last[expected_w_fifo_rd] : source1_w_last;

   wire source1_wstrb_partial = source1_w_strb != 4'h0 && source1_w_strb != 4'hf;
   wire expected_wstrb_partial = expected_w_strb != 4'h0 && expected_w_strb != 4'hf;

   integer init_i;
   always @(posedge clock) begin
      if (reset) begin
         expected_w_fifo_rd <= 3'h0;
         expected_w_fifo_wr <= 3'h0;
         expected_w_fifo_count <= 4'h0;
         source_w_wait_q <= 1'b0;
         source_w_strb_q <= 4'h0;
         source_w_last_q <= 1'b0;
         saw_partial_downstream_wstrb_q <= 1'b0;
         saw_8beat_partial_wstrb_q <= 1'b0;
         source1_write_beat_count_q <= 4'h0;

         for (init_i = 0; init_i < FIFO_DEPTH; init_i = init_i + 1) begin
            expected_w_fifo_strb[init_i] <= 4'h0;
            expected_w_fifo_last[init_i] <= 1'b0;
         end
      end
      else begin
         source_w_wait_q <= source1_w_valid && !source1_w_ready;
         source_w_strb_q <= source1_w_strb;
         source_w_last_q <= source1_w_last;

         if (source1_w_fire && (!downstream_w_fire || !expected_w_fifo_empty)) begin
            expected_w_fifo_strb[expected_w_fifo_wr] <= source1_w_strb;
            expected_w_fifo_last[expected_w_fifo_wr] <= source1_w_last;
         end

         if (source1_w_fire && downstream_w_fire) begin
            if (!expected_w_fifo_empty) begin
               expected_w_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_rd);
               expected_w_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_wr);
            end
         end
         else if (source1_w_fire) begin
            if (!expected_w_fifo_full) begin
               expected_w_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_wr);
               expected_w_fifo_count <= expected_w_fifo_count + 4'h1;
            end
         end
         else if (downstream_w_fire) begin
            if (!expected_w_fifo_empty) begin
               expected_w_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(expected_w_fifo_rd);
               expected_w_fifo_count <= expected_w_fifo_count - 4'h1;
            end
         end

         if (source1_w_fire) begin
            if (source1_w_last)
               source1_write_beat_count_q <= 4'h0;
            else
               source1_write_beat_count_q <= source1_write_beat_count_q + 4'h1;

            if (source1_wstrb_partial && source1_w_last &&
                (source1_write_beat_count_q == 4'd7))
               saw_8beat_partial_wstrb_q <= 1'b1;
         end

         if (downstream_w_fire && expected_w_valid && expected_wstrb_partial)
            saw_partial_downstream_wstrb_q <= 1'b1;
      end
   end

   amba_axi4_di_crossbar_symbolic_wstrb_properties wstrb_properties (.*);

endmodule

module amba_axi4_di_crossbar_owner_scoreboard #(
   parameter logic [31:0] SOURCE0_WRITE_ADDR = 32'h0000_1000,
   parameter logic [31:0] SOURCE0_READ_ADDR  = 32'h0000_2000,
   parameter logic [31:0] SOURCE1_WRITE_ADDR = 32'h0000_3000,
   parameter logic [31:0] SOURCE1_READ_ADDR  = 32'h0000_4000
) (
   input wire        clock,
   input wire        reset,
   input wire [31:0] cfg_source0_write_addr,
   input wire [31:0] cfg_source0_read_addr,
   input wire [31:0] cfg_source1_write_addr,
   input wire [31:0] cfg_source1_read_addr,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire [31:0] source0_req_addr,
   input wire [31:0] source0_req_data,
   input wire        source0_req_wen,
   input wire        source0_req_last,
   input wire        source0_rsp_valid,
   input wire        source0_rsp_ready,
   input wire        source0_rsp_last,

   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire [31:0] source1_req_addr,
   input wire [31:0] source1_req_data,
   input wire        source1_req_wen,
   input wire        source1_req_last,
   input wire        source1_rsp_valid,
   input wire        source1_rsp_ready,
   input wire        source1_rsp_last,

   input wire        downstream_aw_valid,
   input wire        downstream_aw_ready,
   input wire [31:0] downstream_aw_addr,
   input wire        downstream_w_valid,
   input wire        downstream_w_ready,
   input wire [31:0] downstream_w_data,
   input wire        downstream_b_valid,
   input wire        downstream_b_ready,
   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire [31:0] downstream_ar_addr,
   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire        downstream_r_last,

   input wire        source0_b_valid,
   input wire        source0_b_ready,
   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire        source0_r_last,
   input wire        source1_b_valid,
   input wire        source1_b_ready,
   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire        source1_r_last
);

   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_write_req_fire = source0_req_fire && source0_req_wen;
   wire source1_write_req_fire = source1_req_fire && source1_req_wen;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;

   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   wire source0_rsp_fire = source0_rsp_valid && source0_rsp_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;
   wire source0_b_fire = source0_b_valid && source0_b_ready;
   wire source1_b_fire = source1_b_valid && source1_b_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;

   reg write_path_owner_valid = 1'b0;
   reg write_path_owner = OWNER0;
   reg write_path_last_seen = 1'b0;
   reg read_path_owner_valid = 1'b0;
   reg read_path_owner = OWNER0;
   reg source0_b_pending = 1'b0;
   reg source1_b_pending = 1'b0;
   reg source0_r_pending = 1'b0;
   reg source1_r_pending = 1'b0;
   reg source0_r_pending_last = 1'b0;
   reg source1_r_pending_last = 1'b0;

   wire write_owner_now_valid =
      write_path_owner_valid || source0_write_req_fire || source1_write_req_fire;
   wire write_owner_now =
      write_path_owner_valid ? write_path_owner : source1_write_req_fire;
   wire read_owner_now_valid =
      read_path_owner_valid || source0_read_req_fire || source1_read_req_fire;
   wire read_owner_now =
      read_path_owner_valid ? read_path_owner : source1_read_req_fire;

   always @(posedge clock) begin
      if (reset) begin
         write_path_owner_valid <= 1'b0;
         write_path_owner <= OWNER0;
         write_path_last_seen <= 1'b0;
         read_path_owner_valid <= 1'b0;
         read_path_owner <= OWNER0;
         source0_b_pending <= 1'b0;
         source1_b_pending <= 1'b0;
         source0_r_pending <= 1'b0;
         source1_r_pending <= 1'b0;
         source0_r_pending_last <= 1'b0;
         source1_r_pending_last <= 1'b0;
      end
      else begin
         if (!write_path_owner_valid) begin
            if (source0_write_req_fire) begin
               write_path_owner_valid <= 1'b1;
               write_path_owner <= OWNER0;
               write_path_last_seen <= source0_req_last;
            end
            else if (source1_write_req_fire) begin
               write_path_owner_valid <= 1'b1;
               write_path_owner <= OWNER1;
               write_path_last_seen <= source1_req_last;
            end
         end
         else begin
            if ((source0_write_req_fire && (write_path_owner == OWNER0)) ||
                (source1_write_req_fire && (write_path_owner == OWNER1)))
               write_path_last_seen <= write_path_last_seen ||
                                       (write_path_owner == OWNER1 ? source1_req_last : source0_req_last);

            if (source0_rsp_fire && (write_path_owner == OWNER0)) begin
               source0_b_pending <= 1'b1;
               write_path_owner_valid <= 1'b0;
               write_path_last_seen <= 1'b0;
            end
            else if (source1_rsp_fire && (write_path_owner == OWNER1)) begin
               source1_b_pending <= 1'b1;
               write_path_owner_valid <= 1'b0;
               write_path_last_seen <= 1'b0;
            end
         end

         if (!read_path_owner_valid) begin
            if (source0_read_req_fire) begin
               read_path_owner_valid <= 1'b1;
               read_path_owner <= OWNER0;
            end
            else if (source1_read_req_fire) begin
               read_path_owner_valid <= 1'b1;
               read_path_owner <= OWNER1;
            end
         end
         else begin
            if (source0_rsp_fire && (read_path_owner == OWNER0)) begin
               source0_r_pending <= 1'b1;
               source0_r_pending_last <= source0_rsp_last;
               if (source0_rsp_last)
                  read_path_owner_valid <= 1'b0;
            end
            else if (source1_rsp_fire && (read_path_owner == OWNER1)) begin
               source1_r_pending <= 1'b1;
               source1_r_pending_last <= source1_rsp_last;
               if (source1_rsp_last)
                  read_path_owner_valid <= 1'b0;
            end
         end

         if (source0_b_fire)
            source0_b_pending <= 1'b0;
         if (source1_b_fire)
            source1_b_pending <= 1'b0;
         if (source0_r_fire)
            source0_r_pending <= 1'b0;
         if (source1_r_fire)
            source1_r_pending <= 1'b0;
      end
   end

   amba_axi4_di_crossbar_owner_scoreboard_properties owner_properties (.*);

endmodule

module amba_axi4_di_crossbar_source_readback_observer #(
   parameter int unsigned FIFO_DEPTH = 8
) (
   input wire        clock,
   input wire        reset,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire        source0_req_wen,
   input wire        source0_rsp_valid,
   input wire        source0_rsp_ready,
   input wire [31:0] source0_rsp_data,
   input wire        source0_rsp_last,

   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire        source1_req_wen,
   input wire        source1_rsp_valid,
   input wire        source1_rsp_ready,
   input wire [31:0] source1_rsp_data,
   input wire        source1_rsp_last,

   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire [31:0] downstream_r_data,
   input wire        downstream_r_last,

   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire [31:0] source0_r_data,
   input wire        source0_r_last,

   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire [31:0] source1_r_data,
   input wire        source1_r_last
);

   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;
   localparam logic [3:0] FIFO_DEPTH_COUNT = 4'(FIFO_DEPTH);

   reg        read_owner_valid = 1'b0;
   reg        read_owner = OWNER0;

   reg [31:0] downstream_fifo_data [0:FIFO_DEPTH-1];
   reg        downstream_fifo_owner [0:FIFO_DEPTH-1];
   reg        downstream_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  downstream_fifo_rd = 3'd0;
   reg [2:0]  downstream_fifo_wr = 3'd0;
   reg [3:0]  downstream_fifo_count = 4'd0;

   reg [31:0] source0_fifo_data [0:FIFO_DEPTH-1];
   reg        source0_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  source0_fifo_rd = 3'd0;
   reg [2:0]  source0_fifo_wr = 3'd0;
   reg [3:0]  source0_fifo_count = 4'd0;

   reg [31:0] source1_fifo_data [0:FIFO_DEPTH-1];
   reg        source1_fifo_last [0:FIFO_DEPTH-1];
   reg [2:0]  source1_fifo_rd = 3'd0;
   reg [2:0]  source1_fifo_wr = 3'd0;
   reg [3:0]  source1_fifo_count = 4'd0;

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source0_rsp_fire = source0_rsp_valid && source0_rsp_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;

   wire source0_read_rsp_fire = source0_rsp_fire && read_owner_valid && (read_owner == OWNER0);
   wire source1_read_rsp_fire = source1_rsp_fire && read_owner_valid && (read_owner == OWNER1);
   wire cachebus_rsp_fire = source0_read_rsp_fire || source1_read_rsp_fire;
   wire cachebus_rsp_owner = source1_read_rsp_fire ? OWNER1 : OWNER0;
   wire [31:0] cachebus_rsp_data = source1_read_rsp_fire ? source1_rsp_data : source0_rsp_data;
   wire cachebus_rsp_last = source1_read_rsp_fire ? source1_rsp_last : source0_rsp_last;
   wire read_owner_complete = cachebus_rsp_fire && cachebus_rsp_last;
   wire read_owner_can_start = !read_owner_valid || read_owner_complete;

   wire downstream_fifo_empty = downstream_fifo_count == 4'd0;
   wire downstream_expected_valid = !downstream_fifo_empty || downstream_r_fire;
   wire downstream_expected_owner =
      !downstream_fifo_empty ? downstream_fifo_owner[downstream_fifo_rd] : read_owner;
   wire [31:0] downstream_expected_data =
      !downstream_fifo_empty ? downstream_fifo_data[downstream_fifo_rd] : downstream_r_data;
   wire downstream_expected_last =
      !downstream_fifo_empty ? downstream_fifo_last[downstream_fifo_rd] : downstream_r_last;

   wire source0_fifo_empty = source0_fifo_count == 4'd0;
   wire source0_expected_valid = !source0_fifo_empty || source0_read_rsp_fire;
   wire [31:0] source0_expected_data =
      !source0_fifo_empty ? source0_fifo_data[source0_fifo_rd] : source0_rsp_data;
   wire source0_expected_last =
      !source0_fifo_empty ? source0_fifo_last[source0_fifo_rd] : source0_rsp_last;

   wire source1_fifo_empty = source1_fifo_count == 4'd0;
   wire source1_expected_valid = !source1_fifo_empty || source1_read_rsp_fire;
   wire [31:0] source1_expected_data =
      !source1_fifo_empty ? source1_fifo_data[source1_fifo_rd] : source1_rsp_data;
   wire source1_expected_last =
      !source1_fifo_empty ? source1_fifo_last[source1_fifo_rd] : source1_rsp_last;

   integer init_i;

   always @(posedge clock) begin
      if (reset) begin
         read_owner_valid <= 1'b0;
         read_owner <= OWNER0;
         downstream_fifo_rd <= 3'd0;
         downstream_fifo_wr <= 3'd0;
         downstream_fifo_count <= 4'd0;
         source0_fifo_rd <= 3'd0;
         source0_fifo_wr <= 3'd0;
         source0_fifo_count <= 4'd0;
         source1_fifo_rd <= 3'd0;
         source1_fifo_wr <= 3'd0;
         source1_fifo_count <= 4'd0;

         for (init_i = 0; init_i < FIFO_DEPTH; init_i = init_i + 1) begin
            downstream_fifo_data[init_i] <= 32'h0;
            downstream_fifo_owner[init_i] <= OWNER0;
            downstream_fifo_last[init_i] <= 1'b0;
            source0_fifo_data[init_i] <= 32'h0;
            source0_fifo_last[init_i] <= 1'b0;
            source1_fifo_data[init_i] <= 32'h0;
            source1_fifo_last[init_i] <= 1'b0;
         end
      end
      else begin
         if (read_owner_can_start && source0_read_req_fire) begin
            read_owner_valid <= 1'b1;
            read_owner <= OWNER0;
         end
         else if (read_owner_can_start && source1_read_req_fire) begin
            read_owner_valid <= 1'b1;
            read_owner <= OWNER1;
         end
         else if (read_owner_complete) begin
            read_owner_valid <= 1'b0;
         end

         if (downstream_r_fire && (!cachebus_rsp_fire || !downstream_fifo_empty)) begin
            downstream_fifo_data[downstream_fifo_wr] <= downstream_r_data;
            downstream_fifo_owner[downstream_fifo_wr] <= read_owner;
            downstream_fifo_last[downstream_fifo_wr] <= downstream_r_last;
         end
         if (downstream_r_fire && cachebus_rsp_fire) begin
            if (!downstream_fifo_empty) begin
               downstream_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(downstream_fifo_rd);
               downstream_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(downstream_fifo_wr);
            end
         end
         else if (downstream_r_fire) begin
            if (downstream_fifo_count != FIFO_DEPTH_COUNT) begin
               downstream_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(downstream_fifo_wr);
               downstream_fifo_count <= downstream_fifo_count + 4'd1;
            end
         end
         else if (cachebus_rsp_fire) begin
            if (!downstream_fifo_empty) begin
               downstream_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(downstream_fifo_rd);
               downstream_fifo_count <= downstream_fifo_count - 4'd1;
            end
         end

         if (source0_read_rsp_fire && (!source0_r_fire || !source0_fifo_empty)) begin
            source0_fifo_data[source0_fifo_wr] <= source0_rsp_data;
            source0_fifo_last[source0_fifo_wr] <= source0_rsp_last;
         end
         if (source0_read_rsp_fire && source0_r_fire) begin
            if (!source0_fifo_empty) begin
               source0_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_fifo_rd);
               source0_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_fifo_wr);
            end
         end
         else if (source0_read_rsp_fire) begin
            if (source0_fifo_count != FIFO_DEPTH_COUNT) begin
               source0_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_fifo_wr);
               source0_fifo_count <= source0_fifo_count + 4'd1;
            end
         end
         else if (source0_r_fire) begin
            if (!source0_fifo_empty) begin
               source0_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source0_fifo_rd);
               source0_fifo_count <= source0_fifo_count - 4'd1;
            end
         end

         if (source1_read_rsp_fire && (!source1_r_fire || !source1_fifo_empty)) begin
            source1_fifo_data[source1_fifo_wr] <= source1_rsp_data;
            source1_fifo_last[source1_fifo_wr] <= source1_rsp_last;
         end
         if (source1_read_rsp_fire && source1_r_fire) begin
            if (!source1_fifo_empty) begin
               source1_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_fifo_rd);
               source1_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_fifo_wr);
            end
         end
         else if (source1_read_rsp_fire) begin
            if (source1_fifo_count != FIFO_DEPTH_COUNT) begin
               source1_fifo_wr <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_fifo_wr);
               source1_fifo_count <= source1_fifo_count + 4'd1;
            end
         end
         else if (source1_r_fire) begin
            if (!source1_fifo_empty) begin
               source1_fifo_rd <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_fifo_index3(source1_fifo_rd);
               source1_fifo_count <= source1_fifo_count - 4'd1;
            end
         end
      end
   end

   amba_axi4_di_crossbar_source_readback_properties #(
      .FIFO_DEPTH(FIFO_DEPTH)
   ) source_properties (.*);

endmodule

module amba_axi4_di_crossbar_arbitration_backpressure_observer (
   input wire        clock,
   input wire        reset,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire [31:0] source0_req_addr,
   input wire [31:0] source0_req_data,
   input wire        source0_req_wen,
   input wire [3:0]  source0_req_mask,
   input wire [3:0]  source0_req_len,
   input wire [1:0]  source0_req_size,
   input wire        source0_req_last,
   input wire        source0_rsp_valid,
   input wire        source0_rsp_ready,
   input wire        source0_rsp_last,

   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire [31:0] source1_req_addr,
   input wire [31:0] source1_req_data,
   input wire        source1_req_wen,
   input wire [3:0]  source1_req_mask,
   input wire [3:0]  source1_req_len,
   input wire [1:0]  source1_req_size,
   input wire        source1_req_last,
   input wire        source1_rsp_valid,
   input wire        source1_rsp_ready,
   input wire        source1_rsp_last,

   input wire        downstream_aw_valid,
   input wire        downstream_aw_ready,
   input wire [31:0] downstream_aw_addr,
   input wire [7:0]  downstream_aw_len,
   input wire [2:0]  downstream_aw_size,
   input wire [1:0]  downstream_aw_burst,
   input wire        downstream_aw_lock,
   input wire [3:0]  downstream_aw_cache,
   input wire [2:0]  downstream_aw_prot,

   input wire        downstream_w_valid,
   input wire        downstream_w_ready,
   input wire [31:0] downstream_w_data,
   input wire [3:0]  downstream_w_strb,
   input wire        downstream_w_last,

   input wire        downstream_b_valid,
   input wire        downstream_b_ready,

   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire [31:0] downstream_ar_addr,
   input wire [7:0]  downstream_ar_len,
   input wire [2:0]  downstream_ar_size,
   input wire [1:0]  downstream_ar_burst,
   input wire        downstream_ar_lock,
   input wire [3:0]  downstream_ar_cache,
   input wire [2:0]  downstream_ar_prot,

   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire        downstream_r_last,

   input wire        arbiter_req_valid,
   input wire        arbiter_req_wen,
   input wire [3:0]  arbiter_req_mask,
   input wire [3:0]  arbiter_req_len,
   input wire [1:0]  arbiter_req_size
);

   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_rsp_fire = source0_rsp_valid && source0_rsp_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;

   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   reg txn_active_q = 1'b0;
   reg txn_owner_q = OWNER0;
   reg saw_source1_block_q = 1'b0;
   reg saw_downstream_aw_stall_q = 1'b0;
   reg saw_downstream_w_stall_q = 1'b0;
   reg saw_downstream_ar_stall_q = 1'b0;
   reg write_resp_pending_q = 1'b0;
   reg read_resp_pending_q = 1'b0;
   reg saw_downstream_b_delay_q = 1'b0;
   reg saw_downstream_r_delay_q = 1'b0;

   reg source0_req_wait_q = 1'b0;
   reg [31:0] source0_req_addr_q = 32'h0;
   reg [31:0] source0_req_data_q = 32'h0;
   reg        source0_req_wen_q = 1'b0;
   reg [3:0]  source0_req_mask_q = 4'h0;
   reg [3:0]  source0_req_len_q = 4'h0;
   reg [1:0]  source0_req_size_q = 2'h0;
   reg        source0_req_last_q = 1'b0;

   reg source1_req_wait_q = 1'b0;
   reg [31:0] source1_req_addr_q = 32'h0;
   reg [31:0] source1_req_data_q = 32'h0;
   reg        source1_req_wen_q = 1'b0;
   reg [3:0]  source1_req_mask_q = 4'h0;
   reg [3:0]  source1_req_len_q = 4'h0;
   reg [1:0]  source1_req_size_q = 2'h0;
   reg        source1_req_last_q = 1'b0;

   reg downstream_aw_wait_q = 1'b0;
   reg [31:0] downstream_aw_addr_q = 32'h0;
   reg [7:0]  downstream_aw_len_q = 8'h0;
   reg [2:0]  downstream_aw_size_q = 3'h0;
   reg [1:0]  downstream_aw_burst_q = 2'h0;
   reg        downstream_aw_lock_q = 1'b0;
   reg [3:0]  downstream_aw_cache_q = 4'h0;
   reg [2:0]  downstream_aw_prot_q = 3'h0;

   reg downstream_w_wait_q = 1'b0;
   reg [31:0] downstream_w_data_q = 32'h0;
   reg [3:0]  downstream_w_strb_q = 4'h0;
   reg        downstream_w_last_q = 1'b0;

   reg downstream_ar_wait_q = 1'b0;
   reg [31:0] downstream_ar_addr_q = 32'h0;
   reg [7:0]  downstream_ar_len_q = 8'h0;
   reg [2:0]  downstream_ar_size_q = 3'h0;
   reg [1:0]  downstream_ar_burst_q = 2'h0;
   reg        downstream_ar_lock_q = 1'b0;
   reg [3:0]  downstream_ar_cache_q = 4'h0;
   reg [2:0]  downstream_ar_prot_q = 3'h0;

   wire idle_arb_window = !txn_active_q;
   wire both_sources_request = source0_req_valid && source1_req_valid;
   wire both_sources_read_request =
      both_sources_request && !source0_req_wen && !source1_req_wen;

   always @(posedge clock) begin
      if (reset) begin
         txn_active_q <= 1'b0;
         txn_owner_q <= OWNER0;
         saw_source1_block_q <= 1'b0;
         saw_downstream_aw_stall_q <= 1'b0;
         saw_downstream_w_stall_q <= 1'b0;
         saw_downstream_ar_stall_q <= 1'b0;
         write_resp_pending_q <= 1'b0;
         read_resp_pending_q <= 1'b0;
         saw_downstream_b_delay_q <= 1'b0;
         saw_downstream_r_delay_q <= 1'b0;

         source0_req_wait_q <= 1'b0;
         source1_req_wait_q <= 1'b0;
         downstream_aw_wait_q <= 1'b0;
         downstream_w_wait_q <= 1'b0;
         downstream_ar_wait_q <= 1'b0;
      end
      else begin
         if (!txn_active_q) begin
            if (source0_req_fire) begin
               txn_active_q <= 1'b1;
               txn_owner_q <= OWNER0;
            end
            else if (source1_req_fire) begin
               txn_active_q <= 1'b1;
               txn_owner_q <= OWNER1;
            end
         end
         else begin
            if ((txn_owner_q == OWNER0) && source0_rsp_fire && source0_rsp_last)
               txn_active_q <= 1'b0;
            else if ((txn_owner_q == OWNER1) && source1_rsp_fire && source1_rsp_last)
               txn_active_q <= 1'b0;
         end

         if (idle_arb_window && both_sources_read_request && !source1_req_ready)
            saw_source1_block_q <= 1'b1;
         else if (source1_req_fire)
            saw_source1_block_q <= 1'b0;

         if (downstream_aw_valid && !downstream_aw_ready)
            saw_downstream_aw_stall_q <= 1'b1;
         else if (downstream_aw_fire)
            saw_downstream_aw_stall_q <= 1'b0;

         if (downstream_w_valid && !downstream_w_ready)
            saw_downstream_w_stall_q <= 1'b1;
         else if (downstream_w_fire)
            saw_downstream_w_stall_q <= 1'b0;

         if (downstream_ar_valid && !downstream_ar_ready)
            saw_downstream_ar_stall_q <= 1'b1;
         else if (downstream_ar_fire)
            saw_downstream_ar_stall_q <= 1'b0;

         if (downstream_w_fire && downstream_w_last)
            write_resp_pending_q <= 1'b1;
         else if (downstream_b_fire)
            write_resp_pending_q <= 1'b0;

         if (downstream_ar_fire)
            read_resp_pending_q <= 1'b1;
         else if (downstream_r_fire && downstream_r_last)
            read_resp_pending_q <= 1'b0;

         if (write_resp_pending_q && !downstream_b_valid)
            saw_downstream_b_delay_q <= 1'b1;
         else if (downstream_b_fire)
            saw_downstream_b_delay_q <= 1'b0;

         if (read_resp_pending_q && !downstream_r_valid)
            saw_downstream_r_delay_q <= 1'b1;
         else if (downstream_r_fire)
            saw_downstream_r_delay_q <= 1'b0;

         source0_req_wait_q <= source0_req_valid && !source0_req_ready;
         source0_req_addr_q <= source0_req_addr;
         source0_req_data_q <= source0_req_data;
         source0_req_wen_q <= source0_req_wen;
         source0_req_mask_q <= source0_req_mask;
         source0_req_len_q <= source0_req_len;
         source0_req_size_q <= source0_req_size;
         source0_req_last_q <= source0_req_last;

         source1_req_wait_q <= source1_req_valid && !source1_req_ready;
         source1_req_addr_q <= source1_req_addr;
         source1_req_data_q <= source1_req_data;
         source1_req_wen_q <= source1_req_wen;
         source1_req_mask_q <= source1_req_mask;
         source1_req_len_q <= source1_req_len;
         source1_req_size_q <= source1_req_size;
         source1_req_last_q <= source1_req_last;

         downstream_aw_wait_q <= downstream_aw_valid && !downstream_aw_ready;
         downstream_aw_addr_q <= downstream_aw_addr;
         downstream_aw_len_q <= downstream_aw_len;
         downstream_aw_size_q <= downstream_aw_size;
         downstream_aw_burst_q <= downstream_aw_burst;
         downstream_aw_lock_q <= downstream_aw_lock;
         downstream_aw_cache_q <= downstream_aw_cache;
         downstream_aw_prot_q <= downstream_aw_prot;

         downstream_w_wait_q <= downstream_w_valid && !downstream_w_ready;
         downstream_w_data_q <= downstream_w_data;
         downstream_w_strb_q <= downstream_w_strb;
         downstream_w_last_q <= downstream_w_last;

         downstream_ar_wait_q <= downstream_ar_valid && !downstream_ar_ready;
         downstream_ar_addr_q <= downstream_ar_addr;
         downstream_ar_len_q <= downstream_ar_len;
         downstream_ar_size_q <= downstream_ar_size;
         downstream_ar_burst_q <= downstream_ar_burst;
         downstream_ar_lock_q <= downstream_ar_lock;
         downstream_ar_cache_q <= downstream_ar_cache;
         downstream_ar_prot_q <= downstream_ar_prot;
      end
   end

   amba_axi4_di_crossbar_arbitration_backpressure_properties phase4_properties (.*);

endmodule

module amba_axi4_di_crossbar_phase5_cover_observer (
   input wire        clock,
   input wire        reset,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire        source0_req_wen,
   input wire        source0_rsp_valid,
   input wire        source0_rsp_ready,
   input wire        source0_rsp_last,

   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire        source1_req_wen,
   input wire        source1_rsp_valid,
   input wire        source1_rsp_ready,
   input wire        source1_rsp_last,

   input wire        source0_b_valid,
   input wire        source0_b_ready,
   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire        source0_r_last,

   input wire        source1_b_valid,
   input wire        source1_b_ready,
   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire        source1_r_last,

   input wire        downstream_aw_valid,
   input wire        downstream_aw_ready,
   input wire [7:0]  downstream_aw_len,
   input wire        downstream_w_valid,
   input wire        downstream_w_ready,
   input wire        downstream_w_last,
   input wire        downstream_b_valid,
   input wire        downstream_b_ready,
   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire [7:0]  downstream_ar_len,
   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire        downstream_r_last
);

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source1_write_req_fire = source1_req_fire && source1_req_wen;
   wire source0_rsp_fire = source0_rsp_valid && source0_rsp_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;

   wire source0_b_fire = source0_b_valid && source0_b_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_b_fire = source1_b_valid && source1_b_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;

   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   reg pending_source0_read_q = 1'b0;
   reg pending_source1_read_q = 1'b0;
   reg pending_source1_write_q = 1'b0;
   reg saw_source1_write_aw_q = 1'b0;

   reg saw_source0_readback_q = 1'b0;
   reg saw_source1_readback_q = 1'b0;

   reg write_txn_active_q = 1'b0;
   reg write_wlast_seen_q = 1'b0;
   reg read_txn_active_q = 1'b0;

   reg write8_active_q = 1'b0;
   reg [3:0] write8_beat_count_q = 4'h0;
   reg read8_active_q = 1'b0;
   reg [3:0] read8_beat_count_q = 4'h0;
   wire starting_write8 = downstream_aw_fire && (downstream_aw_len == 8'd7);
   wire write8_counting = write8_active_q || starting_write8;
   wire [3:0] write8_beat_count_for_fire =
      (starting_write8 && !write8_active_q) ? 4'h0 : write8_beat_count_q;
   wire starting_read8 = downstream_ar_fire && (downstream_ar_len == 8'd7);
   wire read8_counting = read8_active_q || starting_read8;
   wire [3:0] read8_beat_count_for_fire =
      (starting_read8 && !read8_active_q) ? 4'h0 : read8_beat_count_q;

   always @(posedge clock) begin
      if (reset) begin
         pending_source0_read_q <= 1'b0;
         pending_source1_read_q <= 1'b0;
         pending_source1_write_q <= 1'b0;
         saw_source1_write_aw_q <= 1'b0;
         saw_source0_readback_q <= 1'b0;
         saw_source1_readback_q <= 1'b0;
         write_txn_active_q <= 1'b0;
         write_wlast_seen_q <= 1'b0;
         read_txn_active_q <= 1'b0;
         write8_active_q <= 1'b0;
         write8_beat_count_q <= 4'h0;
         read8_active_q <= 1'b0;
         read8_beat_count_q <= 4'h0;
      end
      else begin
         if (source0_read_req_fire)
            pending_source0_read_q <= 1'b1;
         else if (pending_source0_read_q && downstream_ar_fire)
            pending_source0_read_q <= 1'b0;

         if (source1_read_req_fire)
            pending_source1_read_q <= 1'b1;
         else if (pending_source1_read_q && downstream_ar_fire)
            pending_source1_read_q <= 1'b0;

         if (source1_write_req_fire)
            pending_source1_write_q <= 1'b1;
         if (pending_source1_write_q && downstream_aw_fire)
            saw_source1_write_aw_q <= 1'b1;
         if (pending_source1_write_q && saw_source1_write_aw_q &&
             downstream_w_fire && downstream_w_last) begin
            pending_source1_write_q <= 1'b0;
            saw_source1_write_aw_q <= 1'b0;
         end

         if (source0_r_fire && source0_r_last)
            saw_source0_readback_q <= 1'b1;
         if (source1_r_fire && source1_r_last)
            saw_source1_readback_q <= 1'b1;

         if (downstream_aw_fire) begin
            write_txn_active_q <= 1'b1;
            write_wlast_seen_q <= 1'b0;
            write8_active_q <= starting_write8;
            write8_beat_count_q <= 4'h0;
         end
         if (downstream_w_fire && (write_txn_active_q || downstream_aw_fire)) begin
            if (downstream_w_last)
               write_wlast_seen_q <= 1'b1;
            else if (write8_counting)
               write8_beat_count_q <= write8_beat_count_for_fire + 4'd1;
         end
         if (downstream_b_fire) begin
            write_txn_active_q <= 1'b0;
            write_wlast_seen_q <= 1'b0;
            write8_active_q <= 1'b0;
            write8_beat_count_q <= 4'h0;
         end

         if (downstream_ar_fire) begin
            read_txn_active_q <= 1'b1;
            read8_active_q <= starting_read8;
            read8_beat_count_q <= 4'h0;
         end
         if (downstream_r_fire && (read_txn_active_q || downstream_ar_fire)) begin
            if (downstream_r_last) begin
               read_txn_active_q <= 1'b0;
               read8_active_q <= 1'b0;
               read8_beat_count_q <= 4'h0;
            end
            else if (read8_counting) begin
               read8_beat_count_q <= read8_beat_count_for_fire + 4'd1;
            end
         end
      end
   end

   amba_axi4_di_crossbar_phase5_cover_properties phase5_properties (.*);

endmodule
