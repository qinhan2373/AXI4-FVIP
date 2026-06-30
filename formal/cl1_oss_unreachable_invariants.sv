`default_nettype none

module cl1_oss_source_driver_unreachable_invariants #(
   parameter int unsigned ID_WIDTH = 2,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter bit          READ_ONLY = 1'b0,
   parameter bit          NEVER_START = 1'b0
) (
   input wire                         clock,
   input wire                         reset,
   input wire                         traffic_started,
   input wire                         done,
   input wire [1:0]                   phase,
   input wire                         write_aw_done,
   input wire [3:0]                   write_req_beat,
   input wire [3:0]                   read_rsp_beat,
   input wire [3:0]                   write_burst_len,
   input wire [3:0]                   read_burst_len,
   input wire [1:0]                   write_axi_burst,
   input wire [1:0]                   read_axi_burst,
   input wire [ID_WIDTH-1:0]          write_axi_id,
   input wire [ID_WIDTH-1:0]          read_axi_id,
   input wire [3:0]                   write_axi_cache,
   input wire [3:0]                   read_axi_cache,
   input wire [2:0]                   write_axi_prot,
   input wire [2:0]                   read_axi_prot,
   input wire [ADDRESS_WIDTH-1:0]     up_aw_addr,
   input wire [7:0]                   up_aw_len,
   input wire [2:0]                   up_aw_size,
   input wire [ID_WIDTH-1:0]          m_write_dep_awid,
   input wire                         m_write_dep_aw_seen,
   input wire [ADDRESS_WIDTH-1:0]     m_write_dep_awaddr,
   input wire [7:0]                   m_write_dep_awlen,
   input wire [2:0]                   m_write_dep_awsize,
   input wire [1:0]                   m_write_dep_awburst,
   input wire [8:0]                   m_write_dep_w_count,
   input wire                         m_write_dep_w_seen,
   input wire                         m_write_dep_wlast_seen,
   input wire                         m_read_dep_ar_seen,
   input wire [ID_WIDTH-1:0]          m_read_dep_arid,
   input wire [7:0]                   m_read_dep_arlen,
   input wire [8:0]                   m_read_dep_r_count,
   input wire                         b_valid,
   input wire [ID_WIDTH-1:0]          b_id,
   input wire [1:0]                   b_resp,
   input wire                         r_valid,
   input wire [ID_WIDTH-1:0]          r_id,
   input wire [1:0]                   r_resp
);

   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [1:0] EXOKAY = amba_axi4_protocol_checker_pkg::EXOKAY;

   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
   localparam logic [1:0] PH_READ_REQ  = 2'd2;
   localparam logic [1:0] PH_READ_RSP  = 2'd3;

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_profile_write_len: assert (!write_burst_len[3]);
         inv_cl1_profile_read_len: assert (!read_burst_len[3]);
         inv_cl1_profile_write_burst: assert (write_axi_burst == INCR);
         inv_cl1_profile_read_burst: assert (read_axi_burst == INCR);
         inv_cl1_profile_write_id: assert (write_axi_id == '0);
         inv_cl1_profile_read_id: assert (read_axi_id == '0);
         inv_cl1_profile_write_cache: assert (write_axi_cache == 4'd0);
         inv_cl1_profile_read_cache: assert (read_axi_cache == 4'd0);
         inv_cl1_profile_write_prot: assert (write_axi_prot == 3'd0);
         inv_cl1_profile_read_prot: assert (read_axi_prot == 3'd0);
         inv_cl1_phase_range: assert (phase <= PH_READ_RSP);

         if (NEVER_START) begin
            inv_cl1_never_start_traffic_clear: assert (!traffic_started);
            inv_cl1_never_start_done_clear: assert (!done);
            inv_cl1_never_start_phase: assert (phase == PH_READ_REQ);
            inv_cl1_never_start_write_aw_done: assert (!write_aw_done);
            inv_cl1_never_start_write_beat: assert (write_req_beat == 4'd0);
            inv_cl1_never_start_read_beat: assert (read_rsp_beat == 4'd0);
            inv_cl1_never_start_no_write_dep: assert (!m_write_dep_aw_seen && !m_write_dep_w_seen && !m_write_dep_wlast_seen);
            inv_cl1_never_start_no_read_dep: assert (!m_read_dep_ar_seen);
            inv_cl1_never_start_no_bvalid: assert (!b_valid);
            inv_cl1_never_start_no_rvalid: assert (!r_valid);
         end

         if (!traffic_started) begin
            inv_cl1_pretraffic_phase:
               assert (phase == (READ_ONLY ? PH_READ_REQ : PH_WRITE_REQ));
            inv_cl1_pretraffic_aw_done: assert (!write_aw_done);
            inv_cl1_pretraffic_write_beat: assert (write_req_beat == 4'd0);
            inv_cl1_pretraffic_no_read_dep: assert (!m_read_dep_ar_seen);
            inv_cl1_pretraffic_no_bvalid: assert (!b_valid);
            inv_cl1_pretraffic_no_rvalid: assert (!r_valid);
         end

         if (READ_ONLY) begin
            inv_cl1_read_only_phase:
               assert ((phase == PH_READ_REQ) || (phase == PH_READ_RSP));
            inv_cl1_read_only_write_len_clear:
               assert (write_burst_len == 4'd0);
            inv_cl1_read_only_no_write_dep_aw:
               assert (!m_write_dep_aw_seen);
            inv_cl1_read_only_no_write_dep_w_seen:
               assert (!m_write_dep_w_seen);
            inv_cl1_read_only_no_write_dep_wlast_seen:
               assert (!m_write_dep_wlast_seen);
            inv_cl1_read_only_write_dep_count_clear:
               assert (m_write_dep_w_count == 9'd0);
         end

         if ((phase == PH_WRITE_REQ) || (phase == PH_WRITE_RSP)) begin
            inv_cl1_write_beat_in_range: assert (write_req_beat <= write_burst_len);
         end
         else begin
            inv_cl1_nonwrite_beat_zero: assert (write_req_beat == 4'd0);
            inv_cl1_nonwrite_aw_done_clear: assert (!write_aw_done);
         end

         if (!write_aw_done) begin
            inv_cl1_no_write_beat_before_aw: assert (write_req_beat == 4'd0);
         end

         if (phase == PH_WRITE_RSP) begin
            inv_cl1_write_rsp_after_aw: assert (write_aw_done);
            inv_cl1_write_rsp_after_last_beat: assert (write_req_beat == write_burst_len);
         end

         inv_cl1_master_write_dep_aw_seen_matches_tb:
            assert (m_write_dep_aw_seen == write_aw_done);

         if (m_write_dep_aw_seen) begin
            inv_cl1_master_write_dep_awid_matches_tb: assert (m_write_dep_awid == write_axi_id);
            inv_cl1_master_write_dep_awaddr_matches_tb: assert (m_write_dep_awaddr == up_aw_addr);
            inv_cl1_master_write_dep_awlen_matches_tb: assert (m_write_dep_awlen == up_aw_len);
            inv_cl1_master_write_dep_awsize_matches_tb: assert (m_write_dep_awsize == up_aw_size);
            inv_cl1_master_write_dep_awburst_matches_tb: assert (m_write_dep_awburst == write_axi_burst);
            inv_cl1_master_write_dep_w_count_matches_tb:
               assert (m_write_dep_w_count == {5'b0, write_req_beat});
            inv_cl1_master_write_dep_wlast_seen_matches_tb:
               assert (m_write_dep_wlast_seen == (phase == PH_WRITE_RSP));
            inv_cl1_master_write_dep_w_seen_matches_tb:
               assert (m_write_dep_w_seen ==
                       ((write_req_beat != 4'd0) || (phase == PH_WRITE_RSP)));
         end

         inv_cl1_master_read_dep_only_after_ar:
            assert (!m_read_dep_ar_seen || (phase == PH_READ_RSP));

         if (phase != PH_READ_RSP) begin
            inv_cl1_master_read_dep_clear_before_read_rsp:
               assert (!m_read_dep_ar_seen);
         end

         if (phase == PH_READ_RSP) begin
            inv_cl1_read_beat_in_range:
               assert (read_rsp_beat <= read_burst_len);
         end
         else begin
            inv_cl1_nonread_beat_zero:
               assert (read_rsp_beat == 4'd0);
         end

         if (m_read_dep_ar_seen) begin
            inv_cl1_master_read_dep_arid_matches_tb:
               assert (m_read_dep_arid == read_axi_id);
            inv_cl1_master_read_dep_arlen_matches_tb:
               assert (m_read_dep_arlen == {4'h0, read_burst_len});
            inv_cl1_master_read_dep_r_count_matches_tb:
               assert (m_read_dep_r_count == {5'b0, read_rsp_beat});
            inv_cl1_master_read_dep_count_in_range:
               assert (m_read_dep_r_count <= {5'b0, read_burst_len});
         end

         if (b_valid) begin
            inv_cl1_master_b_id_matches_profile:
               assert (b_id == write_axi_id);
            inv_cl1_master_b_no_exokay:
               assert (b_resp != EXOKAY);
         end

         if (r_valid) begin
            inv_cl1_master_r_id_matches_profile:
               assert (r_id == read_axi_id);
            inv_cl1_master_r_no_exokay:
               assert (r_resp != EXOKAY);
         end
      end
   end
endmodule

module cl1_oss_cachebus_len_unreachable_invariants (
   input wire       clock,
   input wire       reset,
   input wire       source0_req_valid,
   input wire [3:0] source0_req_len,
   input wire [1:0] source0_req_size,
   input wire       source1_req_valid,
   input wire [3:0] source1_req_len,
   input wire [1:0] source1_req_size,
   input wire [1:0] arbiter_state,
   input wire       arbiter_input_sel_0,
   input wire       arbiter_input_sel_1,
   input wire       arbiter_req_valid,
   input wire [3:0] arbiter_req_len,
   input wire [3:0] arbiter_req_mask,
   input wire [1:0] arbiter_req_size,
   input wire       arbiter_req_wen,
   input wire       buscut_buffer_valid,
   input wire [3:0] buscut_buffer_len,
   input wire [3:0] buscut_buffer_mask,
   input wire [1:0] buscut_buffer_size,
   input wire       buscut_buffer_wen,
   input wire       buscut_buffer_last,
   input wire       buscut_out_req_valid,
   input wire [3:0] buscut_out_req_len,
   input wire [3:0] buscut_out_req_mask,
   input wire [1:0] buscut_out_req_size,
   input wire       buscut_out_req_wen,
   input wire       buscut_out_req_last,
   input wire       bridge_write_burst_active,
   input wire       bridge_reqbuf_valid,
   input wire [3:0] bridge_reqbuf_len,
   input wire [3:0] bridge_reqbuf_mask,
   input wire [1:0] bridge_reqbuf_size,
   input wire       bridge_reqbuf_wen,
   input wire       bridge_reqbuf_last,
   input wire       bridge_pend_aw,
   input wire       bridge_pend_w,
   input wire       bridge_pend_ar,
   input wire       slave_seen_ar
);

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_cachebus_source0_req_len: assert (!source0_req_len[3]);
         inv_cl1_cachebus_source1_req_len: assert (!source1_req_len[3]);
         inv_cl1_cachebus_source0_req_size:
            assert (!source0_req_valid || (source0_req_size == 2'b10));
         inv_cl1_cachebus_source1_req_size:
            assert (!source1_req_valid || (source1_req_size == 2'b10));
         inv_cl1_cachebus_arbiter_state_range:
            assert (arbiter_state <= 2'd2);
         inv_cl1_cachebus_arbiter_sel_onehot:
            assert (!(arbiter_input_sel_0 && arbiter_input_sel_1));
         inv_cl1_cachebus_arbiter_req_len:
            assert (!arbiter_req_valid || !arbiter_req_len[3]);
         inv_cl1_cachebus_arbiter_req_mask:
            assert (!arbiter_req_valid || !arbiter_req_wen || (arbiter_req_mask == 4'hf));
         inv_cl1_cachebus_arbiter_req_size:
            assert (!arbiter_req_valid || (arbiter_req_size == 2'b10));
         inv_cl1_cachebus_buscut_buffer_len:
            assert (!buscut_buffer_valid || !buscut_buffer_len[3]);
         inv_cl1_cachebus_buscut_buffer_mask:
            assert (!buscut_buffer_valid || !buscut_buffer_wen || (buscut_buffer_mask == 4'hf));
         inv_cl1_cachebus_buscut_buffer_size:
            assert (!buscut_buffer_valid || (buscut_buffer_size == 2'b10));
         inv_cl1_cachebus_buscut_out_req_len:
            assert (!buscut_out_req_valid || !buscut_out_req_len[3]);
         inv_cl1_cachebus_buscut_out_req_mask:
            assert (!buscut_out_req_valid || !buscut_out_req_wen || (buscut_out_req_mask == 4'hf));
         inv_cl1_cachebus_buscut_out_req_size:
            assert (!buscut_out_req_valid || (buscut_out_req_size == 2'b10));
         inv_cl1_cachebus_bridge_multibeat_write_last_requires_active:
            assert (!buscut_out_req_valid || !buscut_out_req_wen ||
                    !buscut_out_req_last || (buscut_out_req_len == 4'd0) ||
                    bridge_write_burst_active);
         inv_cl1_cachebus_bridge_reqbuf_len:
            assert (!bridge_reqbuf_valid || !bridge_reqbuf_len[3]);
         inv_cl1_cachebus_bridge_reqbuf_mask:
            assert (!bridge_reqbuf_valid || !bridge_reqbuf_wen || (bridge_reqbuf_mask == 4'hf));
         inv_cl1_cachebus_bridge_reqbuf_size:
            assert (!bridge_reqbuf_valid || (bridge_reqbuf_size == 2'b10));
         inv_cl1_cachebus_bridge_reqbuf_direction:
            assert (!bridge_reqbuf_valid || (bridge_reqbuf_wen != bridge_pend_ar));
         inv_cl1_cachebus_bridge_reqbuf_has_pending_channel:
            assert (!bridge_reqbuf_valid || bridge_pend_aw || bridge_pend_w || bridge_pend_ar);
         inv_cl1_cachebus_bridge_reqbuf_pending_onehot:
            assert (!bridge_reqbuf_valid ||
                    (!(bridge_pend_aw && bridge_pend_w) &&
                     !(bridge_pend_aw && bridge_pend_ar) &&
                     !(bridge_pend_w && bridge_pend_ar)));
         inv_cl1_cachebus_bridge_write_reqbuf_pending:
            assert (!bridge_reqbuf_valid || !bridge_reqbuf_wen ||
                    (bridge_pend_aw || bridge_pend_w));
         inv_cl1_cachebus_bridge_read_reqbuf_pending:
            assert (!bridge_reqbuf_valid || bridge_reqbuf_wen || bridge_pend_ar);
         inv_cl1_cachebus_bridge_read_reqbuf_not_write_burst:
            assert (!bridge_reqbuf_valid || bridge_reqbuf_wen ||
                    !bridge_write_burst_active);
         inv_cl1_cachebus_bridge_pendar_not_write_burst:
            assert (!bridge_pend_ar || !bridge_write_burst_active);

         if (slave_seen_ar) begin
            inv_cl1_cachebus_no_arbiter_read_after_slave_ar:
               assert (!arbiter_req_valid || arbiter_req_wen);
            inv_cl1_cachebus_no_buscut_buffered_read_after_slave_ar:
               assert (!buscut_buffer_valid || buscut_buffer_wen);
            inv_cl1_cachebus_no_buscut_output_read_after_slave_ar:
               assert (!buscut_out_req_valid || buscut_out_req_wen);
            inv_cl1_cachebus_no_bridge_buffered_read_after_slave_ar:
               assert (!bridge_reqbuf_valid || bridge_reqbuf_wen);
            inv_cl1_cachebus_no_bridge_pendar_after_slave_ar:
               assert (!bridge_pend_ar);
         end
      end
   end
endmodule

module cl1_oss_axi4_to_cachebus_source_unreachable_invariants (
   input wire       clock,
   input wire       reset,
   input wire [1:0] source_phase,
   input wire       source_write_aw_done,
   input wire [3:0] source_write_req_beat,
   input wire [3:0] source_read_rsp_beat,
   input wire [3:0] source_write_burst_len,
   input wire [3:0] source_read_burst_len,
   input wire [31:0]                up_aw_addr,
   input wire [2:0] source_up_aw_size,
   input wire [2:0] bridge_state,
   input wire       bridge_aw_pending,
   input wire [31:0] bridge_aw_addr,
   input wire [7:0] bridge_aw_len,
   input wire [7:0] bridge_write_index,
   input wire [31:0] bridge_req_addr,
   input wire       bridge_w_buf_valid,
   input wire       bridge_w_buf_last,
   input wire       bridge_ar_pending,
   input wire [7:0] bridge_ar_len,
   input wire       bridge_rsp_last,
   input wire       bridge_in_rsp_valid,
   input wire       bridge_in_rsp_last,
   input wire       m_read_dep_ar_seen,
   input wire [7:0] m_read_dep_arlen,
   input wire [8:0] m_read_dep_r_count
);

   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
   localparam logic [1:0] PH_READ_REQ  = 2'd2;
   localparam logic [1:0] PH_READ_RSP  = 2'd3;

   localparam logic [2:0] ST_IDLE           = 3'd0;
   localparam logic [2:0] ST_WRITE_WAIT_W   = 3'd1;
   localparam logic [2:0] ST_WRITE_SEND_REQ = 3'd2;
   localparam logic [2:0] ST_WRITE_WAIT_B   = 3'd3;
   localparam logic [2:0] ST_WRITE_SEND_B   = 3'd4;
   localparam logic [2:0] ST_READ_SEND_REQ  = 3'd5;
   localparam logic [2:0] ST_READ_WAIT_RSP  = 3'd6;
   localparam logic [2:0] ST_READ_SEND_R    = 3'd7;

   wire bridge_write_context =
      (bridge_state == ST_WRITE_WAIT_W) ||
      (bridge_state == ST_WRITE_SEND_REQ) ||
      (bridge_state == ST_WRITE_WAIT_B) ||
      (bridge_state == ST_WRITE_SEND_B);

   wire bridge_aw_context_live =
      (bridge_state == ST_WRITE_WAIT_W) ||
      (bridge_state == ST_WRITE_SEND_REQ) ||
      (bridge_state == ST_WRITE_WAIT_B);

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_axi2cb_state_range: assert (bridge_state <= ST_READ_SEND_R);
         inv_cl1_axi2cb_write_index_range:
            assert (bridge_write_index <= {4'h0, source_write_burst_len});

         if (bridge_write_context) begin
            inv_cl1_axi2cb_write_context_matches_source_phase:
               assert ((source_phase == PH_WRITE_REQ) ||
                       (source_phase == PH_WRITE_RSP));
            inv_cl1_axi2cb_write_context_after_source_aw:
               assert (source_write_aw_done);
            inv_cl1_axi2cb_write_aw_len_matches_source:
               assert (bridge_aw_len == {4'h0, source_write_burst_len});
            inv_cl1_axi2cb_write_aw_addr_matches_source:
               assert (bridge_aw_addr == up_aw_addr);
         end

         if (bridge_aw_context_live) begin
            inv_cl1_axi2cb_write_aw_context_live:
               assert (bridge_aw_pending);
         end
         else begin
            inv_cl1_axi2cb_no_write_aw_context_outside_write_req:
               assert (!bridge_aw_pending);
         end

         if (bridge_w_buf_valid) begin
            inv_cl1_axi2cb_w_buf_only_during_send_req:
               assert (bridge_state == ST_WRITE_SEND_REQ);
            inv_cl1_axi2cb_w_buf_has_aw_context:
               assert (bridge_aw_pending);
            inv_cl1_axi2cb_w_buf_last_matches_source:
               assert (bridge_w_buf_last ==
                       (bridge_write_index == {4'h0, source_write_burst_len}));
         end

         if (bridge_state == ST_WRITE_SEND_REQ) begin
            inv_cl1_axi2cb_send_req_addr_matches_source:
               assert (bridge_req_addr ==
                       (up_aw_addr +
                        ({{24{1'b0}}, bridge_write_index} << source_up_aw_size)));
         end

         if (bridge_ar_pending ||
             (bridge_state == ST_READ_SEND_REQ) ||
             (bridge_state == ST_READ_WAIT_RSP) ||
             (bridge_state == ST_READ_SEND_R)) begin
            inv_cl1_axi2cb_read_state_matches_source:
               assert (source_phase == PH_READ_RSP);
            inv_cl1_axi2cb_ar_len_matches_source:
               assert (bridge_ar_len == {4'h0, source_read_burst_len});
            inv_cl1_axi2cb_read_state_has_checker_context:
               assert (m_read_dep_ar_seen);
            inv_cl1_axi2cb_read_dep_len_matches_bridge:
               assert (m_read_dep_arlen == bridge_ar_len);
            inv_cl1_axi2cb_read_dep_count_matches_source:
               assert (m_read_dep_r_count == {5'b0, source_read_rsp_beat});
         end

         if (bridge_state == ST_READ_SEND_R) begin
            inv_cl1_axi2cb_rdata_last_matches_source_count:
               assert (bridge_rsp_last ==
                       (source_read_rsp_beat == source_read_burst_len));
         end

         if ((bridge_state == ST_READ_WAIT_RSP) && bridge_in_rsp_valid) begin
            inv_cl1_axi2cb_input_rdata_last_matches_source_count:
               assert (bridge_in_rsp_last ==
                       (source_read_rsp_beat == source_read_burst_len));
         end

         if ((bridge_state == ST_WRITE_WAIT_W) ||
             (bridge_state == ST_WRITE_SEND_REQ) ||
             (bridge_state == ST_WRITE_WAIT_B) ||
             (bridge_state == ST_WRITE_SEND_B)) begin
            inv_cl1_axi2cb_write_state_has_aw:
               assert (source_write_aw_done || bridge_aw_pending);
         end

         if (bridge_state == ST_WRITE_SEND_REQ) begin
            inv_cl1_axi2cb_send_req_has_w_buf:
               assert (bridge_w_buf_valid);
            inv_cl1_axi2cb_send_req_index_matches_source:
               assert ((bridge_write_index == {4'h0, source_write_req_beat}) ||
                       (!bridge_w_buf_last &&
                        ((bridge_write_index + 8'h01) ==
                         {4'h0, source_write_req_beat})));
            inv_cl1_axi2cb_send_req_last_matches_source:
               assert (bridge_w_buf_last ==
                       (bridge_write_index == {4'h0, source_write_burst_len}));
         end
         else if ((bridge_state == ST_WRITE_WAIT_B) ||
                  (bridge_state == ST_WRITE_SEND_B) ||
                  (source_phase == PH_WRITE_RSP)) begin
            inv_cl1_axi2cb_completed_write_index_within_len:
               assert (bridge_write_index <= {4'h0, source_write_burst_len});
         end
      end
   end
endmodule

module cl1_oss_crossbar_write_pipeline_unreachable_invariants (
   input wire       clock,
   input wire       reset,
   input wire [1:0] source0_phase,
   input wire [3:0] source0_write_req_beat,
   input wire [3:0] source0_write_burst_len,
   input wire       source0_w_valid,
   input wire       source0_w_ready,
   input wire       source0_w_last,
   input wire [1:0] source1_phase,
   input wire [3:0] source1_write_req_beat,
   input wire [3:0] source1_write_burst_len,
   input wire       source1_w_valid,
   input wire       source1_w_ready,
   input wire       source1_w_last,
   input wire       source1_axi2cb_w_buf_valid,
   input wire       source1_axi2cb_w_buf_last,
   input wire       arbiter_input_sel_0,
   input wire       arbiter_input_sel_1,
   input wire       buscut_buffer_valid,
   input wire       buscut_buffer_last,
   input wire       buscut_rsp_buffer_valid,
   input wire       buscut_rsp_buffer_last,
   input wire       buscut_out_req_valid,
   input wire       buscut_out_req_ready,
   input wire       buscut_out_req_wen,
   input wire       buscut_out_req_last,
   input wire       bridge_reqbuf_valid,
   input wire       bridge_reqbuf_last,
   input wire       dn_w_valid,
   input wire       dn_w_ready,
   input wire       dn_w_last,
   input wire       dn_b_fire,
   input wire       slave_seen_aw,
   input wire [7:0] saved_aw_len,
   input wire [8:0] slave_write_beat_count
);

   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;

   wire source0_w_fire = source0_w_valid && source0_w_ready;
   wire source1_w_fire = source1_w_valid && source1_w_ready;
   wire source_nonlast_fire =
      (source0_w_fire && !source0_w_last) ||
      (source1_w_fire && !source1_w_last);
   wire downstream_nonlast_fire = dn_w_valid && dn_w_ready && !dn_w_last;
   wire buscut_out_write_fire =
      buscut_out_req_valid && buscut_out_req_ready && buscut_out_req_wen;

   wire [3:0] selected_write_req_beat =
      arbiter_input_sel_0 ? source0_write_req_beat : source1_write_req_beat;
   wire [3:0] selected_write_burst_len =
      arbiter_input_sel_0 ? source0_write_burst_len : source1_write_burst_len;
   wire [1:0] selected_phase =
      arbiter_input_sel_0 ? source0_phase : source1_phase;
   wire selected_write_context =
      slave_seen_aw && (arbiter_input_sel_0 || arbiter_input_sel_1) &&
      ((selected_phase == PH_WRITE_REQ) ||
       (selected_phase == PH_WRITE_RSP));
   wire [3:0] visible_nonlast_slots =
      {3'b000, (source1_w_valid && !source1_w_last)} +
      {3'b000, (source1_axi2cb_w_buf_valid && !source1_axi2cb_w_buf_last)} +
      {3'b000, (buscut_buffer_valid && !buscut_buffer_last)} +
      {3'b000, (buscut_out_req_valid && !buscut_out_req_last)} +
      {3'b000, (bridge_reqbuf_valid && !bridge_reqbuf_last)} +
      {3'b000, (dn_w_valid && !dn_w_last)};

   reg [3:0] pipe_nonlast_count_q = 4'd0;

   always @(posedge clock) begin
      if (reset || dn_b_fire) begin
         pipe_nonlast_count_q <= 4'd0;
      end
      else begin
         case ({source_nonlast_fire, downstream_nonlast_fire})
            2'b10: pipe_nonlast_count_q <= pipe_nonlast_count_q + 4'd1;
            2'b01: pipe_nonlast_count_q <= pipe_nonlast_count_q - 4'd1;
            default: pipe_nonlast_count_q <= pipe_nonlast_count_q;
         endcase
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_crossbar_write_pipe_count_range:
            assert (pipe_nonlast_count_q < 4'd8);
         inv_cl1_crossbar_write_pipe_count_has_storage:
            assert (pipe_nonlast_count_q <= visible_nonlast_slots);

         if (downstream_nonlast_fire && !source_nonlast_fire) begin
            inv_cl1_crossbar_write_pipe_no_underflow:
               assert (pipe_nonlast_count_q != 4'd0);
         end

         if (buscut_out_req_valid && buscut_out_req_wen &&
             buscut_out_req_last) begin
            inv_cl1_crossbar_buscut_last_no_pending_nonlast:
               assert (pipe_nonlast_count_q == 4'd0);
         end

         if (dn_w_valid && dn_w_last) begin
            inv_cl1_crossbar_downstream_last_no_pending_nonlast:
               assert (pipe_nonlast_count_q == 4'd0);
         end

         if (selected_write_context) begin
            inv_cl1_crossbar_selected_awlen_matches_source:
               assert (saved_aw_len == {4'h0, selected_write_burst_len});
         end

         if (buscut_out_write_fire && buscut_out_req_last) begin
            inv_cl1_crossbar_buscut_last_matches_selected_len:
               assert (!selected_write_context ||
                       (selected_write_req_beat ==
                        selected_write_burst_len));
         end
      end
   end
endmodule

module cl1_oss_crossbar_read_pipeline_unreachable_invariants (
   input wire       clock,
   input wire       reset,
   input wire       source0_r_valid,
   input wire       source0_r_ready,
   input wire       source0_r_last,
   input wire [3:0] source0_read_rsp_beat,
   input wire       source1_r_valid,
   input wire       source1_r_ready,
   input wire       source1_r_last,
   input wire [3:0] source1_read_rsp_beat,
   input wire       cb0_rsp_valid,
   input wire       cb0_rsp_last,
   input wire       cb1_rsp_valid,
   input wire       cb1_rsp_last,
   input wire       buscut_rsp_buffer_valid,
   input wire       buscut_rsp_buffer_last,
   input wire       dn_r_valid,
   input wire       dn_r_ready,
   input wire       dn_r_last,
   input wire       slave_seen_ar,
   input wire       s_read_dep_ar_seen,
   input wire [8:0] s_read_dep_r_count
);

   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire source_nonlast_fire =
      (source0_r_fire && !source0_r_last) ||
      (source1_r_fire && !source1_r_last);
   wire downstream_nonlast_fire = dn_r_valid && dn_r_ready && !dn_r_last;
   wire [3:0] visible_nonlast_slots =
      {3'b000, (dn_r_valid && !dn_r_last)} +
      {3'b000, (buscut_rsp_buffer_valid && !buscut_rsp_buffer_last)} +
      {3'b000, (cb0_rsp_valid && !cb0_rsp_last)} +
      {3'b000, (cb1_rsp_valid && !cb1_rsp_last)} +
      {3'b000, (source0_r_valid && !source0_r_last)} +
      {3'b000, (source1_r_valid && !source1_r_last)};

   reg [3:0] pipe_nonlast_count_q = 4'd0;

   always @(posedge clock) begin
      if (reset || !slave_seen_ar) begin
         pipe_nonlast_count_q <= 4'd0;
      end
      else begin
         case ({downstream_nonlast_fire, source_nonlast_fire})
            2'b10: pipe_nonlast_count_q <= pipe_nonlast_count_q + 4'd1;
            2'b01: pipe_nonlast_count_q <= pipe_nonlast_count_q - 4'd1;
            default: pipe_nonlast_count_q <= pipe_nonlast_count_q;
         endcase
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_crossbar_read_pipe_count_range:
            assert (pipe_nonlast_count_q < 4'd8);
         inv_cl1_crossbar_read_pipe_count_has_storage:
            assert (pipe_nonlast_count_q <= visible_nonlast_slots);

         if (source_nonlast_fire && !downstream_nonlast_fire) begin
            inv_cl1_crossbar_read_pipe_no_underflow:
               assert (pipe_nonlast_count_q != 4'd0);
         end

         if (s_read_dep_ar_seen) begin
            inv_cl1_crossbar_read_pipe_count_matches_observed_counts:
               assert (({5'b0, source0_read_rsp_beat} +
                        {5'b0, source1_read_rsp_beat} +
                        {5'b0, pipe_nonlast_count_q}) ==
                       s_read_dep_r_count);

            if (cb0_rsp_valid && !cb0_rsp_last) begin
               inv_cl1_crossbar_cb0_nonlast_is_pending:
                  assert (({5'b0, source0_read_rsp_beat} + 9'h001) <=
                          s_read_dep_r_count);
            end

            if (cb1_rsp_valid && !cb1_rsp_last) begin
               inv_cl1_crossbar_cb1_nonlast_is_pending:
                  assert (({5'b0, source1_read_rsp_beat} + 9'h001) <=
                          s_read_dep_r_count);
            end

            if (source0_r_valid && !source0_r_last) begin
               inv_cl1_crossbar_source0_nonlast_is_pending:
                  assert (({5'b0, source0_read_rsp_beat} + 9'h001) <=
                          s_read_dep_r_count);
            end

            if (source1_r_valid && !source1_r_last) begin
               inv_cl1_crossbar_source1_nonlast_is_pending:
                  assert (({5'b0, source1_read_rsp_beat} + 9'h001) <=
                          s_read_dep_r_count);
            end
         end

         if ((cb0_rsp_valid && cb0_rsp_last) ||
             (cb1_rsp_valid && cb1_rsp_last)) begin
            inv_cl1_crossbar_cb_rsp_last_no_pending_nonlast:
               assert (pipe_nonlast_count_q == 4'd0);
         end

         if ((source0_r_valid && source0_r_last) ||
             (source1_r_valid && source1_r_last)) begin
            inv_cl1_crossbar_source_r_last_no_pending_nonlast:
               assert (pipe_nonlast_count_q == 4'd0);
         end
      end
   end
endmodule

module cl1_oss_slave_model_unreachable_invariants #(
   parameter int unsigned ID_WIDTH = 2,
   parameter int unsigned ADDRESS_WIDTH = 32
) (
   input wire                clock,
   input wire                reset,
   input wire                no_slave_read_expected,
   input wire                slave_seen_aw,
   input wire                slave_seen_w,
   input wire                slave_seen_wlast,
   input wire                slave_seen_ar,
   input wire [ID_WIDTH-1:0] saved_aw_id,
   input wire [ID_WIDTH-1:0] saved_ar_id,
   input wire [ADDRESS_WIDTH-1:0] saved_aw_addr,
   input wire [7:0]          saved_aw_len,
   input wire [2:0]          saved_aw_size,
   input wire [1:0]          saved_aw_burst,
   input wire [8:0]          slave_write_beat_count,
   input wire [7:0]          read_beats_left,
   input wire [7:0]          dn_aw_len,
   input wire                dn_w_valid,
   input wire                dn_w_last,
   input wire                dn_b_valid,
   input wire [ID_WIDTH-1:0] dn_b_id,
   input wire                dn_ar_valid,
   input wire                dn_ar_ready,
   input wire                dn_r_valid,
   input wire                dn_r_last,
   input wire                slave_read_busy,
   input wire                s_write_dep_aw_seen,
   input wire [ID_WIDTH-1:0] s_write_dep_awid,
   input wire [ADDRESS_WIDTH-1:0] s_write_dep_awaddr,
   input wire [7:0]          s_write_dep_awlen,
   input wire [2:0]          s_write_dep_awsize,
   input wire [1:0]          s_write_dep_awburst,
   input wire [8:0]          s_write_dep_w_count,
   input wire                s_write_dep_w_seen,
   input wire                s_write_dep_wlast_seen,
   input wire                s_read_dep_ar_seen,
   input wire [ID_WIDTH-1:0] s_read_dep_arid,
   input wire [7:0]          s_read_dep_arlen,
   input wire [8:0]          s_read_dep_r_count
);

   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;

   always @(posedge clock) begin
      if (!reset) begin
         inv_cl1_slave_write_dep_aw_seen_matches_tb:
            assert (s_write_dep_aw_seen == slave_seen_aw);
         inv_cl1_slave_write_dep_w_seen_matches_tb:
            assert (s_write_dep_w_seen == slave_seen_w);
         inv_cl1_slave_write_dep_wlast_seen_matches_tb:
            assert (s_write_dep_wlast_seen == slave_seen_wlast);
         inv_cl1_slave_write_dep_w_count_matches_tb:
            assert (s_write_dep_w_count == slave_write_beat_count);

         if (s_write_dep_aw_seen) begin
            inv_cl1_slave_write_dep_awid_matches_tb:
               assert (s_write_dep_awid == saved_aw_id);
            inv_cl1_slave_write_dep_awaddr_matches_tb:
               assert (s_write_dep_awaddr == saved_aw_addr);
            inv_cl1_slave_write_dep_awlen_matches_tb:
               assert (s_write_dep_awlen == saved_aw_len);
            inv_cl1_slave_write_dep_awlen_matches_w_context:
               assert (!dn_w_valid || (s_write_dep_awlen == dn_aw_len));
            inv_cl1_slave_write_dep_awlen_within_cl1_max:
               assert (s_write_dep_awlen < 8'h08);
            inv_cl1_slave_write_dep_awsize_matches_tb:
               assert (s_write_dep_awsize == saved_aw_size);
            inv_cl1_slave_write_dep_awburst_matches_tb:
               assert (s_write_dep_awburst == saved_aw_burst);
         end

         if (slave_seen_aw) begin
            inv_cl1_slave_saved_awlen_within_cl1_max:
               assert (saved_aw_len < 8'h08);
            inv_cl1_slave_saved_awsize_matches_cl1:
               assert (saved_aw_size == 3'b010);
            inv_cl1_slave_saved_awburst_matches_cl1:
               assert (saved_aw_burst == INCR);
            inv_cl1_slave_write_count_within_saved_awlen:
               assert (slave_write_beat_count <= {1'b0, saved_aw_len});

            if (dn_w_valid) begin
               inv_cl1_slave_wlast_matches_saved_awlen:
                  assert (dn_w_last ==
                          (slave_write_beat_count == {1'b0, saved_aw_len}));
            end
         end

         if (slave_seen_wlast) begin
            inv_cl1_slave_wlast_count_matches_saved_awlen:
               assert (slave_write_beat_count == {1'b0, saved_aw_len});
         end

         inv_cl1_slave_read_dep_ar_seen_matches_tb:
            assert (s_read_dep_ar_seen == slave_seen_ar);

         if (s_read_dep_ar_seen) begin
            inv_cl1_slave_read_dep_arid_matches_tb:
               assert (s_read_dep_arid == saved_ar_id);
            inv_cl1_slave_read_dep_count_matches_tb:
               assert ((s_read_dep_r_count + {1'b0, read_beats_left}) ==
                       {1'b0, s_read_dep_arlen});
            inv_cl1_slave_read_dep_arlen_within_cl1_max:
               assert (s_read_dep_arlen < 8'h08);
         end

         if (dn_b_valid) begin
            inv_cl1_slave_bvalid_has_completed_write:
               assert (slave_seen_aw && slave_seen_wlast);
            inv_cl1_slave_bid_matches_saved_aw:
               assert (dn_b_id == saved_aw_id);
         end

         if (no_slave_read_expected) begin
            inv_cl1_no_slave_read_before_read_phase: assert (!dn_ar_valid && !dn_r_valid);
            inv_cl1_no_slave_read_state_before_read_phase: assert (!slave_seen_ar);
         end

         if (!slave_seen_ar && !dn_r_valid) begin
            inv_cl1_slave_read_idle_count_clear: assert (read_beats_left == 8'h00);
            inv_cl1_slave_read_idle_last_clear: assert (!dn_r_last);
         end
         else begin
            inv_cl1_slave_read_count_in_range: assert (read_beats_left < 8'h08);
         end

         if (dn_r_valid) begin
            inv_cl1_slave_read_valid_has_ar: assert (slave_seen_ar);
            inv_cl1_slave_read_last_matches_count: assert (dn_r_last == (read_beats_left == 8'h00));
         end

         if (slave_read_busy) begin
            inv_cl1_slave_read_backpressures_ar: assert (!dn_ar_ready);
         end
      end
   end
endmodule

`default_nettype wire
