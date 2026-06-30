// Generated from the source crossbar proof helper by flatten_crossbar_proof_helpers_oss.py.
// Proof-only interface ports are exposed as <instance>_if_<field> inputs.
`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

`ifdef AXI4_DI_CROSSBAR_ASSUME_PROOF_HELPERS
`define AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK assume
`define AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK assume
`else
`ifdef AXI4_DI_CROSSBAR_ASSUME_PROOF_HELPERS_WPATH_PREREQ
`define AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK assume
`else
`define AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK assert
`endif
`ifdef AXI4_DI_CROSSBAR_ASSUME_PROOF_HELPERS_READ_PIPE
`define AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK assume
`else
`define AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK assert
`endif
`endif

module amba_axi4_di_crossbar_cachebus_len_unreachable_invariants (
   input wire clock,
   input wire reset,
   input wire xbar_if_source0_req_valid,
   input wire [3:0] xbar_if_source0_req_len,
   input wire [1:0] xbar_if_source0_req_size,
   input wire xbar_if_source0_rsp_valid,
   input wire xbar_if_source0_rsp_last,
   input wire xbar_if_source1_req_valid,
   input wire [3:0] xbar_if_source1_req_len,
   input wire [1:0] xbar_if_source1_req_size,
   input wire xbar_if_source1_rsp_valid,
   input wire xbar_if_source1_rsp_last,
   input wire [1:0] xbar_if_arbiter_state,
   input wire xbar_if_arbiter_input_sel_0,
   input wire xbar_if_arbiter_input_sel_1,
   input wire xbar_if_arbiter_req_valid,
   input wire [3:0] xbar_if_arbiter_req_len,
   input wire [3:0] xbar_if_arbiter_req_mask,
   input wire [1:0] xbar_if_arbiter_req_size,
   input wire xbar_if_arbiter_req_wen,
   input wire xbar_if_buscut_buffer_valid,
   input wire [3:0] xbar_if_buscut_buffer_len,
   input wire [3:0] xbar_if_buscut_buffer_mask,
   input wire [1:0] xbar_if_buscut_buffer_size,
   input wire xbar_if_buscut_buffer_wen,
   input wire xbar_if_buscut_buffer_last,
   input wire xbar_if_buscut_rsp_buffer_valid,
   input wire xbar_if_buscut_rsp_buffer_last,
   input wire xbar_if_buscut_out_req_valid,
   input wire [3:0] xbar_if_buscut_out_req_len,
   input wire [3:0] xbar_if_buscut_out_req_mask,
   input wire [1:0] xbar_if_buscut_out_req_size,
   input wire xbar_if_buscut_out_req_wen,
   input wire xbar_if_buscut_out_req_last,
   input wire xbar_if_buscut_out_req_ready,
   input wire xbar_if_bridge_write_burst_active,
   input wire xbar_if_bridge_reqbuf_valid,
   input wire [3:0] xbar_if_bridge_reqbuf_len,
   input wire [3:0] xbar_if_bridge_reqbuf_mask,
   input wire [1:0] xbar_if_bridge_reqbuf_size,
   input wire xbar_if_bridge_reqbuf_wen,
   input wire xbar_if_bridge_reqbuf_last,
   input wire xbar_if_bridge_pend_aw,
   input wire xbar_if_bridge_pend_w,
   input wire xbar_if_bridge_pend_ar,
   input wire memory_if_write_aw_seen,
   input wire memory_if_write_wlast_seen,
   input wire [7:0] memory_if_saved_aw_len,
   input wire memory_if_read_active,
   input wire [7:0] memory_if_read_beat_index,
   input wire memory_if_read_targets_tracked_slot,
   input wire [31:0] memory_if_r_expected_word,
   input wire [31:0] memory_if_read_current_profile_word
);

   wire       source0_req_valid = xbar_if_source0_req_valid;
   wire [3:0] source0_req_len = xbar_if_source0_req_len;
   wire [1:0] source0_req_size = xbar_if_source0_req_size;
   wire       source1_req_valid = xbar_if_source1_req_valid;
   wire [3:0] source1_req_len = xbar_if_source1_req_len;
   wire [1:0] source1_req_size = xbar_if_source1_req_size;
   wire [1:0] arbiter_state = xbar_if_arbiter_state;
   wire       arbiter_input_sel_0 = xbar_if_arbiter_input_sel_0;
   wire       arbiter_input_sel_1 = xbar_if_arbiter_input_sel_1;
   wire       arbiter_req_valid = xbar_if_arbiter_req_valid;
   wire [3:0] arbiter_req_len = xbar_if_arbiter_req_len;
   wire [3:0] arbiter_req_mask = xbar_if_arbiter_req_mask;
   wire [1:0] arbiter_req_size = xbar_if_arbiter_req_size;
   wire       arbiter_req_wen = xbar_if_arbiter_req_wen;
   wire       buscut_buffer_valid = xbar_if_buscut_buffer_valid;
   wire [3:0] buscut_buffer_len = xbar_if_buscut_buffer_len;
   wire [3:0] buscut_buffer_mask = xbar_if_buscut_buffer_mask;
   wire [1:0] buscut_buffer_size = xbar_if_buscut_buffer_size;
   wire       buscut_buffer_wen = xbar_if_buscut_buffer_wen;
   wire       buscut_buffer_last = xbar_if_buscut_buffer_last;
   wire       buscut_out_req_valid = xbar_if_buscut_out_req_valid;
   wire [3:0] buscut_out_req_len = xbar_if_buscut_out_req_len;
   wire [3:0] buscut_out_req_mask = xbar_if_buscut_out_req_mask;
   wire [1:0] buscut_out_req_size = xbar_if_buscut_out_req_size;
   wire       buscut_out_req_wen = xbar_if_buscut_out_req_wen;
   wire       buscut_out_req_last = xbar_if_buscut_out_req_last;
   wire       bridge_write_burst_active = xbar_if_bridge_write_burst_active;
   wire       bridge_reqbuf_valid = xbar_if_bridge_reqbuf_valid;
   wire [3:0] bridge_reqbuf_len = xbar_if_bridge_reqbuf_len;
   wire [3:0] bridge_reqbuf_mask = xbar_if_bridge_reqbuf_mask;
   wire [1:0] bridge_reqbuf_size = xbar_if_bridge_reqbuf_size;
   wire       bridge_reqbuf_wen = xbar_if_bridge_reqbuf_wen;
   wire       bridge_reqbuf_last = xbar_if_bridge_reqbuf_last;
   wire       bridge_pend_aw = xbar_if_bridge_pend_aw;
   wire       bridge_pend_w = xbar_if_bridge_pend_w;
   wire       bridge_pend_ar = xbar_if_bridge_pend_ar;
   wire       downstream_read_active = memory_if_read_active;

   function automatic bit cachebus_size_in_profile(input logic [1:0] size);
      begin
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
         cachebus_size_in_profile = size <= 2'b10;
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
         cachebus_size_in_profile = size <= 2'b10;
