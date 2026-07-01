`default_nettype none

import amba_axi4_protocol_checker_pkg::*;

module data_integrity_single_bridge_smoke_tb (
   input wire clock,
   input wire reset
);

   localparam int unsigned CL1_ID_WIDTH      = 2;
   localparam int unsigned CL1_ADDRESS_WIDTH = 32;
   localparam int unsigned CL1_DATA_WIDTH    = 32;
   localparam int unsigned CL1_USER_WIDTH    = 1;
   localparam int unsigned CL1_MAX_BURSTS    = 1;
   localparam int unsigned CL1_MAX_LENGTH    = 8;

   (* anyconst *) wire [31:0]  f_initial_tracked_word;
   (* anyconst *) wire [2:0]   f_tracked_beat;
   reg [31:0] initial_tracked_word_q = 32'h0;
   reg [2:0] tracked_beat_q = 3'h0;
   reg       tracked_beat_loaded_q = 1'b0;
   reg       f_past_valid = 1'b0;
   wire      model_reset = reset || !tracked_beat_loaded_q;

   wire [31:0] tracked_base;
   wire [7:0]  source_burst_len;
   wire [2:0]  source_transfer_size;
   wire [31:0] source_tracked_write_data;
   wire [3:0]  source_tracked_write_strb;
   wire        source_write_done;
   wire        source_compare_done;

   wire        m_aw_ready, m_aw_valid;
   wire [1:0]  m_aw_id;
   wire [31:0] m_aw_addr;
   wire [7:0]  m_aw_len;
   wire [2:0]  m_aw_size;
   wire [1:0]  m_aw_burst;
   wire        m_aw_lock;
   wire [3:0]  m_aw_cache;
   wire [2:0]  m_aw_prot;
   wire        m_w_ready, m_w_valid;
   wire [31:0] m_w_data;
   wire [3:0]  m_w_strb;
   wire        m_w_last;
   wire        m_b_valid, m_b_ready;
   wire [1:0]  m_b_id, m_b_resp;
   wire        m_ar_ready, m_ar_valid;
   wire [1:0]  m_ar_id;
   wire [31:0] m_ar_addr;
   wire [7:0]  m_ar_len;
   wire [2:0]  m_ar_size;
   wire [1:0]  m_ar_burst;
   wire        m_ar_lock;
   wire [3:0]  m_ar_cache;
   wire [2:0]  m_ar_prot;
   wire        m_r_valid, m_r_ready;
   wire [1:0]  m_r_id, m_r_resp;
   wire [31:0] m_r_data;
   wire        m_r_last;

   amba_axi4_di_single_bridge_burst_source source (
      .clock(clock),
      .reset(model_reset),
      .tracked_beat(tracked_beat_q),
      .aw_ready(m_aw_ready),
      .aw_valid(m_aw_valid),
      .aw_id(m_aw_id),
      .aw_addr(m_aw_addr),
      .aw_len(m_aw_len),
      .aw_size(m_aw_size),
      .aw_burst(m_aw_burst),
      .aw_lock(m_aw_lock),
      .aw_cache(m_aw_cache),
      .aw_prot(m_aw_prot),
      .w_ready(m_w_ready),
      .w_valid(m_w_valid),
      .w_data(m_w_data),
      .w_strb(m_w_strb),
      .w_last(m_w_last),
      .b_valid(m_b_valid),
      .b_resp(m_b_resp),
      .b_ready(m_b_ready),
      .ar_ready(m_ar_ready),
      .ar_valid(m_ar_valid),
      .ar_id(m_ar_id),
      .ar_addr(m_ar_addr),
      .ar_len(m_ar_len),
      .ar_size(m_ar_size),
      .ar_burst(m_ar_burst),
      .ar_lock(m_ar_lock),
      .ar_cache(m_ar_cache),
      .ar_prot(m_ar_prot),
      .r_valid(m_r_valid),
      .r_data(m_r_data),
      .r_resp(m_r_resp),
      .r_last(m_r_last),
      .r_ready(m_r_ready),
      .tracked_base(tracked_base),
      .burst_len(source_burst_len),
      .transfer_size(source_transfer_size),
      .tracked_write_data(source_tracked_write_data),
      .tracked_write_strb(source_tracked_write_strb),
      .write_done(source_write_done),
      .compare_done(source_compare_done)
   );

   wire        cb_req_ready, cb_req_valid;
   wire [31:0] cb_req_addr, cb_req_data;
   wire        cb_req_wen, cb_req_burst;
   wire [3:0]  cb_req_mask, cb_req_len;
   wire [1:0]  cb_req_size;
   wire        cb_req_last;
   wire        cb_rsp_ready, cb_rsp_valid;
   wire [31:0] cb_rsp_data;
   wire        cb_rsp_last, cb_rsp_err;

   Axi4ToCacheBus axi_to_cache (
      .clock(clock),
      .reset(reset),
      .io_in_aw_ready(m_aw_ready),
      .io_in_aw_valid(m_aw_valid),
      .io_in_aw_bits_awid(m_aw_id),
      .io_in_aw_bits_awaddr(m_aw_addr),
      .io_in_aw_bits_awlen(m_aw_len),
      .io_in_aw_bits_awsize(m_aw_size),
      .io_in_aw_bits_awburst(m_aw_burst),
      .io_in_aw_bits_awlock(m_aw_lock),
      .io_in_aw_bits_awcache(m_aw_cache),
      .io_in_aw_bits_awprot(m_aw_prot),
      .io_in_w_ready(m_w_ready),
      .io_in_w_valid(m_w_valid),
      .io_in_w_bits_wdata(m_w_data),
      .io_in_w_bits_wstrb(m_w_strb),
      .io_in_w_bits_wlast(m_w_last),
      .io_in_b_ready(m_b_ready),
      .io_in_b_valid(m_b_valid),
      .io_in_b_bits_bid(m_b_id),
      .io_in_b_bits_bresp(m_b_resp),
      .io_in_ar_ready(m_ar_ready),
      .io_in_ar_valid(m_ar_valid),
      .io_in_ar_bits_arid(m_ar_id),
      .io_in_ar_bits_araddr(m_ar_addr),
      .io_in_ar_bits_arlen(m_ar_len),
      .io_in_ar_bits_arsize(m_ar_size),
      .io_in_ar_bits_arburst(m_ar_burst),
      .io_in_ar_bits_arlock(m_ar_lock),
      .io_in_ar_bits_arcache(m_ar_cache),
      .io_in_ar_bits_arprot(m_ar_prot),
      .io_in_r_ready(m_r_ready),
      .io_in_r_valid(m_r_valid),
      .io_in_r_bits_rid(m_r_id),
      .io_in_r_bits_rdata(m_r_data),
      .io_in_r_bits_rresp(m_r_resp),
      .io_in_r_bits_rlast(m_r_last),
      .io_out_req_ready(cb_req_ready),
      .io_out_req_valid(cb_req_valid),
      .io_out_req_bits_addr(cb_req_addr),
      .io_out_req_bits_data(cb_req_data),
      .io_out_req_bits_wen(cb_req_wen),
      .io_out_req_bits_burst(cb_req_burst),
      .io_out_req_bits_mask(cb_req_mask),
      .io_out_req_bits_len(cb_req_len),
      .io_out_req_bits_size(cb_req_size),
      .io_out_req_bits_last(cb_req_last),
      .io_out_rsp_ready(cb_rsp_ready),
      .io_out_rsp_valid(cb_rsp_valid),
      .io_out_rsp_bits_data(cb_rsp_data),
      .io_out_rsp_bits_last(cb_rsp_last),
      .io_out_rsp_bits_err(cb_rsp_err)
   );

   wire        s_aw_ready, s_aw_valid;
   wire [31:0] s_aw_addr;
   wire [1:0]  s_aw_id;
   wire [7:0]  s_aw_len;
   wire [2:0]  s_aw_size;
   wire [1:0]  s_aw_burst;
   wire        s_aw_lock;
   wire [3:0]  s_aw_cache;
   wire [2:0]  s_aw_prot;
   wire        s_w_ready, s_w_valid;
   wire [31:0] s_w_data;
   wire [3:0]  s_w_strb;
   wire        s_w_last;
   wire        s_b_ready, s_b_valid;
   wire [1:0]  s_b_resp, s_b_id;
   wire        s_ar_ready, s_ar_valid;
   wire [31:0] s_ar_addr;
   wire [1:0]  s_ar_id;
   wire [7:0]  s_ar_len;
   wire [2:0]  s_ar_size;
   wire [1:0]  s_ar_burst;
   wire        s_ar_lock;
   wire [3:0]  s_ar_cache;
   wire [2:0]  s_ar_prot;
   wire        s_r_ready, s_r_valid;
   wire [31:0] s_r_data;
   wire [1:0]  s_r_resp, s_r_id;
   wire        s_r_last;
   wire [31:0] memory_tracked_word;

   CacheBus2Axi4Top cache_to_axi (
      .clock(clock),
      .reset(reset),
      .io_in_req_ready(cb_req_ready),
      .io_in_req_valid(cb_req_valid),
      .io_in_req_bits_addr(cb_req_addr),
      .io_in_req_bits_data(cb_req_data),
      .io_in_req_bits_wen(cb_req_wen),
      .io_in_req_bits_burst(cb_req_burst),
      .io_in_req_bits_mask(cb_req_mask),
      .io_in_req_bits_len(cb_req_len),
      .io_in_req_bits_size(cb_req_size),
      .io_in_req_bits_last(cb_req_last),
      .io_in_rsp_ready(cb_rsp_ready),
      .io_in_rsp_valid(cb_rsp_valid),
      .io_in_rsp_bits_data(cb_rsp_data),
      .io_in_rsp_bits_last(cb_rsp_last),
      .io_in_rsp_bits_err(cb_rsp_err),
      .io_out_aw_ready(s_aw_ready),
      .io_out_aw_valid(s_aw_valid),
      .io_out_aw_bits_awaddr(s_aw_addr),
      .io_out_aw_bits_awid(s_aw_id),
      .io_out_aw_bits_awlen(s_aw_len),
      .io_out_aw_bits_awsize(s_aw_size),
      .io_out_aw_bits_awburst(s_aw_burst),
      .io_out_aw_bits_awlock(s_aw_lock),
      .io_out_aw_bits_awcache(s_aw_cache),
      .io_out_aw_bits_awprot(s_aw_prot),
      .io_out_w_ready(s_w_ready),
      .io_out_w_valid(s_w_valid),
      .io_out_w_bits_wdata(s_w_data),
      .io_out_w_bits_wstrb(s_w_strb),
      .io_out_w_bits_wlast(s_w_last),
      .io_out_b_ready(s_b_ready),
      .io_out_b_valid(s_b_valid),
      .io_out_b_bits_bresp(s_b_resp),
      .io_out_b_bits_bid(s_b_id),
      .io_out_ar_ready(s_ar_ready),
      .io_out_ar_valid(s_ar_valid),
      .io_out_ar_bits_araddr(s_ar_addr),
      .io_out_ar_bits_arid(s_ar_id),
      .io_out_ar_bits_arlen(s_ar_len),
      .io_out_ar_bits_arsize(s_ar_size),
      .io_out_ar_bits_arburst(s_ar_burst),
      .io_out_ar_bits_arlock(s_ar_lock),
      .io_out_ar_bits_arcache(s_ar_cache),
      .io_out_ar_bits_arprot(s_ar_prot),
      .io_out_r_ready(s_r_ready),
      .io_out_r_valid(s_r_valid),
      .io_out_r_bits_rresp(s_r_resp),
      .io_out_r_bits_rdata(s_r_data),
      .io_out_r_bits_rlast(s_r_last),
      .io_out_r_bits_rid(s_r_id)
   );

`ifdef AXI4_DI_USE_ALEXFORENCICH_AXI_RAM
   amba_axi4_di_alexforencich_axi_ram_window memory (
`else
   amba_axi4_di_window_axi_memory memory (
`endif
      .clock(clock),
      .reset(model_reset),
      .tracked_base(tracked_base),
      .tracked_beat(tracked_beat_q),
      .transfer_size(source_transfer_size),
      .initial_tracked_word(initial_tracked_word_q),
      .aw_ready(s_aw_ready),
      .aw_valid(s_aw_valid),
      .aw_addr(s_aw_addr),
      .aw_len(s_aw_len),
      .aw_size(s_aw_size),
      .aw_id(s_aw_id),
      .w_ready(s_w_ready),
      .w_valid(s_w_valid),
      .w_data(s_w_data),
      .w_strb(s_w_strb),
      .w_last(s_w_last),
      .b_ready(s_b_ready),
      .b_valid(s_b_valid),
      .b_resp(s_b_resp),
      .b_id(s_b_id),
      .ar_ready(s_ar_ready),
      .ar_valid(s_ar_valid),
      .ar_addr(s_ar_addr),
      .ar_len(s_ar_len),
      .ar_size(s_ar_size),
      .ar_id(s_ar_id),
      .r_ready(s_r_ready),
      .r_valid(s_r_valid),
      .r_data(s_r_data),
      .r_resp(s_r_resp),
      .r_last(s_r_last),
      .r_id(s_r_id),
      .tracked_word(memory_tracked_word)
   );

   wire observer_write_committed;
   wire observer_read_compared;
   wire [31:0] observer_golden_tracked_word;
   wire [31:0] observer_expected_read_tracked_word;
   wire        observer_read_snapshot_valid;

   amba_axi4_di_window_observer observer (
      .clock(clock),
      .reset(model_reset),
      .initial_tracked_word(initial_tracked_word_q),
      .tracked_beat(tracked_beat_q),
      .transfer_size(source_transfer_size),
      .aw_valid(m_aw_valid),
      .aw_ready(m_aw_ready),
      .aw_addr(m_aw_addr),
      .aw_len(m_aw_len),
      .aw_size(m_aw_size),
      .aw_burst(m_aw_burst),
      .w_valid(m_w_valid),
      .w_ready(m_w_ready),
      .w_data(m_w_data),
      .w_strb(m_w_strb),
      .w_last(m_w_last),
      .b_valid(m_b_valid),
      .b_ready(m_b_ready),
      .b_resp(m_b_resp),
      .ar_valid(m_ar_valid),
      .ar_ready(m_ar_ready),
      .ar_addr(m_ar_addr),
      .ar_len(m_ar_len),
      .ar_size(m_ar_size),
      .ar_burst(m_ar_burst),
      .r_valid(m_r_valid),
      .r_ready(m_r_ready),
      .r_data(m_r_data),
      .r_resp(m_r_resp),
      .r_last(m_r_last),
      .tracked_base(tracked_base),
      .write_committed(observer_write_committed),
      .read_compared(observer_read_compared),
      .golden_tracked_word(observer_golden_tracked_word),
      .expected_read_tracked_word(observer_expected_read_tracked_word),
      .read_snapshot_valid(observer_read_snapshot_valid)
   );

   wire                        m_proof_write_dep_aw_seen;
   wire [CL1_ID_WIDTH-1:0]     m_proof_write_dep_awid;
   wire [CL1_ADDRESS_WIDTH-1:0] m_proof_write_dep_awaddr;
   wire [7:0]                  m_proof_write_dep_awlen;
   wire [2:0]                  m_proof_write_dep_awsize;
   wire [1:0]                  m_proof_write_dep_awburst;
   wire [8:0]                  m_proof_write_dep_w_count;
   wire                        m_proof_write_dep_w_seen;
   wire                        m_proof_write_dep_wlast_seen;
   wire                        m_proof_read_dep_ar_seen;
   wire [CL1_ID_WIDTH-1:0]     m_proof_read_dep_arid;
   wire [7:0]                  m_proof_read_dep_arlen;
   wire [8:0]                  m_proof_read_dep_r_count;

   wire                        s_proof_write_dep_aw_seen;
   wire [CL1_ID_WIDTH-1:0]     s_proof_write_dep_awid;
   wire [CL1_ADDRESS_WIDTH-1:0] s_proof_write_dep_awaddr;
   wire [7:0]                  s_proof_write_dep_awlen;
   wire [2:0]                  s_proof_write_dep_awsize;
   wire [1:0]                  s_proof_write_dep_awburst;
   wire [8:0]                  s_proof_write_dep_w_count;
   wire                        s_proof_write_dep_w_seen;
   wire                        s_proof_write_dep_wlast_seen;
   wire                        s_proof_read_dep_ar_seen;
   wire [CL1_ID_WIDTH-1:0]     s_proof_read_dep_arid;
   wire [7:0]                  s_proof_read_dep_arlen;
   wire [8:0]                  s_proof_read_dep_r_count;

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(CL1_ID_WIDTH),
      .ADDRESS_WIDTH(CL1_ADDRESS_WIDTH),
      .DATA_WIDTH(CL1_DATA_WIDTH),
      .AWUSER_WIDTH(CL1_USER_WIDTH),
      .WUSER_WIDTH(CL1_USER_WIDTH),
      .BUSER_WIDTH(CL1_USER_WIDTH),
      .ARUSER_WIDTH(CL1_USER_WIDTH),
      .RUSER_WIDTH(CL1_USER_WIDTH),
      .MAX_WR_BURSTS(CL1_MAX_BURSTS),
      .MAX_RD_BURSTS(CL1_MAX_BURSTS),
      .MAX_WR_LENGTH(CL1_MAX_LENGTH),
      .MAX_RD_LENGTH(CL1_MAX_LENGTH),
      .MAXWAIT(16),
      .VERIFY_AGENT_TYPE(DESTINATION),
      .PROTOCOL_TYPE(AXI4FULL),
      .INTERFACE_REQS(1'b1),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b0),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b0),
      .FULL_WR_STRB(1'b0),
      .OPTIONAL_RESET(1'b1),
      .EXCLUSIVE_ACCESS(1'b0),
      .OPTIONAL_LP(1'b0)
   )
   master_side_check (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(m_aw_id), .AWADDR(m_aw_addr), .AWLEN(m_aw_len), .AWSIZE(m_aw_size),
      .AWBURST(m_aw_burst), .AWLOCK(m_aw_lock), .AWCACHE(m_aw_cache),
      .AWPROT(m_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(m_aw_valid), .AWREADY(m_aw_ready),
      .WDATA(m_w_data), .WSTRB(m_w_strb), .WLAST(m_w_last), .WUSER(1'b0),
      .WVALID(m_w_valid), .WREADY(m_w_ready),
      .BID(m_b_id), .BRESP(m_b_resp), .BUSER(1'b0),
      .BVALID(m_b_valid), .BREADY(m_b_ready),
      .ARID(m_ar_id), .ARADDR(m_ar_addr), .ARLEN(m_ar_len), .ARSIZE(m_ar_size),
      .ARBURST(m_ar_burst), .ARLOCK(m_ar_lock), .ARCACHE(m_ar_cache),
      .ARPROT(m_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(m_ar_valid), .ARREADY(m_ar_ready),
      .RID(m_r_id), .RDATA(m_r_data), .RRESP(m_r_resp), .RLAST(m_r_last),
      .RUSER(1'b0), .RVALID(m_r_valid), .RREADY(m_r_ready),
      .CSYSREQ(1'b1), .CSYSACK(1'b1), .CACTIVE(1'b1),
      .proof_write_dep_aw_seen(m_proof_write_dep_aw_seen),
      .proof_write_dep_awid(m_proof_write_dep_awid),
      .proof_write_dep_awaddr(m_proof_write_dep_awaddr),
      .proof_write_dep_awlen(m_proof_write_dep_awlen),
      .proof_write_dep_awsize(m_proof_write_dep_awsize),
      .proof_write_dep_awburst(m_proof_write_dep_awburst),
      .proof_write_dep_w_count(m_proof_write_dep_w_count),
      .proof_write_dep_w_seen(m_proof_write_dep_w_seen),
      .proof_write_dep_wlast_seen(m_proof_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(m_proof_read_dep_ar_seen),
      .proof_read_dep_arid(m_proof_read_dep_arid),
      .proof_read_dep_arlen(m_proof_read_dep_arlen),
      .proof_read_dep_r_count(m_proof_read_dep_r_count)
   );

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(CL1_ID_WIDTH),
      .ADDRESS_WIDTH(CL1_ADDRESS_WIDTH),
      .DATA_WIDTH(CL1_DATA_WIDTH),
      .AWUSER_WIDTH(CL1_USER_WIDTH),
      .WUSER_WIDTH(CL1_USER_WIDTH),
      .BUSER_WIDTH(CL1_USER_WIDTH),
      .ARUSER_WIDTH(CL1_USER_WIDTH),
      .RUSER_WIDTH(CL1_USER_WIDTH),
      .MAX_WR_BURSTS(CL1_MAX_BURSTS),
      .MAX_RD_BURSTS(CL1_MAX_BURSTS),
      .MAX_WR_LENGTH(CL1_MAX_LENGTH),
      .MAX_RD_LENGTH(CL1_MAX_LENGTH),
      .MAXWAIT(16),
      .VERIFY_AGENT_TYPE(SOURCE),
      .PROTOCOL_TYPE(AXI4FULL),
      .INTERFACE_REQS(1'b1),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b0),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b0),
      .FULL_WR_STRB(1'b0),
      .OPTIONAL_RESET(1'b1),
      .EXCLUSIVE_ACCESS(1'b0),
      .OPTIONAL_LP(1'b0)
   )
   slave_side_check (
      .ACLK(clock), .ARESETn(!reset),
      .AWID(s_aw_id), .AWADDR(s_aw_addr), .AWLEN(s_aw_len), .AWSIZE(s_aw_size),
      .AWBURST(s_aw_burst), .AWLOCK(s_aw_lock), .AWCACHE(s_aw_cache),
      .AWPROT(s_aw_prot), .AWQOS(4'h0), .AWREGION(4'h0), .AWUSER(1'b0),
      .AWVALID(s_aw_valid), .AWREADY(s_aw_ready),
      .WDATA(s_w_data), .WSTRB(s_w_strb), .WLAST(s_w_last), .WUSER(1'b0),
      .WVALID(s_w_valid), .WREADY(s_w_ready),
      .BID(s_b_id), .BRESP(s_b_resp), .BUSER(1'b0),
      .BVALID(s_b_valid), .BREADY(s_b_ready),
      .ARID(s_ar_id), .ARADDR(s_ar_addr), .ARLEN(s_ar_len), .ARSIZE(s_ar_size),
      .ARBURST(s_ar_burst), .ARLOCK(s_ar_lock), .ARCACHE(s_ar_cache),
      .ARPROT(s_ar_prot), .ARQOS(4'h0), .ARREGION(4'h0), .ARUSER(1'b0),
      .ARVALID(s_ar_valid), .ARREADY(s_ar_ready),
      .RID(s_r_id), .RDATA(s_r_data), .RRESP(s_r_resp), .RLAST(s_r_last),
      .RUSER(1'b0), .RVALID(s_r_valid), .RREADY(s_r_ready),
      .CSYSREQ(1'b1), .CSYSACK(1'b1), .CACTIVE(1'b1),
      .proof_write_dep_aw_seen(s_proof_write_dep_aw_seen),
      .proof_write_dep_awid(s_proof_write_dep_awid),
      .proof_write_dep_awaddr(s_proof_write_dep_awaddr),
      .proof_write_dep_awlen(s_proof_write_dep_awlen),
      .proof_write_dep_awsize(s_proof_write_dep_awsize),
      .proof_write_dep_awburst(s_proof_write_dep_awburst),
      .proof_write_dep_w_count(s_proof_write_dep_w_count),
      .proof_write_dep_w_seen(s_proof_write_dep_w_seen),
      .proof_write_dep_wlast_seen(s_proof_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(s_proof_read_dep_ar_seen),
      .proof_read_dep_arid(s_proof_read_dep_arid),
      .proof_read_dep_arlen(s_proof_read_dep_arlen),
      .proof_read_dep_r_count(s_proof_read_dep_r_count)
   );

   wire m_aw_fire = m_aw_valid && m_aw_ready;
   wire m_w_fire = m_w_valid && m_w_ready;
   wire m_b_fire = m_b_valid && m_b_ready;
   wire m_ar_fire = m_ar_valid && m_ar_ready;
   wire m_r_fire = m_r_valid && m_r_ready;
   wire s_aw_fire = s_aw_valid && s_aw_ready;
   wire s_w_fire = s_w_valid && s_w_ready;
   wire s_b_fire = s_b_valid && s_b_ready;
   wire s_ar_fire = s_ar_valid && s_ar_ready;
   wire s_r_fire = s_r_valid && s_r_ready;

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         initial_tracked_word_q <= 32'h0;
         tracked_beat_q <= 3'h0;
         tracked_beat_loaded_q <= 1'b0;
      end
      else if (!tracked_beat_loaded_q) begin
         initial_tracked_word_q <= f_initial_tracked_word;
         tracked_beat_q <= f_tracked_beat;
         tracked_beat_loaded_q <= 1'b1;
      end
   end

   always @(posedge clock) begin
      f_past_valid <= 1'b1;

      if (!f_past_valid)
         as_di_single_bridge_initial_reset: assume(reset);
      else
         as_di_single_bridge_reset_released: assume(!reset);
   end

   amba_axi4_di_single_bridge_model single_bridge_di (
      .clock(clock),
      .reset(reset),
      .model_reset(model_reset),
      .initial_tracked_word(initial_tracked_word_q),
      .tracked_beat(tracked_beat_q),
      .tracked_base(tracked_base),
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
      .m_r_last(m_r_last),
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
      .s_b_fire(s_b_fire),
      .s_ar_fire(s_ar_fire),
      .s_ar_addr(s_ar_addr),
      .s_ar_len(s_ar_len),
      .s_ar_size(s_ar_size),
      .s_ar_burst(s_ar_burst),
      .s_ar_id(s_ar_id),
      .s_r_fire(s_r_fire),
      .s_r_data(s_r_data),
      .s_r_last(s_r_last)
   );


endmodule

`default_nettype wire
