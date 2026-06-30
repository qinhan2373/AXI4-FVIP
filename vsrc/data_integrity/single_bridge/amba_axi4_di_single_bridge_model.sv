`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module amba_axi4_di_single_bridge_model (
   input wire        clock,
   input wire        reset,
   input wire        model_reset,
   input wire [31:0] initial_tracked_word,
   input wire [2:0]  tracked_beat,
   input wire [31:0] tracked_base,
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
   input wire        m_r_last,

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
   input wire        s_b_fire,
   input wire        s_ar_fire,
   input wire [31:0] s_ar_addr,
   input wire [7:0]  s_ar_len,
   input wire [2:0]  s_ar_size,
   input wire [1:0]  s_ar_burst,
   input wire [1:0]  s_ar_id,
   input wire        s_r_fire,
   input wire [31:0] s_r_data,
   input wire        s_r_last
);

   reg       di_active_q = 1'b0;
   reg [2:0] s_w_index_q = 3'h0;
   reg [2:0] s_r_index_q = 3'h0;
   reg [2:0] m_r_index_q = 3'h0;
   reg [31:0] s_tracked_r_data_q = 32'h0;
   reg        s_tracked_r_seen_q = 1'b0;
   reg [31:0] downstream_golden_tracked_word_q = 32'h0;
   reg        downstream_model_init_q = 1'b0;
   reg        downstream_tracked_write_seen_q = 1'b0;
   reg [31:0] committed_expected_tracked_word_q = 32'h0;
   reg        committed_expected_valid_q = 1'b0;

   wire [31:0] expected_committed_tracked_word =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         initial_tracked_word,
         source_tracked_write_data,
         source_tracked_write_strb);
   wire s_w_is_tracked_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         s_w_index_q, tracked_beat);
   wire s_r_is_tracked_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         s_r_index_q, tracked_beat);
   wire m_r_is_tracked_beat =
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(
         m_r_index_q, tracked_beat);

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         di_active_q <= 1'b0;
         s_w_index_q <= 3'h0;
         s_r_index_q <= 3'h0;
         m_r_index_q <= 3'h0;
         s_tracked_r_data_q <= 32'h0;
         s_tracked_r_seen_q <= 1'b0;
         downstream_golden_tracked_word_q <= 32'h0;
         downstream_model_init_q <= 1'b0;
         downstream_tracked_write_seen_q <= 1'b0;
         committed_expected_tracked_word_q <= 32'h0;
         committed_expected_valid_q <= 1'b0;
      end
      else begin
         if (model_reset) begin
            di_active_q <= 1'b0;
            s_w_index_q <= 3'h0;
            s_r_index_q <= 3'h0;
            m_r_index_q <= 3'h0;
            s_tracked_r_data_q <= 32'h0;
            s_tracked_r_seen_q <= 1'b0;
            downstream_golden_tracked_word_q <= 32'h0;
            downstream_model_init_q <= 1'b0;
            downstream_tracked_write_seen_q <= 1'b0;
            committed_expected_tracked_word_q <= 32'h0;
            committed_expected_valid_q <= 1'b0;
         end
         else begin
            di_active_q <= 1'b1;

            if (!downstream_model_init_q) begin
               downstream_golden_tracked_word_q <=
                  initial_tracked_word;
               downstream_model_init_q <= 1'b1;
            end
            else if (s_w_fire && s_w_is_tracked_beat) begin
               downstream_golden_tracked_word_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
                     downstream_golden_tracked_word_q,
                     s_w_data,
                     s_w_strb);
               committed_expected_tracked_word_q <=
                  expected_committed_tracked_word;
               committed_expected_valid_q <= 1'b1;
               downstream_tracked_write_seen_q <= 1'b1;
            end

            if (s_w_fire && s_w_last)
               s_w_index_q <= 3'h0;
            else if (s_w_fire)
               s_w_index_q <=
                  amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                     s_w_index_q);
            else if (s_aw_fire)
               s_w_index_q <= 3'h0;

            if (m_ar_fire) begin
               s_r_index_q <= 3'h0;
               m_r_index_q <= 3'h0;
               s_tracked_r_data_q <= 32'h0;
               s_tracked_r_seen_q <= 1'b0;
            end

            if (s_r_fire) begin
               if (s_r_is_tracked_beat) begin
                  s_tracked_r_data_q <= s_r_data;
                  s_tracked_r_seen_q <= 1'b1;
               end

               if (s_r_last)
                  s_r_index_q <= 3'h0;
               else
                  s_r_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        s_r_index_q);
            end

            if (m_r_fire) begin
               if (m_r_last)
                  m_r_index_q <= 3'h0;
               else
                  m_r_index_q <=
                     amba_axi4_data_integrity_pkg::axi4_di_next_beat_index3(
                        m_r_index_q);
            end
         end
      end
   end

   // OSS flow attaches properties explicitly because Yosys does not elaborate
   // the bind wrapper for this data-integrity model.
   amba_axi4_di_single_bridge_data_integrity_properties data_integrity_properties (
      .clock(clock),
      .reset(reset),
      .di_active_q(di_active_q),
      .s_w_index_q(s_w_index_q),
      .tracked_base(tracked_base),
      .tracked_beat(tracked_beat),
      .source_burst_len(source_burst_len),
      .source_transfer_size(source_transfer_size),
      .source_tracked_write_data(source_tracked_write_data),
      .source_tracked_write_strb(source_tracked_write_strb),
      .memory_tracked_word(memory_tracked_word),
      .observer_golden_tracked_word(observer_golden_tracked_word),
      .observer_expected_read_tracked_word(observer_expected_read_tracked_word),
      .observer_read_snapshot_valid(observer_read_snapshot_valid),
      .m_aw_fire(m_aw_fire),
      .m_w_fire(m_w_fire),
      .m_b_fire(m_b_fire),
      .m_ar_fire(m_ar_fire),
      .m_r_fire(m_r_fire),
      .m_r_data(m_r_data),
      .s_aw_fire(s_aw_fire),
      .s_aw_addr(s_aw_addr),
      .s_aw_len(s_aw_len),
      .s_aw_size(s_aw_size),
      .s_aw_burst(s_aw_burst),
      .s_aw_id(s_aw_id),
      .s_w_fire(s_w_fire),
      .s_w_data(s_w_data),
      .s_w_strb(s_w_strb),
      .s_w_last(s_w_last),
      .s_ar_fire(s_ar_fire),
      .s_ar_addr(s_ar_addr),
      .s_ar_len(s_ar_len),
      .s_ar_size(s_ar_size),
      .s_ar_burst(s_ar_burst),
      .s_ar_id(s_ar_id),
      .s_r_fire(s_r_fire),
      .s_r_data(s_r_data),
      .s_w_is_tracked_beat(s_w_is_tracked_beat),
      .s_r_is_tracked_beat(s_r_is_tracked_beat),
      .m_r_is_tracked_beat(m_r_is_tracked_beat),
      .s_tracked_r_data_q(s_tracked_r_data_q),
      .s_tracked_r_seen_q(s_tracked_r_seen_q),
      .downstream_golden_tracked_word_q(downstream_golden_tracked_word_q),
      .downstream_model_init_q(downstream_model_init_q),
      .downstream_tracked_write_seen_q(downstream_tracked_write_seen_q),
      .committed_expected_tracked_word_q(committed_expected_tracked_word_q),
      .committed_expected_valid_q(committed_expected_valid_q)
   );

endmodule

`default_nettype wire