`else
         cachebus_size_in_profile = size == 2'b10;
`endif
      end
   endfunction

   function automatic bit cachebus_write_mask_in_profile(
      input logic [3:0] mask,
      input logic [1:0] size
   );
      begin
`ifdef AXI4_DI_CROSSBAR_UNCACHE_SINGLE_BEAT
         case (size)
            2'b00:
               cachebus_write_mask_in_profile =
                  (mask == 4'b0001) || (mask == 4'b0010) ||
                  (mask == 4'b0100) || (mask == 4'b1000);
            2'b01:
               cachebus_write_mask_in_profile =
                  (mask == 4'b0011) || (mask == 4'b1100);
            2'b10:
               cachebus_write_mask_in_profile = mask == 4'b1111;
            default:
               cachebus_write_mask_in_profile = 1'b0;
         endcase
`elsif AXI4_DI_CROSSBAR_MIXED_SINGLE_BURST
         case (size)
            2'b00:
               cachebus_write_mask_in_profile =
                  (mask == 4'b0001) || (mask == 4'b0010) ||
                  (mask == 4'b0100) || (mask == 4'b1000);
            2'b01:
               cachebus_write_mask_in_profile =
                  (mask == 4'b0011) || (mask == 4'b1100);
            2'b10:
               cachebus_write_mask_in_profile = mask == 4'b1111;
            default:
               cachebus_write_mask_in_profile = 1'b0;
         endcase
