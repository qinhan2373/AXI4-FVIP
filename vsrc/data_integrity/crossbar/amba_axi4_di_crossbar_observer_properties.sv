`default_nettype none

module amba_axi4_di_crossbar_symbolic_addr_properties (
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

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source1_write_req_fire = source1_req_fire && source1_req_wen;
   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;

   function automatic bit in_symbolic_window(input logic [31:0] addr);
      in_symbolic_window =
         amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(
            cfg_shared_addr, addr);
   endfunction

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_symbolic_source0_read_addr_matches_cfg:
            assert (!source0_read_req_fire || in_symbolic_window(source0_req_addr));
         ap_di_xbar_symbolic_source1_read_addr_matches_cfg:
            assert (!source1_read_req_fire || in_symbolic_window(source1_req_addr));
         ap_di_xbar_symbolic_source1_write_addr_matches_cfg:
            assert (!source1_write_req_fire || in_symbolic_window(source1_req_addr));
         ap_di_xbar_symbolic_downstream_awaddr_matches_cfg:
            assert (!downstream_aw_fire || in_symbolic_window(downstream_aw_addr));
         ap_di_xbar_symbolic_downstream_araddr_matches_cfg:
            assert (!downstream_ar_fire || in_symbolic_window(downstream_ar_addr));

         cv_di_xbar_symbolic_addr_high_nonzero:
            cover (source1_write_req_fire && (cfg_shared_addr[31:12] != 20'h0));
         cv_di_xbar_symbolic_source0_read_nondefault_addr:
            cover (source0_read_req_fire && (cfg_shared_addr != 32'h0000_1000));
         cv_di_xbar_symbolic_source1_write_nondefault_addr:
            cover (source1_write_req_fire && (cfg_shared_addr != 32'h0000_1000));
         cv_di_xbar_symbolic_downstream_aw_nondefault_addr:
            cover (downstream_aw_fire && (downstream_aw_addr != 32'h0000_1000));
         cv_di_xbar_symbolic_downstream_ar_nondefault_addr:
            cover (downstream_ar_fire && (downstream_ar_addr != 32'h0000_1000));
      end
   end
endmodule


module amba_axi4_di_crossbar_symbolic_wdata_properties (
   input wire        clock,
   input wire        reset,

   input wire        source1_w_valid,
   input wire        source1_w_ready,
   input wire [31:0] source1_w_data,
   input wire [3:0]  source1_w_strb,
   input wire        source1_w_last,
   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire        source0_r_last,
   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire        source1_r_last,
   input wire        downstream_w_valid,
   input wire        downstream_w_ready,
   input wire [31:0] downstream_w_data,
   input wire [3:0]  downstream_w_strb,
   input wire        downstream_w_last,
   input wire        downstream_ar_valid,
   input wire        downstream_ar_ready,
   input wire        downstream_r_valid,
   input wire        downstream_r_ready,

   input wire        source_w_wait_q,
   input wire [31:0] source_w_data_q,
   input wire [3:0]  source_w_strb_q,
   input wire        source_w_last_q,
   input wire        expected_w_fifo_full,
   input wire        expected_w_valid,
   input wire [31:0] expected_w_data,
   input wire [3:0]  expected_w_strb,
   input wire        expected_w_last,
   input wire        write_check_pending_q,
   input wire [31:0] write_check_actual_word,
   input wire [31:0] write_check_expected_q,
   input wire        read_owner_now_valid,
   input wire        active_read_valid_q,
   input wire        active_read_owner_q,
   input wire        source0_expected_fifo_full,
   input wire        source1_expected_fifo_full,
   input wire        source0_expected_valid,
   input wire        source0_expected_last,
   input wire        source1_expected_valid,
   input wire        source1_expected_last,
   input wire        saw_distinct_wdata_q,
   input wire        saw_downstream_write_q
);

   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;

   wire source1_w_fire = source1_w_valid && source1_w_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_symbolic_wdata_stable_when_stalled:
            assert (!source_w_wait_q ||
                    (source1_w_valid &&
                     source1_w_data == source_w_data_q &&
                     source1_w_strb == source_w_strb_q &&
                     source1_w_last == source_w_last_q));
         ap_di_xbar_symbolic_wdata_fifo_no_overflow:
            assert (!(source1_w_fire && !downstream_w_fire && expected_w_fifo_full));
         ap_di_xbar_symbolic_source_to_downstream_wdata:
            assert (!downstream_w_fire || (expected_w_valid && downstream_w_data == expected_w_data));
         ap_di_xbar_symbolic_source_to_downstream_wstrb:
            assert (!downstream_w_fire || (expected_w_valid && downstream_w_strb == expected_w_strb));
         ap_di_xbar_symbolic_source_to_downstream_wlast:
            assert (!downstream_w_fire || (expected_w_valid && downstream_w_last == expected_w_last));
         ap_di_xbar_symbolic_commit_data_matches_observer:
            assert (!write_check_pending_q ||
                    (write_check_actual_word == write_check_expected_q));
         ap_di_xbar_symbolic_downstream_ar_has_read_owner:
            assert (!downstream_ar_fire || read_owner_now_valid);
         ap_di_xbar_symbolic_downstream_r_has_active_snapshot:
            assert (!downstream_r_fire || active_read_valid_q);
         ap_di_xbar_symbolic_source0_readback_fifo_no_overflow:
            assert (!(downstream_r_fire && active_read_valid_q &&
                      (active_read_owner_q == OWNER0) && !source0_r_fire &&
                      source0_expected_fifo_full));
         ap_di_xbar_symbolic_source1_readback_fifo_no_overflow:
            assert (!(downstream_r_fire && active_read_valid_q &&
                      (active_read_owner_q == OWNER1) && !source1_r_fire &&
                      source1_expected_fifo_full));
         ap_di_xbar_symbolic_source0_readback_last_matches_expected:
            assert (!source0_r_fire ||
                    (source0_expected_valid && source0_r_last == source0_expected_last));
         ap_di_xbar_symbolic_source1_readback_last_matches_expected:
            assert (!source1_r_fire ||
                    (source1_expected_valid && source1_r_last == source1_expected_last));
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_symbolic_wdata_nonzero:
            cover (source1_w_fire && source1_w_data != 32'h0);
         cv_di_xbar_symbolic_wdata_byte_variation:
            cover (source1_w_fire && source1_w_data[7:0] != source1_w_data[15:8]);
         cv_di_xbar_symbolic_wdata_multi_beat_distinct:
            cover (saw_distinct_wdata_q);
         cv_di_xbar_symbolic_wdata_downstream_write:
            cover (downstream_w_fire && expected_w_valid &&
                   downstream_w_data == expected_w_data);
         cv_di_xbar_symbolic_wdata_source0_readback_after_write:
            cover (saw_downstream_write_q && source0_r_fire && source0_r_last);
         cv_di_xbar_symbolic_wdata_source1_readback_after_write:
            cover (saw_downstream_write_q && source1_r_fire && source1_r_last);
      end
   end
endmodule


module amba_axi4_di_crossbar_symbolic_wstrb_properties (
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
   input wire       downstream_w_last,

   input wire       source_w_wait_q,
   input wire [3:0] source_w_strb_q,
   input wire       source_w_last_q,
   input wire       expected_w_fifo_full,
   input wire       expected_w_valid,
   input wire [3:0] expected_w_strb,
   input wire       expected_w_last,
   input wire       expected_wstrb_partial,
   input wire       saw_partial_downstream_wstrb_q,
   input wire       saw_8beat_partial_wstrb_q
);

   wire source1_w_fire = source1_w_valid && source1_w_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_symbolic_wstrb_stable_when_stalled:
            assert (!source_w_wait_q ||
                    (source1_w_valid &&
                     source1_w_strb == source_w_strb_q &&
                     source1_w_last == source_w_last_q));
         ap_di_xbar_symbolic_wstrb_fifo_no_overflow:
            assert (!(source1_w_fire && !downstream_w_fire && expected_w_fifo_full));
         ap_di_xbar_symbolic_wstrb_source_to_downstream:
            assert (!downstream_w_fire || (expected_w_valid && downstream_w_strb == expected_w_strb));
         ap_di_xbar_symbolic_wstrb_wlast_alignment:
            assert (!downstream_w_fire || (expected_w_valid && downstream_w_last == expected_w_last));
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_symbolic_wstrb_zero:
            cover (source1_w_fire && source1_w_strb == 4'b0000);
         cv_di_xbar_symbolic_wstrb_single:
            cover (source1_w_fire && source1_w_strb == 4'b0001);
         cv_di_xbar_symbolic_wstrb_partial:
            cover (source1_w_fire && source1_w_strb == 4'b0101);
         cv_di_xbar_symbolic_wstrb_full:
            cover (source1_w_fire && source1_w_strb == 4'b1111);
         cv_di_xbar_symbolic_wstrb_downstream_partial:
            cover (downstream_w_fire && expected_w_valid && expected_wstrb_partial &&
                   downstream_w_strb == expected_w_strb);
         cv_di_xbar_symbolic_wstrb_partial_8beat_readback:
            cover (saw_8beat_partial_wstrb_q && saw_partial_downstream_wstrb_q &&
                   source1_r_fire && source1_r_last);
      end
   end
endmodule


module amba_axi4_di_crossbar_owner_scoreboard_properties (
   input wire        clock,
   input wire        reset,
   input wire [31:0] cfg_source0_write_addr,
   input wire [31:0] cfg_source0_read_addr,
   input wire [31:0] cfg_source1_write_addr,
   input wire [31:0] cfg_source1_read_addr,

   input wire        source0_req_valid,
   input wire        source0_req_ready,
   input wire [31:0] source0_req_addr,
   input wire        source0_req_wen,
   input wire        source0_rsp_valid,
   input wire        source0_rsp_ready,
   input wire        source0_rsp_last,
   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire [31:0] source1_req_addr,
   input wire        source1_req_wen,
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

   input wire        write_path_owner_valid,
   input wire        write_path_owner,
   input wire        write_path_last_seen,
   input wire        read_path_owner_valid,
   input wire        read_path_owner,
   input wire        source0_b_pending,
   input wire        source1_b_pending,
   input wire        source0_r_pending,
   input wire        source1_r_pending,
   input wire        source0_r_pending_last,
   input wire        source1_r_pending_last,
   input wire        write_owner_now_valid,
   input wire        write_owner_now,
   input wire        read_owner_now_valid,
   input wire        read_owner_now
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

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_route_no_dual_req_accept:
            assert (!(source0_req_fire && source1_req_fire));
         ap_di_xbar_route_single_active_direction:
            assert (!(write_path_owner_valid && read_path_owner_valid));

         ap_di_xbar_route_write_source0_addr:
            assert (!source0_write_req_fire || (source0_req_addr[31:12] == cfg_source0_write_addr[31:12]));
         ap_di_xbar_route_write_source1_addr:
            assert (!source1_write_req_fire || (source1_req_addr[31:12] == cfg_source1_write_addr[31:12]));
         ap_di_xbar_route_read_source0_addr:
            assert (!source0_read_req_fire || (source0_req_addr == cfg_source0_read_addr));
         ap_di_xbar_route_read_source1_addr:
            assert (!source1_read_req_fire || (source1_req_addr == cfg_source1_read_addr));

         ap_di_xbar_route_write_source_consistent:
            assert (!write_path_owner_valid ||
                    !(source0_write_req_fire && (write_path_owner == OWNER1)) &&
                    !(source1_write_req_fire && (write_path_owner == OWNER0)));
         ap_di_xbar_route_read_source_consistent:
            assert (!read_path_owner_valid ||
                    !(source0_read_req_fire && (read_path_owner == OWNER1)) &&
                    !(source1_read_req_fire && (read_path_owner == OWNER0)));

         ap_di_xbar_route_downstream_aw_has_owner:
            assert (!downstream_aw_fire || write_owner_now_valid);
         ap_di_xbar_route_downstream_aw_matches_owner_page:
            assert (!downstream_aw_fire ||
                    (!write_owner_now && downstream_aw_addr[31:12] == cfg_source0_write_addr[31:12]) ||
                    ( write_owner_now && downstream_aw_addr[31:12] == cfg_source1_write_addr[31:12]));
         ap_di_xbar_route_downstream_w_has_owner:
            assert (!downstream_w_fire || write_owner_now_valid);
`ifndef AXI4_DI_CROSSBAR_SYMBOLIC_WDATA
         ap_di_xbar_route_downstream_w_matches_owner_page:
            assert (!downstream_w_fire ||
                    (!write_owner_now && downstream_w_data[31:12] == cfg_source0_write_addr[31:12]) ||
                    ( write_owner_now && downstream_w_data[31:12] == cfg_source1_write_addr[31:12]));