`else
         cachebus_write_mask_in_profile = mask == 4'hf;
`endif
      end
   endfunction

   always @(posedge clock) begin
      if (!reset) begin
         inv_di_xbar_cachebus_source0_req_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!source0_req_valid || !source0_req_len[3]);
         inv_di_xbar_cachebus_source1_req_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!source1_req_valid || !source1_req_len[3]);
         inv_di_xbar_cachebus_source0_req_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!source0_req_valid || cachebus_size_in_profile(source0_req_size));
         inv_di_xbar_cachebus_source1_req_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!source1_req_valid || cachebus_size_in_profile(source1_req_size));
         inv_di_xbar_cachebus_arbiter_state_range:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(arbiter_state <= 2'd2);
         inv_di_xbar_cachebus_arbiter_sel_onehot:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!(arbiter_input_sel_0 && arbiter_input_sel_1));
         inv_di_xbar_cachebus_arbiter_req_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!arbiter_req_valid || !arbiter_req_len[3]);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         inv_di_xbar_cachebus_arbiter_req_mask:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!arbiter_req_valid || !arbiter_req_wen ||
                    cachebus_write_mask_in_profile(arbiter_req_mask, arbiter_req_size));
`endif
         inv_di_xbar_cachebus_arbiter_req_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!arbiter_req_valid || cachebus_size_in_profile(arbiter_req_size));
         inv_di_xbar_cachebus_buscut_buffer_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_buffer_valid || !buscut_buffer_len[3]);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         inv_di_xbar_cachebus_buscut_buffer_mask:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_buffer_valid || !buscut_buffer_wen ||
                    cachebus_write_mask_in_profile(buscut_buffer_mask, buscut_buffer_size));
`endif
         inv_di_xbar_cachebus_buscut_buffer_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_buffer_valid || cachebus_size_in_profile(buscut_buffer_size));
         inv_di_xbar_cachebus_buscut_out_req_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_out_req_valid || !buscut_out_req_len[3]);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         inv_di_xbar_cachebus_buscut_out_req_mask:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_out_req_valid || !buscut_out_req_wen ||
                    cachebus_write_mask_in_profile(buscut_out_req_mask, buscut_out_req_size));
`endif
         inv_di_xbar_cachebus_buscut_out_req_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_out_req_valid || cachebus_size_in_profile(buscut_out_req_size));
         inv_di_xbar_cachebus_bridge_multibeat_write_last_requires_active:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_out_req_valid || !buscut_out_req_wen ||
                    !buscut_out_req_last || (buscut_out_req_len == 4'd0) ||
                    bridge_write_burst_active);
         inv_di_xbar_cachebus_bridge_reqbuf_len:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || !bridge_reqbuf_len[3]);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB
         inv_di_xbar_cachebus_bridge_reqbuf_mask:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || !bridge_reqbuf_wen ||
                    cachebus_write_mask_in_profile(bridge_reqbuf_mask, bridge_reqbuf_size));
`endif
         inv_di_xbar_cachebus_bridge_reqbuf_size:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || cachebus_size_in_profile(bridge_reqbuf_size));
         inv_di_xbar_cachebus_bridge_reqbuf_direction:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || (bridge_reqbuf_wen != bridge_pend_ar));
         inv_di_xbar_cachebus_bridge_reqbuf_has_pending_channel:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid ||
                    bridge_pend_aw || bridge_pend_w || bridge_pend_ar);
         inv_di_xbar_cachebus_bridge_reqbuf_pending_onehot:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid ||
                    (!(bridge_pend_aw && bridge_pend_w) &&
                     !(bridge_pend_aw && bridge_pend_ar) &&
                     !(bridge_pend_w && bridge_pend_ar)));
         inv_di_xbar_cachebus_bridge_write_reqbuf_pending:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || !bridge_reqbuf_wen ||
                    bridge_pend_aw || bridge_pend_w);
         inv_di_xbar_cachebus_bridge_read_reqbuf_pending:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || bridge_reqbuf_wen || bridge_pend_ar);
         inv_di_xbar_cachebus_bridge_read_reqbuf_not_write_burst:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || bridge_reqbuf_wen ||
                    !bridge_write_burst_active);
         inv_di_xbar_cachebus_bridge_pendar_not_write_burst:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_pend_ar || !bridge_write_burst_active);

         if (downstream_read_active) begin
            inv_di_xbar_cachebus_no_arbiter_read_after_downstream_ar:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!arbiter_req_valid || arbiter_req_wen);
            inv_di_xbar_cachebus_no_buscut_buffered_read_after_downstream_ar:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_buffer_valid || buscut_buffer_wen);
            inv_di_xbar_cachebus_no_buscut_output_read_after_downstream_ar:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!buscut_out_req_valid || buscut_out_req_wen);
            inv_di_xbar_cachebus_no_bridge_buffered_read_after_downstream_ar:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_reqbuf_valid || bridge_reqbuf_wen);
            inv_di_xbar_cachebus_no_bridge_pendar_after_downstream_ar:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_pend_ar);
         end
      end
   end
endmodule

module amba_axi4_di_crossbar_axi4_to_cachebus_unreachable_invariants (
   input wire clock,
   input wire reset,
   input wire [1:0] source_if_phase,
   input wire source_if_write_aw_done,
   input wire [3:0] source_if_write_req_beat,
   input wire [3:0] source_if_read_rsp_beat,
   input wire [3:0] source_if_write_burst_len,
   input wire [3:0] source_if_read_burst_len,
   input wire [31:0] source_if_aw_addr,
   input wire [2:0] source_if_aw_size,
   input wire source_if_w_valid,
   input wire source_if_w_ready,
   input wire source_if_w_last,
   input wire source_if_r_valid,
   input wire source_if_r_ready,
   input wire source_if_r_last,
   input wire [2:0] bridge_if_state,
   input wire bridge_if_aw_pending,
   input wire [31:0] bridge_if_aw_addr,
   input wire [7:0] bridge_if_aw_len,
   input wire [7:0] bridge_if_write_index,
   input wire [31:0] bridge_if_req_addr,
   input wire bridge_if_w_buf_valid,
   input wire bridge_if_w_buf_last,
   input wire bridge_if_ar_pending,
   input wire [7:0] bridge_if_ar_len,
   input wire bridge_if_rsp_last,
   input wire bridge_if_in_rsp_valid,
   input wire bridge_if_in_rsp_last
);

   wire [1:0]  source_phase = source_if_phase;
   wire        source_write_aw_done = source_if_write_aw_done;
   wire [3:0]  source_write_req_beat = source_if_write_req_beat;
   wire [3:0]  source_read_rsp_beat = source_if_read_rsp_beat;
   wire [3:0]  source_write_burst_len = source_if_write_burst_len;
   wire [3:0]  source_read_burst_len = source_if_read_burst_len;
   wire [31:0] up_aw_addr = source_if_aw_addr;
   wire [2:0]  source_up_aw_size = source_if_aw_size;
   wire [2:0]  bridge_state = bridge_if_state;
   wire        bridge_aw_pending = bridge_if_aw_pending;
   wire [31:0] bridge_aw_addr = bridge_if_aw_addr;
   wire [7:0]  bridge_aw_len = bridge_if_aw_len;
   wire [7:0]  bridge_write_index = bridge_if_write_index;
   wire [31:0] bridge_req_addr = bridge_if_req_addr;
   wire        bridge_w_buf_valid = bridge_if_w_buf_valid;
   wire        bridge_w_buf_last = bridge_if_w_buf_last;
   wire        bridge_ar_pending = bridge_if_ar_pending;
   wire [7:0]  bridge_ar_len = bridge_if_ar_len;
   wire        bridge_rsp_last = bridge_if_rsp_last;
   wire        bridge_in_rsp_valid = bridge_if_in_rsp_valid;
   wire        bridge_in_rsp_last = bridge_if_in_rsp_last;

   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
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
         inv_di_xbar_axi2cb_state_range:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_state <= ST_READ_SEND_R);
         inv_di_xbar_axi2cb_write_index_range:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_write_index <= {4'h0, source_write_burst_len});

         if (bridge_write_context) begin
            inv_di_xbar_axi2cb_write_context_matches_source_phase:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK((source_phase == PH_WRITE_REQ) ||
                       (source_phase == PH_WRITE_RSP));
            inv_di_xbar_axi2cb_write_context_after_source_aw:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(source_write_aw_done);
            inv_di_xbar_axi2cb_write_aw_len_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_aw_len == {4'h0, source_write_burst_len});
            inv_di_xbar_axi2cb_write_aw_addr_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_aw_addr == up_aw_addr);
         end

         if (bridge_aw_context_live) begin
            inv_di_xbar_axi2cb_write_aw_context_live:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_aw_pending);
         end
         else begin
            inv_di_xbar_axi2cb_no_write_aw_context_outside_write_req:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!bridge_aw_pending);
         end

         if (bridge_w_buf_valid) begin
            inv_di_xbar_axi2cb_w_buf_only_during_send_req:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_state == ST_WRITE_SEND_REQ);
            inv_di_xbar_axi2cb_w_buf_has_aw_context:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_aw_pending);
            inv_di_xbar_axi2cb_w_buf_last_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_w_buf_last ==
                       (bridge_write_index == {4'h0, source_write_burst_len}));
         end

         if (bridge_state == ST_WRITE_SEND_REQ) begin
            inv_di_xbar_axi2cb_send_req_addr_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_req_addr ==
                       (up_aw_addr +
                        ({{24{1'b0}}, bridge_write_index} << source_up_aw_size)));
            inv_di_xbar_axi2cb_send_req_has_w_buf:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_w_buf_valid);
            inv_di_xbar_axi2cb_send_req_index_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK((bridge_write_index == {4'h0, source_write_req_beat}) ||
                       (!bridge_w_buf_last &&
                        ((bridge_write_index + 8'h01) ==
                         {4'h0, source_write_req_beat})));
            inv_di_xbar_axi2cb_send_req_last_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_w_buf_last ==
                       (bridge_write_index == {4'h0, source_write_burst_len}));
         end
         else if ((bridge_state == ST_WRITE_WAIT_B) ||
                  (bridge_state == ST_WRITE_SEND_B) ||
                  (source_phase == PH_WRITE_RSP)) begin
            inv_di_xbar_axi2cb_completed_write_index_within_len:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_write_index <= {4'h0, source_write_burst_len});
         end

         if (bridge_ar_pending ||
             (bridge_state == ST_READ_SEND_REQ) ||
             (bridge_state == ST_READ_WAIT_RSP) ||
             (bridge_state == ST_READ_SEND_R)) begin
            inv_di_xbar_axi2cb_read_state_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(source_phase == PH_READ_RSP);
            inv_di_xbar_axi2cb_ar_len_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_ar_len == {4'h0, source_read_burst_len});
         end

         if (bridge_state == ST_READ_SEND_R) begin
            inv_di_xbar_axi2cb_rdata_last_matches_source_count:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_rsp_last ==
                       (source_read_rsp_beat == source_read_burst_len));
         end

         if ((bridge_state == ST_READ_WAIT_RSP) && bridge_in_rsp_valid) begin
            inv_di_xbar_axi2cb_input_rdata_last_matches_source_count:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(bridge_in_rsp_last ==
                       (source_read_rsp_beat == source_read_burst_len));
         end

         if ((bridge_state == ST_WRITE_WAIT_W) ||
             (bridge_state == ST_WRITE_SEND_REQ) ||
             (bridge_state == ST_WRITE_WAIT_B) ||
             (bridge_state == ST_WRITE_SEND_B)) begin
            inv_di_xbar_axi2cb_write_state_has_aw:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(source_write_aw_done || bridge_aw_pending);
         end
      end
   end
endmodule

module amba_axi4_di_crossbar_write_pipeline_unreachable_invariants (
   input wire clock,
   input wire reset,
   input wire [1:0] source0_if_phase,
   input wire source0_if_write_aw_done,
   input wire [3:0] source0_if_write_req_beat,
   input wire [3:0] source0_if_read_rsp_beat,
   input wire [3:0] source0_if_write_burst_len,
   input wire [3:0] source0_if_read_burst_len,
   input wire [31:0] source0_if_aw_addr,
   input wire [2:0] source0_if_aw_size,
   input wire source0_if_w_valid,
   input wire source0_if_w_ready,
   input wire source0_if_w_last,
   input wire source0_if_r_valid,
   input wire source0_if_r_ready,
   input wire source0_if_r_last,
   input wire [1:0] source1_if_phase,
   input wire source1_if_write_aw_done,
   input wire [3:0] source1_if_write_req_beat,
   input wire [3:0] source1_if_read_rsp_beat,
   input wire [3:0] source1_if_write_burst_len,
   input wire [3:0] source1_if_read_burst_len,
   input wire [31:0] source1_if_aw_addr,
   input wire [2:0] source1_if_aw_size,
   input wire source1_if_w_valid,
   input wire source1_if_w_ready,
   input wire source1_if_w_last,
   input wire source1_if_r_valid,
   input wire source1_if_r_ready,
   input wire source1_if_r_last,
   input wire [2:0] source1_axi2cb_if_state,
   input wire source1_axi2cb_if_aw_pending,
   input wire [31:0] source1_axi2cb_if_aw_addr,
   input wire [7:0] source1_axi2cb_if_aw_len,
   input wire [7:0] source1_axi2cb_if_write_index,
   input wire [31:0] source1_axi2cb_if_req_addr,
   input wire source1_axi2cb_if_w_buf_valid,
   input wire source1_axi2cb_if_w_buf_last,
   input wire source1_axi2cb_if_ar_pending,
   input wire [7:0] source1_axi2cb_if_ar_len,
   input wire source1_axi2cb_if_rsp_last,
   input wire source1_axi2cb_if_in_rsp_valid,
   input wire source1_axi2cb_if_in_rsp_last,
   input wire xbar_if_source0_req_valid,
   input wire [3:0] xbar_if_source0_req_len,
   input wire [1:0] xbar_if_source0_req_size,
   input wire xbar_if_source0_rsp_valid,
   input wire xbar_if_source0_rsp_last,
   input wire xbar_if_source1_req_valid,
   input wire [3:0] xbar_if_source1_req_len,
   input wire [1:0] xbar_if_source1_req_size,
   input wire xbar_if_source1_rsp_valid,
   input wire xbar_if_source1_rsp_last,
   input wire [1:0] xbar_if_arbiter_state,
   input wire xbar_if_arbiter_input_sel_0,
   input wire xbar_if_arbiter_input_sel_1,
   input wire xbar_if_arbiter_req_valid,
   input wire [3:0] xbar_if_arbiter_req_len,
   input wire [3:0] xbar_if_arbiter_req_mask,
   input wire [1:0] xbar_if_arbiter_req_size,
   input wire xbar_if_arbiter_req_wen,
   input wire xbar_if_buscut_buffer_valid,
   input wire [3:0] xbar_if_buscut_buffer_len,
   input wire [3:0] xbar_if_buscut_buffer_mask,
   input wire [1:0] xbar_if_buscut_buffer_size,
   input wire xbar_if_buscut_buffer_wen,
   input wire xbar_if_buscut_buffer_last,
   input wire xbar_if_buscut_rsp_buffer_valid,
   input wire xbar_if_buscut_rsp_buffer_last,
   input wire xbar_if_buscut_out_req_valid,
   input wire [3:0] xbar_if_buscut_out_req_len,
   input wire [3:0] xbar_if_buscut_out_req_mask,
   input wire [1:0] xbar_if_buscut_out_req_size,
   input wire xbar_if_buscut_out_req_wen,
   input wire xbar_if_buscut_out_req_last,
   input wire xbar_if_buscut_out_req_ready,
   input wire xbar_if_bridge_write_burst_active,
   input wire xbar_if_bridge_reqbuf_valid,
   input wire [3:0] xbar_if_bridge_reqbuf_len,
   input wire [3:0] xbar_if_bridge_reqbuf_mask,
   input wire [1:0] xbar_if_bridge_reqbuf_size,
   input wire xbar_if_bridge_reqbuf_wen,
   input wire xbar_if_bridge_reqbuf_last,
   input wire xbar_if_bridge_pend_aw,
   input wire xbar_if_bridge_pend_w,
   input wire xbar_if_bridge_pend_ar,
   input wire memory_if_write_aw_seen,
   input wire memory_if_write_wlast_seen,
   input wire [7:0] memory_if_saved_aw_len,
   input wire memory_if_read_active,
   input wire [7:0] memory_if_read_beat_index,
   input wire memory_if_read_targets_tracked_slot,
   input wire [31:0] memory_if_r_expected_word,
   input wire [31:0] memory_if_read_current_profile_word,
   input wire dn_w_valid,
   input wire dn_w_ready,
   input wire dn_w_last,
   input wire dn_b_fire
);

   wire [1:0] source0_phase = source0_if_phase;
   wire [3:0] source0_write_req_beat = source0_if_write_req_beat;
   wire [3:0] source0_write_burst_len = source0_if_write_burst_len;
   wire       source0_w_valid = source0_if_w_valid;
   wire       source0_w_ready = source0_if_w_ready;
   wire       source0_w_last = source0_if_w_last;
   wire [1:0] source1_phase = source1_if_phase;
   wire [3:0] source1_write_req_beat = source1_if_write_req_beat;
   wire [3:0] source1_write_burst_len = source1_if_write_burst_len;
   wire       source1_w_valid = source1_if_w_valid;
   wire       source1_w_ready = source1_if_w_ready;
   wire       source1_w_last = source1_if_w_last;
   wire       source1_axi2cb_w_buf_valid = source1_axi2cb_if_w_buf_valid;
   wire       source1_axi2cb_w_buf_last = source1_axi2cb_if_w_buf_last;
   wire       arbiter_input_sel_0 = xbar_if_arbiter_input_sel_0;
   wire       arbiter_input_sel_1 = xbar_if_arbiter_input_sel_1;
   wire       buscut_buffer_valid = xbar_if_buscut_buffer_valid;
   wire       buscut_buffer_last = xbar_if_buscut_buffer_last;
   wire       buscut_out_req_valid = xbar_if_buscut_out_req_valid;
   wire       buscut_out_req_ready = xbar_if_buscut_out_req_ready;
   wire       buscut_out_req_wen = xbar_if_buscut_out_req_wen;
   wire       buscut_out_req_last = xbar_if_buscut_out_req_last;
   wire       bridge_reqbuf_valid = xbar_if_bridge_reqbuf_valid;
   wire       bridge_reqbuf_last = xbar_if_bridge_reqbuf_last;
   wire       downstream_write_aw_seen = memory_if_write_aw_seen;
   wire [7:0] downstream_saved_aw_len = memory_if_saved_aw_len;

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
      downstream_write_aw_seen && (arbiter_input_sel_0 || arbiter_input_sel_1) &&
      ((selected_phase == PH_WRITE_REQ) || (selected_phase == PH_WRITE_RSP));
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
         inv_di_xbar_write_pipe_count_range:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(pipe_nonlast_count_q < 4'd8);
         inv_di_xbar_write_pipe_count_has_storage:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(pipe_nonlast_count_q <= visible_nonlast_slots);

         if (downstream_nonlast_fire && !source_nonlast_fire) begin
            inv_di_xbar_write_pipe_no_underflow:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(pipe_nonlast_count_q != 4'd0);
         end

         if (buscut_out_req_valid && buscut_out_req_wen &&
             buscut_out_req_last) begin
            inv_di_xbar_buscut_last_no_pending_nonlast:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(pipe_nonlast_count_q == 4'd0);
         end

         if (dn_w_valid && dn_w_last) begin
            inv_di_xbar_downstream_last_no_pending_nonlast:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(pipe_nonlast_count_q == 4'd0);
         end

         if (selected_write_context) begin
            inv_di_xbar_selected_awlen_matches_source:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(downstream_saved_aw_len == {4'h0, selected_write_burst_len});
         end

         if (buscut_out_write_fire && buscut_out_req_last) begin
            inv_di_xbar_buscut_last_matches_selected_len:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK(!selected_write_context ||
                       (selected_write_req_beat == selected_write_burst_len));
         end
      end
   end
endmodule

module amba_axi4_di_crossbar_read_pipeline_unreachable_invariants (
   input wire clock,
   input wire reset,
   input wire [1:0] source0_if_phase,
   input wire source0_if_write_aw_done,
   input wire [3:0] source0_if_write_req_beat,
   input wire [3:0] source0_if_read_rsp_beat,
   input wire [3:0] source0_if_write_burst_len,
   input wire [3:0] source0_if_read_burst_len,
   input wire [31:0] source0_if_aw_addr,
   input wire [2:0] source0_if_aw_size,
   input wire source0_if_w_valid,
   input wire source0_if_w_ready,
   input wire source0_if_w_last,
   input wire source0_if_r_valid,
   input wire source0_if_r_ready,
   input wire source0_if_r_last,
   input wire [1:0] source1_if_phase,
   input wire source1_if_write_aw_done,
   input wire [3:0] source1_if_write_req_beat,
   input wire [3:0] source1_if_read_rsp_beat,
   input wire [3:0] source1_if_write_burst_len,
   input wire [3:0] source1_if_read_burst_len,
   input wire [31:0] source1_if_aw_addr,
   input wire [2:0] source1_if_aw_size,
   input wire source1_if_w_valid,
   input wire source1_if_w_ready,
   input wire source1_if_w_last,
   input wire source1_if_r_valid,
   input wire source1_if_r_ready,
   input wire source1_if_r_last,
   input wire xbar_if_source0_req_valid,
   input wire [3:0] xbar_if_source0_req_len,
   input wire [1:0] xbar_if_source0_req_size,
   input wire xbar_if_source0_rsp_valid,
   input wire xbar_if_source0_rsp_last,
   input wire xbar_if_source1_req_valid,
   input wire [3:0] xbar_if_source1_req_len,
   input wire [1:0] xbar_if_source1_req_size,
   input wire xbar_if_source1_rsp_valid,
   input wire xbar_if_source1_rsp_last,
   input wire [1:0] xbar_if_arbiter_state,
   input wire xbar_if_arbiter_input_sel_0,
   input wire xbar_if_arbiter_input_sel_1,
   input wire xbar_if_arbiter_req_valid,
   input wire [3:0] xbar_if_arbiter_req_len,
   input wire [3:0] xbar_if_arbiter_req_mask,
   input wire [1:0] xbar_if_arbiter_req_size,
   input wire xbar_if_arbiter_req_wen,
   input wire xbar_if_buscut_buffer_valid,
   input wire [3:0] xbar_if_buscut_buffer_len,
   input wire [3:0] xbar_if_buscut_buffer_mask,
   input wire [1:0] xbar_if_buscut_buffer_size,
   input wire xbar_if_buscut_buffer_wen,
   input wire xbar_if_buscut_buffer_last,
   input wire xbar_if_buscut_rsp_buffer_valid,
   input wire xbar_if_buscut_rsp_buffer_last,
   input wire xbar_if_buscut_out_req_valid,
   input wire [3:0] xbar_if_buscut_out_req_len,
   input wire [3:0] xbar_if_buscut_out_req_mask,
   input wire [1:0] xbar_if_buscut_out_req_size,
   input wire xbar_if_buscut_out_req_wen,
   input wire xbar_if_buscut_out_req_last,
   input wire xbar_if_buscut_out_req_ready,
   input wire xbar_if_bridge_write_burst_active,
   input wire xbar_if_bridge_reqbuf_valid,
   input wire [3:0] xbar_if_bridge_reqbuf_len,
   input wire [3:0] xbar_if_bridge_reqbuf_mask,
   input wire [1:0] xbar_if_bridge_reqbuf_size,
   input wire xbar_if_bridge_reqbuf_wen,
   input wire xbar_if_bridge_reqbuf_last,
   input wire xbar_if_bridge_pend_aw,
   input wire xbar_if_bridge_pend_w,
   input wire xbar_if_bridge_pend_ar,
   input wire memory_if_write_aw_seen,
   input wire memory_if_write_wlast_seen,
   input wire [7:0] memory_if_saved_aw_len,
   input wire memory_if_read_active,
   input wire [7:0] memory_if_read_beat_index,
   input wire memory_if_read_targets_tracked_slot,
   input wire [31:0] memory_if_r_expected_word,
   input wire [31:0] memory_if_read_current_profile_word,
   input wire dn_r_valid,
   input wire dn_r_ready,
   input wire dn_r_last
);

   wire       source0_r_valid = source0_if_r_valid;
   wire       source0_r_ready = source0_if_r_ready;
   wire       source0_r_last = source0_if_r_last;
   wire [3:0] source0_read_rsp_beat = source0_if_read_rsp_beat;
   wire       source1_r_valid = source1_if_r_valid;
   wire       source1_r_ready = source1_if_r_ready;
   wire       source1_r_last = source1_if_r_last;
   wire [3:0] source1_read_rsp_beat = source1_if_read_rsp_beat;
   wire       cb0_rsp_valid = xbar_if_source0_rsp_valid;
   wire       cb0_rsp_last = xbar_if_source0_rsp_last;
   wire       cb1_rsp_valid = xbar_if_source1_rsp_valid;
   wire       cb1_rsp_last = xbar_if_source1_rsp_last;
   wire       buscut_rsp_buffer_valid = xbar_if_buscut_rsp_buffer_valid;
   wire       buscut_rsp_buffer_last = xbar_if_buscut_rsp_buffer_last;
   wire       downstream_read_active = memory_if_read_active;

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
      if (reset) begin
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
         inv_di_xbar_read_pipe_count_range:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK(pipe_nonlast_count_q < 4'd8);
         inv_di_xbar_read_pipe_count_has_storage:
            `AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK(pipe_nonlast_count_q <= visible_nonlast_slots);

         if (source_nonlast_fire && !downstream_nonlast_fire) begin
            inv_di_xbar_read_pipe_no_underflow:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK(pipe_nonlast_count_q != 4'd0);
         end

`ifndef AXI4_DI_CROSSBAR_MIXED_TRANSITION
         if ((cb0_rsp_valid && cb0_rsp_last) ||
             (cb1_rsp_valid && cb1_rsp_last)) begin
            inv_di_xbar_cb_rsp_last_no_pending_nonlast:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK(pipe_nonlast_count_q == 4'd0);
         end
`endif

         if ((source0_r_valid && source0_r_last) ||
             (source1_r_valid && source1_r_last)) begin
            inv_di_xbar_source_r_last_no_pending_nonlast:
               `AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK(pipe_nonlast_count_q == 4'd0);
         end
      end
   end
endmodule

`undef AXI4_DI_CROSSBAR_PROOF_HELPER_WPATH_PREREQ_CHECK
`undef AXI4_DI_CROSSBAR_PROOF_HELPER_READ_PIPE_CHECK