`endif
         ap_di_xbar_route_downstream_b_has_owner:
            assert (!downstream_b_fire || (write_path_owner_valid && write_path_last_seen));

         ap_di_xbar_route_downstream_ar_has_owner:
            assert (!downstream_ar_fire || read_owner_now_valid);
         ap_di_xbar_route_downstream_ar_matches_owner:
            assert (!downstream_ar_fire ||
                    (!read_owner_now && downstream_ar_addr == cfg_source0_read_addr) ||
                    ( read_owner_now && downstream_ar_addr == cfg_source1_read_addr));
         ap_di_xbar_route_downstream_r_has_owner:
            assert (!downstream_r_fire || read_path_owner_valid);

         ap_di_xbar_route_source0_rsp_return:
            assert (!source0_rsp_valid ||
                    (write_path_owner_valid && (write_path_owner == OWNER0)) ||
                    (read_path_owner_valid && (read_path_owner == OWNER0)));
         ap_di_xbar_route_source1_rsp_return:
            assert (!source1_rsp_valid ||
                    (write_path_owner_valid && (write_path_owner == OWNER1)) ||
                    (read_path_owner_valid && (read_path_owner == OWNER1)));
         ap_di_xbar_route_write_rsp_is_last:
            assert (!(write_path_owner_valid &&
                      ((source0_rsp_fire && (write_path_owner == OWNER0)) ||
                       (source1_rsp_fire && (write_path_owner == OWNER1)))) ||
                    ((write_path_owner == OWNER0) ? source0_rsp_last : source1_rsp_last));

         ap_di_xbar_route_no_dual_b_return:
            assert (!(source0_b_valid && source1_b_valid));
         ap_di_xbar_route_no_dual_r_return:
            assert (!(source0_r_valid && source1_r_valid));
         ap_di_xbar_route_source0_b_return:
            assert (!source0_b_valid || source0_b_pending);
         ap_di_xbar_route_source1_b_return:
            assert (!source1_b_valid || source1_b_pending);
         ap_di_xbar_route_source0_r_return:
            assert (!source0_r_valid || source0_r_pending);
         ap_di_xbar_route_source1_r_return:
            assert (!source1_r_valid || source1_r_pending);
         ap_di_xbar_route_source0_r_last_return:
            assert (!source0_r_valid || (source0_r_last == source0_r_pending_last));
         ap_di_xbar_route_source1_r_last_return:
            assert (!source1_r_valid || (source1_r_last == source1_r_pending_last));
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_route_source0_write_return:
            cover (source0_b_fire && source0_b_pending);
         cv_di_xbar_route_source1_write_return:
            cover (source1_b_fire && source1_b_pending);
         cv_di_xbar_route_source0_read_return:
            cover (source0_r_fire && source0_r_last && source0_r_pending);
         cv_di_xbar_route_source1_read_return:
            cover (source1_r_fire && source1_r_last && source1_r_pending);
      end
   end
endmodule


module amba_axi4_di_crossbar_source_readback_properties #(
   parameter int unsigned FIFO_DEPTH = 8
) (
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
   input wire        downstream_r_valid,
   input wire        downstream_r_ready,
   input wire        downstream_r_last,
   input wire        source0_r_valid,
   input wire        source0_r_ready,
   input wire [31:0] source0_r_data,
   input wire        source0_r_last,
   input wire        source1_r_valid,
   input wire        source1_r_ready,
   input wire [31:0] source1_r_data,
   input wire        source1_r_last,

   input wire        read_owner_valid,
   input wire        read_owner,
   input wire        read_owner_complete,
   input wire [3:0]  downstream_fifo_count,
   input wire        downstream_expected_valid,
   input wire        downstream_expected_owner,
   input wire        downstream_expected_last,
   input wire [3:0]  source0_fifo_count,
   input wire        source0_expected_valid,
   input wire [31:0] source0_expected_data,
   input wire        source0_expected_last,
   input wire [3:0]  source1_fifo_count,
   input wire        source1_expected_valid,
   input wire [31:0] source1_expected_data,
   input wire        source1_expected_last
);

   localparam logic OWNER0 = 1'b0;
   localparam logic OWNER1 = 1'b1;
   localparam logic [3:0] FIFO_DEPTH_COUNT = 4'(FIFO_DEPTH);

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire source0_read_req_fire = source0_req_fire && !source0_req_wen;
   wire source1_read_req_fire = source1_req_fire && !source1_req_wen;
   wire source0_rsp_fire = source0_rsp_valid && source0_rsp_ready;
   wire source1_rsp_fire = source1_rsp_valid && source1_rsp_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;
   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire source0_read_rsp_fire =
      source0_rsp_fire && read_owner_valid && (read_owner == OWNER0);
   wire source1_read_rsp_fire =
      source1_rsp_fire && read_owner_valid && (read_owner == OWNER1);
   wire cachebus_rsp_fire = source0_read_rsp_fire || source1_read_rsp_fire;
   wire cachebus_rsp_owner = source1_read_rsp_fire ? OWNER1 : OWNER0;
   wire cachebus_rsp_last =
      source1_read_rsp_fire ? source1_rsp_last : source0_rsp_last;

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_readback_read_req_single_owner:
            assert (!(source0_read_req_fire && source1_read_req_fire));
         ap_di_xbar_readback_read_req_not_overlapping:
            assert (!(read_owner_valid && !read_owner_complete &&
                      (source0_read_req_fire || source1_read_req_fire)));
         ap_di_xbar_readback_downstream_r_has_read_owner:
            assert (!downstream_r_fire || read_owner_valid);
         ap_di_xbar_readback_downstream_fifo_no_overflow:
            assert (!(downstream_r_fire && !cachebus_rsp_fire &&
                      (downstream_fifo_count == FIFO_DEPTH_COUNT)));

         ap_di_xbar_readback_cachebus_no_dual_rsp:
            assert (!(source0_rsp_fire && source1_rsp_fire));
         ap_di_xbar_readback_cachebus_rsp_has_downstream:
            assert (!cachebus_rsp_fire || downstream_expected_valid);
         ap_di_xbar_readback_cachebus_rsp_owner_matches:
            assert (!cachebus_rsp_fire || !downstream_expected_valid ||
                    (cachebus_rsp_owner == downstream_expected_owner));
         ap_di_xbar_readback_cachebus_rsp_last_matches_downstream:
            assert (!cachebus_rsp_fire || !downstream_expected_valid ||
                    (cachebus_rsp_last == downstream_expected_last));

         ap_di_xbar_readback_source0_axi_fifo_no_overflow:
            assert (!(source0_read_rsp_fire && !source0_r_fire &&
                      (source0_fifo_count == FIFO_DEPTH_COUNT)));
         ap_di_xbar_readback_source0_axi_r_has_cachebus:
            assert (!source0_r_fire || source0_expected_valid);
         ap_di_xbar_readback_source0_axi_rdata_matches_cachebus:
            assert (!source0_r_fire || !source0_expected_valid ||
                    (source0_r_data == source0_expected_data));
         ap_di_xbar_readback_source0_axi_rlast_matches_cachebus:
            assert (!source0_r_fire || !source0_expected_valid ||
                    (source0_r_last == source0_expected_last));

         ap_di_xbar_readback_source1_axi_fifo_no_overflow:
            assert (!(source1_read_rsp_fire && !source1_r_fire &&
                      (source1_fifo_count == FIFO_DEPTH_COUNT)));
         ap_di_xbar_readback_source1_axi_r_has_cachebus:
            assert (!source1_r_fire || source1_expected_valid);
         ap_di_xbar_readback_source1_axi_rdata_matches_cachebus:
            assert (!source1_r_fire || !source1_expected_valid ||
                    (source1_r_data == source1_expected_data));
         ap_di_xbar_readback_source1_axi_rlast_matches_cachebus:
            assert (!source1_r_fire || !source1_expected_valid ||
                    (source1_r_last == source1_expected_last));
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_readback_source0_cachebus_read_return:
            cover (source0_read_rsp_fire && source0_rsp_last);
         cv_di_xbar_readback_source1_cachebus_read_return:
            cover (source1_read_rsp_fire && source1_rsp_last);
         cv_di_xbar_readback_source0_axi_readback_complete:
            cover (source0_r_fire && source0_r_last && source0_expected_valid);
         cv_di_xbar_readback_source1_axi_readback_complete:
            cover (source1_r_fire && source1_r_last && source1_expected_valid);
      end
   end
endmodule

module amba_axi4_di_crossbar_source_data_structural_monitor (
   input wire        clock,
   input wire        reset,
   input wire [31:0] downstream_r_data,
   input wire [31:0] bridge_rsp_data,
   input wire        buscut_rsp_capture,
   input wire [31:0] buscut_buffer_data,
   input wire [31:0] buscut_rsp_data,
   input wire [31:0] source0_rsp_data,
   input wire [31:0] source1_rsp_data
);

   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_readback_data_bridge_passthrough: assert (bridge_rsp_data == downstream_r_data);
      end
   end


   reg ap_di_xbar_readback_data_buscut_capture_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_xbar_readback_data_buscut_capture_oss_past_valid <= 1'b1;
      if (ap_di_xbar_readback_data_buscut_capture_oss_past_valid && !(reset) && !$past((reset))) begin
         ap_di_xbar_readback_data_buscut_capture: assert (!$past((buscut_rsp_capture)) || (buscut_buffer_data == $past(bridge_rsp_data)));
      end
   end


   reg ap_di_xbar_readback_data_buscut_hold_oss_past_valid = 1'b0;
   always @(posedge clock) begin
      ap_di_xbar_readback_data_buscut_hold_oss_past_valid <= 1'b1;
      if (ap_di_xbar_readback_data_buscut_hold_oss_past_valid && !(reset) && !$past((reset))) begin
         ap_di_xbar_readback_data_buscut_hold: assert (!$past((!buscut_rsp_capture)) || ($stable(buscut_buffer_data)));
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_readback_data_buscut_output: assert (buscut_rsp_data == buscut_buffer_data);
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_readback_data_crossbar_source0: assert (source0_rsp_data == buscut_rsp_data);
      end
   end


   always @(posedge clock) begin
      if (!(reset)) begin
         ap_di_xbar_readback_data_crossbar_source1: assert (source1_rsp_data == buscut_rsp_data);
      end
   end

endmodule

module amba_axi4_di_crossbar_arbitration_backpressure_properties (
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
   input wire        source1_req_valid,
   input wire        source1_req_ready,
   input wire [31:0] source1_req_addr,
   input wire [31:0] source1_req_data,
   input wire        source1_req_wen,
   input wire [3:0]  source1_req_mask,
   input wire [3:0]  source1_req_len,
   input wire [1:0]  source1_req_size,
   input wire        source1_req_last,
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
   input wire        arbiter_req_valid,
   input wire        arbiter_req_wen,
   input wire [3:0]  arbiter_req_mask,
   input wire [3:0]  arbiter_req_len,
   input wire [1:0]  arbiter_req_size,

   input wire        idle_arb_window,
   input wire        both_sources_read_request,
   input wire        saw_source1_block_q,
   input wire        saw_downstream_aw_stall_q,
   input wire        saw_downstream_w_stall_q,
   input wire        saw_downstream_ar_stall_q,
   input wire        write_resp_pending_q,
   input wire        read_resp_pending_q,
   input wire        saw_downstream_b_delay_q,
   input wire        saw_downstream_r_delay_q,
   input wire        source0_req_wait_q,
   input wire [31:0] source0_req_addr_q,
   input wire [31:0] source0_req_data_q,
   input wire        source0_req_wen_q,
   input wire [3:0]  source0_req_mask_q,
   input wire [3:0]  source0_req_len_q,
   input wire [1:0]  source0_req_size_q,
   input wire        source0_req_last_q,
   input wire        source1_req_wait_q,
   input wire [31:0] source1_req_addr_q,
   input wire [31:0] source1_req_data_q,
   input wire        source1_req_wen_q,
   input wire [3:0]  source1_req_mask_q,
   input wire [3:0]  source1_req_len_q,
   input wire [1:0]  source1_req_size_q,
   input wire        source1_req_last_q,
   input wire        downstream_aw_wait_q,
   input wire [31:0] downstream_aw_addr_q,
   input wire [7:0]  downstream_aw_len_q,
   input wire [2:0]  downstream_aw_size_q,
   input wire [1:0]  downstream_aw_burst_q,
   input wire        downstream_aw_lock_q,
   input wire [3:0]  downstream_aw_cache_q,
   input wire [2:0]  downstream_aw_prot_q,
   input wire        downstream_w_wait_q,
   input wire [31:0] downstream_w_data_q,
   input wire [3:0]  downstream_w_strb_q,
   input wire        downstream_w_last_q,
   input wire        downstream_ar_wait_q,
   input wire [31:0] downstream_ar_addr_q,
   input wire [7:0]  downstream_ar_len_q,
   input wire [2:0]  downstream_ar_size_q,
   input wire [1:0]  downstream_ar_burst_q,
   input wire        downstream_ar_lock_q,
   input wire [3:0]  downstream_ar_cache_q,
   input wire [2:0]  downstream_ar_prot_q
);

   wire source0_req_fire = source0_req_valid && source0_req_ready;
   wire source1_req_fire = source1_req_valid && source1_req_ready;
   wire downstream_aw_fire = downstream_aw_valid && downstream_aw_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   always @(posedge clock) begin
      if (!reset) begin
         ap_di_xbar_backpressure_idle_priority_blocks_source1:
            assert (!(idle_arb_window && both_sources_read_request && source1_req_ready));
         ap_di_xbar_backpressure_idle_priority_accepts_source0_only:
            assert (!(idle_arb_window && both_sources_read_request &&
                      source0_req_ready && source1_req_ready));
         ap_di_xbar_backpressure_arbiter_output_matches_source0_when_contended:
            assert (!(idle_arb_window && both_sources_read_request && source0_req_ready) ||
                    (arbiter_req_valid &&
                     (arbiter_req_wen == source0_req_wen) &&
                     (arbiter_req_mask == source0_req_mask) &&
                     (arbiter_req_len == source0_req_len) &&
                     (arbiter_req_size == source0_req_size)));

         ap_di_xbar_backpressure_source0_req_stable_when_stalled:
            assert (!source0_req_wait_q ||
                    (source0_req_valid &&
                     source0_req_addr == source0_req_addr_q &&
                     source0_req_data == source0_req_data_q &&
                     source0_req_wen == source0_req_wen_q &&
                     source0_req_mask == source0_req_mask_q &&
                     source0_req_len == source0_req_len_q &&
                     source0_req_size == source0_req_size_q &&
                     source0_req_last == source0_req_last_q));
         ap_di_xbar_backpressure_source1_req_stable_when_stalled:
            assert (!source1_req_wait_q ||
                    (source1_req_valid &&
                     source1_req_addr == source1_req_addr_q &&
                     source1_req_data == source1_req_data_q &&
                     source1_req_wen == source1_req_wen_q &&
                     source1_req_mask == source1_req_mask_q &&
                     source1_req_len == source1_req_len_q &&
                     source1_req_size == source1_req_size_q &&
                     source1_req_last == source1_req_last_q));

         ap_di_xbar_backpressure_downstream_aw_stable_under_backpressure:
            assert (!downstream_aw_wait_q ||
                    (downstream_aw_valid &&
                     downstream_aw_addr == downstream_aw_addr_q &&
                     downstream_aw_len == downstream_aw_len_q &&
                     downstream_aw_size == downstream_aw_size_q &&
                     downstream_aw_burst == downstream_aw_burst_q &&
                     downstream_aw_lock == downstream_aw_lock_q &&
                     downstream_aw_cache == downstream_aw_cache_q &&
                     downstream_aw_prot == downstream_aw_prot_q));
         ap_di_xbar_backpressure_downstream_w_stable_under_backpressure:
            assert (!downstream_w_wait_q ||
                    (downstream_w_valid &&
                     downstream_w_data == downstream_w_data_q &&
                     downstream_w_strb == downstream_w_strb_q &&
                     downstream_w_last == downstream_w_last_q));
         ap_di_xbar_backpressure_downstream_ar_stable_under_backpressure:
            assert (!downstream_ar_wait_q ||
                    (downstream_ar_valid &&
                     downstream_ar_addr == downstream_ar_addr_q &&
                     downstream_ar_len == downstream_ar_len_q &&
                     downstream_ar_size == downstream_ar_size_q &&
                     downstream_ar_burst == downstream_ar_burst_q &&
                     downstream_ar_lock == downstream_ar_lock_q &&
                     downstream_ar_cache == downstream_ar_cache_q &&
                     downstream_ar_prot == downstream_ar_prot_q));
      end
   end

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_backpressure_both_read_requests:
            cover (idle_arb_window && both_sources_read_request);
         cv_di_xbar_backpressure_source0_priority_accept:
            cover (idle_arb_window && both_sources_read_request &&
                   source0_req_fire && !source1_req_ready);
         cv_di_xbar_backpressure_source1_block_then_accept:
            cover (saw_source1_block_q && source1_req_fire && !source1_req_wen);
         cv_di_xbar_backpressure_downstream_aw_stall:
            cover (downstream_aw_valid && !downstream_aw_ready);
         cv_di_xbar_backpressure_downstream_aw_stall_then_fire:
            cover (saw_downstream_aw_stall_q && downstream_aw_fire);
         cv_di_xbar_backpressure_downstream_w_stall:
            cover (downstream_w_valid && !downstream_w_ready);
         cv_di_xbar_backpressure_downstream_w_stall_then_fire:
            cover (saw_downstream_w_stall_q && downstream_w_fire);
         cv_di_xbar_backpressure_downstream_ar_stall:
            cover (downstream_ar_valid && !downstream_ar_ready);
         cv_di_xbar_backpressure_downstream_ar_stall_then_fire:
            cover (saw_downstream_ar_stall_q && downstream_ar_fire);
         cv_di_xbar_backpressure_downstream_bvalid_delay:
            cover (write_resp_pending_q && !downstream_b_valid);
         cv_di_xbar_backpressure_downstream_bvalid_delay_then_fire:
            cover (saw_downstream_b_delay_q && downstream_b_fire);
         cv_di_xbar_backpressure_downstream_rvalid_delay:
            cover (read_resp_pending_q && !downstream_r_valid);
         cv_di_xbar_backpressure_downstream_rvalid_delay_then_fire:
            cover (saw_downstream_r_delay_q && downstream_r_fire);
      end
   end
endmodule

module amba_axi4_di_crossbar_phase5_cover_properties (
   input wire       clock,
   input wire       reset,
   input wire       source0_r_valid,
   input wire       source0_r_ready,
   input wire       source0_r_last,
   input wire       source1_b_valid,
   input wire       source1_b_ready,
   input wire       source1_r_valid,
   input wire       source1_r_ready,
   input wire       source1_r_last,
   input wire       downstream_w_valid,
   input wire       downstream_w_ready,
   input wire       downstream_w_last,
   input wire       downstream_b_valid,
   input wire       downstream_b_ready,
   input wire       downstream_ar_valid,
   input wire       downstream_ar_ready,
   input wire       downstream_r_valid,
   input wire       downstream_r_ready,
   input wire       downstream_r_last,

   input wire       pending_source0_read_q,
   input wire       pending_source1_read_q,
   input wire       pending_source1_write_q,
   input wire       saw_source1_write_aw_q,
   input wire       saw_source0_readback_q,
   input wire       saw_source1_readback_q,
   input wire       write_txn_active_q,
   input wire       write_wlast_seen_q,
   input wire       read_txn_active_q,
   input wire       write8_counting,
   input wire [3:0] write8_beat_count_for_fire,
   input wire       read8_counting,
   input wire [3:0] read8_beat_count_for_fire
);

   wire source0_r_fire = source0_r_valid && source0_r_ready;
   wire source1_b_fire = source1_b_valid && source1_b_ready;
   wire source1_r_fire = source1_r_valid && source1_r_ready;
   wire downstream_w_fire = downstream_w_valid && downstream_w_ready;
   wire downstream_b_fire = downstream_b_valid && downstream_b_ready;
   wire downstream_ar_fire = downstream_ar_valid && downstream_ar_ready;
   wire downstream_r_fire = downstream_r_valid && downstream_r_ready;

   always @(posedge clock) begin
      if (!reset) begin
         cv_di_xbar_flow_source0_read_downstream_ar:
            cover (pending_source0_read_q && downstream_ar_fire);
         cv_di_xbar_flow_source1_read_downstream_ar:
            cover (pending_source1_read_q && downstream_ar_fire);
         cv_di_xbar_flow_source1_write_downstream_aw_wlast:
            cover (pending_source1_write_q && saw_source1_write_aw_q &&
                   downstream_w_fire && downstream_w_last);

         cv_di_xbar_flow_source0_readback_complete:
            cover (source0_r_fire && source0_r_last);
         cv_di_xbar_flow_source1_readback_complete:
            cover (source1_r_fire && source1_r_last);
         cv_di_xbar_flow_both_sources_readback_complete:
            cover (saw_source0_readback_q && saw_source1_readback_q);

         cv_di_xbar_flow_downstream_write_complete:
            cover (write_txn_active_q && write_wlast_seen_q && downstream_b_fire);
         cv_di_xbar_flow_downstream_read_complete:
            cover (read_txn_active_q && downstream_r_fire && downstream_r_last);

         cv_di_xbar_flow_source0_response_return:
            cover (source0_r_fire && source0_r_last);
         cv_di_xbar_flow_source1_write_response_return:
            cover (source1_b_fire);
         cv_di_xbar_flow_source1_read_response_return:
            cover (source1_r_fire && source1_r_last);

         cv_di_xbar_flow_8beat_write_burst_complete:
            cover (write8_counting && downstream_w_fire && downstream_w_last &&
                   (write8_beat_count_for_fire == 4'd7));
         cv_di_xbar_flow_8beat_read_burst_complete:
            cover (read8_counting && downstream_r_fire && downstream_r_last &&
                   (read8_beat_count_for_fire == 4'd7));
      end
   end
endmodule


`default_nettype wire
