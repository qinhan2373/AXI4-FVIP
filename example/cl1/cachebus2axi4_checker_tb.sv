`default_nettype none

module cachebus2axi4_checker_tb (
   input wire clock,
   input wire reset
);

   localparam int unsigned SOURCE = amba_axi4_protocol_checker_pkg::SOURCE;
   localparam int unsigned DESTINATION = amba_axi4_protocol_checker_pkg::DESTINATION;
   localparam int unsigned AXI4FULL = amba_axi4_protocol_checker_pkg::AXI4FULL;
   localparam logic [1:0] FIXED = amba_axi4_protocol_checker_pkg::FIXED;
   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;
   localparam logic [1:0] WRAP = amba_axi4_protocol_checker_pkg::WRAP;

   localparam logic [1:0] PH_WRITE_REQ = 2'd0;
   localparam logic [1:0] PH_WRITE_RSP = 2'd1;
   localparam logic [1:0] PH_READ_REQ  = 2'd2;
   localparam logic [1:0] PH_READ_RSP  = 2'd3;

   function automatic logic [1:0] legal_burst(input logic [1:0] raw_burst);
      legal_burst = (raw_burst == 2'b11) ? INCR : raw_burst;
   endfunction

   function automatic logic [3:0] legal_wrap_len(input logic [1:0] sel);
      case (sel)
         2'd0: legal_wrap_len = 4'd1;
         2'd1: legal_wrap_len = 4'd3;
         2'd2: legal_wrap_len = 4'd7;
         default: legal_wrap_len = 4'd15;
      endcase
   endfunction

   function automatic logic [3:0] legal_cache(input logic [3:0] sel);
      case (sel)
         4'd0: legal_cache = 4'h0;
         4'd1: legal_cache = 4'h1;
         4'd2: legal_cache = 4'h2;
         4'd3: legal_cache = 4'h3;
         4'd4: legal_cache = 4'h6;
         4'd5: legal_cache = 4'ha;
         4'd6: legal_cache = 4'he;
         4'd7: legal_cache = 4'h7;
         4'd8: legal_cache = 4'hb;
         default: legal_cache = 4'hf;
      endcase
   endfunction

   (* anyseq *) wire [2:0] f_next_write_burst_len;
   (* anyseq *) wire [2:0] f_next_read_burst_len;

   wire [1:0] f_next_write_burst = INCR;
   wire [1:0] f_next_read_burst = INCR;
   wire [3:0] f_next_write_len = {1'b0, f_next_write_burst_len};
   wire [3:0] f_next_read_len = {1'b0, f_next_read_burst_len};
   wire [1:0] f_next_write_id = 2'd0;
   wire [1:0] f_next_read_id = 2'd0;
   wire [3:0] f_next_aw_cache = 4'd0;
   wire [3:0] f_next_ar_cache = 4'd0;
   wire [2:0] f_next_aw_prot = 3'd0;
   wire [2:0] f_next_ar_prot = 3'd0;

   reg [3:0] write_burst_len = 4'd0;
   reg [3:0] read_burst_len = 4'd0;
   reg [1:0] write_axi_burst = INCR;
   reg [1:0] read_axi_burst = INCR;
   reg [1:0] write_axi_id = 2'd0;
   reg [1:0] read_axi_id = 2'd0;
   reg [3:0] write_axi_cache = 4'd0;
   reg [3:0] read_axi_cache = 4'd0;
   reg [2:0] write_axi_prot = 3'd0;
   reg [2:0] read_axi_prot = 3'd0;

   reg       f_past_valid = 1'b0;
   reg       post_reset_seen = 1'b0;
   reg       traffic_started = 1'b0;
   reg [1:0] phase = PH_WRITE_REQ;
   reg       write_aw_done = 1'b0;
   reg [3:0] write_req_beat = 4'd0;
   reg [3:0] read_rsp_beat = 4'd0;

   wire        up_aw_ready;
   wire        up_w_ready;
   wire        up_b_valid;
   wire [1:0]  up_b_id;
   wire [1:0]  up_b_resp;
   wire        up_ar_ready;
   wire        up_r_valid;
   wire [1:0]  up_r_id;
   wire [31:0] up_r_data;
   wire [1:0]  up_r_resp;
   wire        up_r_last;

   wire [31:0] up_aw_addr = 32'h0000_1000;
   wire [31:0] up_ar_addr = 32'h0000_2000;
   wire [7:0]  up_aw_len = {4'h0, write_burst_len};
   wire [7:0]  up_ar_len = {4'h0, read_burst_len};
   wire [31:0] up_w_data = 32'hdead_be00 | {28'b0, write_req_beat};
   wire [3:0]  up_w_strb = 4'hf;
   wire        up_w_last = write_req_beat == write_burst_len;
   wire        up_aw_valid = traffic_started && (phase == PH_WRITE_REQ) && !write_aw_done;
   wire        up_w_valid = traffic_started && (phase == PH_WRITE_REQ) && write_aw_done;
   wire        up_b_ready = !reset;
   wire        up_ar_valid = traffic_started && (phase == PH_READ_REQ);
   wire        up_r_ready = !reset;

   wire        up_aw_fire = up_aw_valid && up_aw_ready;
   wire        up_w_fire = up_w_valid && up_w_ready;
   wire        up_b_fire = up_b_valid && up_b_ready;
   wire        up_ar_fire = up_ar_valid && up_ar_ready;
   wire        up_r_fire = up_r_valid && up_r_ready;

   wire        cb_req_ready;
   wire        cb_req_valid;
   wire [31:0] cb_req_bits_addr;
   wire [31:0] cb_req_bits_data;
   wire        cb_req_bits_wen;
   wire        cb_req_bits_burst;
   wire [3:0]  cb_req_bits_mask;
   wire [3:0]  cb_req_bits_len;
   wire [1:0]  cb_req_bits_size;
   wire        cb_req_bits_last;
   wire        cb_rsp_ready;
   wire        cb_rsp_valid;
   wire [31:0] cb_rsp_bits_data;
   wire        cb_rsp_bits_last;
   wire        cb_rsp_bits_err;

   wire        dn_aw_valid;
   wire [31:0] dn_aw_addr;
   wire [1:0]  dn_aw_id;
   wire [7:0]  dn_aw_len;
   wire [2:0]  dn_aw_size;
   wire [1:0]  dn_aw_burst;
   wire        dn_aw_lock;
   wire [3:0]  dn_aw_cache;
   wire [2:0]  dn_aw_prot;
   wire        dn_w_valid;
   wire [31:0] dn_w_data;
   wire [3:0]  dn_w_strb;
   wire        dn_w_last;
   wire        dn_b_ready;
   wire        dn_ar_valid;
   wire [31:0] dn_ar_addr;
   wire [1:0]  dn_ar_id;
   wire [7:0]  dn_ar_len;
   wire [2:0]  dn_ar_size;
   wire [1:0]  dn_ar_burst;
   wire        dn_ar_lock;
   wire [3:0]  dn_ar_cache;
   wire [2:0]  dn_ar_prot;
   wire        dn_r_ready;

   reg         dn_aw_ready = 1'b0;
   reg         dn_w_ready = 1'b0;
   reg         dn_b_valid = 1'b0;
   reg [1:0]  dn_b_resp = 2'b00;
   reg [1:0]  dn_b_id = 2'b00;
   reg         dn_ar_ready = 1'b0;
   reg         dn_r_valid = 1'b0;
   reg [1:0]  dn_r_resp = 2'b00;
   reg [31:0] dn_r_data = 32'h1234_5678;
   reg         dn_r_last = 1'b0;
   reg [1:0]  dn_r_id = 2'b00;

   reg        slave_seen_aw = 1'b0;
   reg        slave_seen_w = 1'b0;
   reg        slave_seen_wlast = 1'b0;
   reg        slave_seen_ar = 1'b0;
   reg [1:0]  saved_aw_id = 2'b00;
   reg [1:0]  saved_ar_id = 2'b00;
   reg [31:0] saved_aw_addr = 32'h0;
   reg [7:0]  saved_aw_len = 8'h00;
   reg [2:0]  saved_aw_size = 3'b000;
   reg [1:0]  saved_aw_burst = 2'b00;
   reg [8:0]  slave_write_beat_count = 9'h000;
   reg [7:0]  read_beats_left = 8'h00;

   wire dn_aw_fire = dn_aw_valid && dn_aw_ready;
   wire dn_w_fire = dn_w_valid && dn_w_ready;
   wire dn_b_fire = dn_b_valid && dn_b_ready;
   wire dn_ar_fire = dn_ar_valid && dn_ar_ready;
   wire dn_r_fire = dn_r_valid && dn_r_ready;
   wire cb_req_fire = cb_req_valid && cb_req_ready;
   wire cb_rsp_fire = cb_rsp_valid && cb_rsp_ready;
   wire slave_read_busy = slave_seen_ar || dn_r_valid;
   wire [2:0] axi2cb_state;
   wire       axi2cb_aw_pending;
   wire [7:0] axi2cb_aw_len;
   wire [7:0] axi2cb_write_index;
   wire       axi2cb_w_buf_valid;
   wire       axi2cb_w_buf_last;
   wire       axi2cb_ar_pending;
   wire [7:0] axi2cb_ar_len;
   wire       axi2cb_rsp_last;

   wire        m_write_dep_aw_seen;
   wire [1:0]  m_write_dep_awid;
   wire [31:0] m_write_dep_awaddr;
   wire [7:0]  m_write_dep_awlen;
   wire [2:0]  m_write_dep_awsize;
   wire [1:0]  m_write_dep_awburst;
   wire [8:0]  m_write_dep_w_count;
   wire        m_write_dep_w_seen;
   wire        m_write_dep_wlast_seen;
   wire        m_read_dep_ar_seen;
   wire [1:0]  m_read_dep_arid;
   wire [7:0]  m_read_dep_arlen;
   wire [8:0]  m_read_dep_r_count;
   wire        s_write_dep_aw_seen;
   wire [1:0]  s_write_dep_awid;
   wire [31:0] s_write_dep_awaddr;
   wire [7:0]  s_write_dep_awlen;
   wire [2:0]  s_write_dep_awsize;
   wire [1:0]  s_write_dep_awburst;
   wire [8:0]  s_write_dep_w_count;
   wire        s_write_dep_w_seen;
   wire        s_write_dep_wlast_seen;
   wire        s_read_dep_ar_seen;
   wire [1:0]  s_read_dep_arid;
   wire [7:0]  s_read_dep_arlen;
   wire [8:0]  s_read_dep_r_count;

   Axi4ToCacheBus axi4_to_cachebus (
      .clock                 (clock),
      .reset                 (reset),
      .io_in_aw_ready        (up_aw_ready),
      .io_in_aw_valid        (up_aw_valid),
      .io_in_aw_bits_awid    (write_axi_id),
      .io_in_aw_bits_awaddr  (up_aw_addr),
      .io_in_aw_bits_awlen   (up_aw_len),
      .io_in_aw_bits_awsize  (3'b010),
      .io_in_aw_bits_awburst (write_axi_burst),
      .io_in_aw_bits_awlock  (1'b0),
      .io_in_aw_bits_awcache (write_axi_cache),
      .io_in_aw_bits_awprot  (write_axi_prot),
      .io_in_w_ready         (up_w_ready),
      .io_in_w_valid         (up_w_valid),
      .io_in_w_bits_wdata    (up_w_data),
      .io_in_w_bits_wstrb    (up_w_strb),
      .io_in_w_bits_wlast    (up_w_last),
      .io_in_b_ready         (up_b_ready),
      .io_in_b_valid         (up_b_valid),
      .io_in_b_bits_bid      (up_b_id),
      .io_in_b_bits_bresp    (up_b_resp),
      .io_in_ar_ready        (up_ar_ready),
      .io_in_ar_valid        (up_ar_valid),
      .io_in_ar_bits_arid    (read_axi_id),
      .io_in_ar_bits_araddr  (up_ar_addr),
      .io_in_ar_bits_arlen   (up_ar_len),
      .io_in_ar_bits_arsize  (3'b010),
      .io_in_ar_bits_arburst (read_axi_burst),
      .io_in_ar_bits_arlock  (1'b0),
      .io_in_ar_bits_arcache (read_axi_cache),
      .io_in_ar_bits_arprot  (read_axi_prot),
      .io_in_r_ready         (up_r_ready),
      .io_in_r_valid         (up_r_valid),
      .io_in_r_bits_rid      (up_r_id),
      .io_in_r_bits_rdata    (up_r_data),
      .io_in_r_bits_rresp    (up_r_resp),
      .io_in_r_bits_rlast    (up_r_last),
      .io_out_req_ready      (cb_req_ready),
      .io_out_req_valid      (cb_req_valid),
      .io_out_req_bits_addr  (cb_req_bits_addr),
      .io_out_req_bits_data  (cb_req_bits_data),
      .io_out_req_bits_wen   (cb_req_bits_wen),
      .io_out_req_bits_burst (cb_req_bits_burst),
      .io_out_req_bits_mask  (cb_req_bits_mask),
      .io_out_req_bits_len   (cb_req_bits_len),
      .io_out_req_bits_size  (cb_req_bits_size),
      .io_out_req_bits_last  (cb_req_bits_last),
      .io_out_rsp_ready      (cb_rsp_ready),
      .io_out_rsp_valid      (cb_rsp_valid),
      .io_out_rsp_bits_data  (cb_rsp_bits_data),
      .io_out_rsp_bits_last  (cb_rsp_bits_last),
      .io_out_rsp_bits_err   (cb_rsp_bits_err),
      .proof_state           (axi2cb_state),
      .proof_aw_pending      (axi2cb_aw_pending),
      .proof_aw_len          (axi2cb_aw_len),
      .proof_write_index     (axi2cb_write_index),
      .proof_w_buf_valid     (axi2cb_w_buf_valid),
      .proof_w_buf_last      (axi2cb_w_buf_last),
      .proof_ar_pending      (axi2cb_ar_pending),
      .proof_ar_len          (axi2cb_ar_len),
      .proof_rsp_last        (axi2cb_rsp_last)
   );

   CacheBus2Axi4Top cachebus_to_axi4 (
      .clock                  (clock),
      .reset                  (reset),
      .io_in_req_ready        (cb_req_ready),
      .io_in_req_valid        (cb_req_valid),
      .io_in_req_bits_addr    (cb_req_bits_addr),
      .io_in_req_bits_data    (cb_req_bits_data),
      .io_in_req_bits_wen     (cb_req_bits_wen),
      .io_in_req_bits_burst   (cb_req_bits_burst),
      .io_in_req_bits_mask    (cb_req_bits_mask),
      .io_in_req_bits_len     (cb_req_bits_len),
      .io_in_req_bits_size    (cb_req_bits_size),
      .io_in_req_bits_last    (cb_req_bits_last),
      .io_in_rsp_ready        (cb_rsp_ready),
      .io_in_rsp_valid        (cb_rsp_valid),
      .io_in_rsp_bits_data    (cb_rsp_bits_data),
      .io_in_rsp_bits_last    (cb_rsp_bits_last),
      .io_in_rsp_bits_err     (cb_rsp_bits_err),
      .io_out_aw_ready        (dn_aw_ready),
      .io_out_aw_valid        (dn_aw_valid),
      .io_out_aw_bits_awaddr  (dn_aw_addr),
      .io_out_aw_bits_awid    (dn_aw_id),
      .io_out_aw_bits_awlen   (dn_aw_len),
      .io_out_aw_bits_awsize  (dn_aw_size),
      .io_out_aw_bits_awburst (dn_aw_burst),
      .io_out_aw_bits_awlock  (dn_aw_lock),
      .io_out_aw_bits_awcache (dn_aw_cache),
      .io_out_aw_bits_awprot  (dn_aw_prot),
      .io_out_w_ready         (dn_w_ready),
      .io_out_w_valid         (dn_w_valid),
      .io_out_w_bits_wdata    (dn_w_data),
      .io_out_w_bits_wstrb    (dn_w_strb),
      .io_out_w_bits_wlast    (dn_w_last),
      .io_out_b_ready         (dn_b_ready),
      .io_out_b_valid         (dn_b_valid),
      .io_out_b_bits_bresp    (dn_b_resp),
      .io_out_b_bits_bid      (dn_b_id),
      .io_out_ar_ready        (dn_ar_ready),
      .io_out_ar_valid        (dn_ar_valid),
      .io_out_ar_bits_araddr  (dn_ar_addr),
      .io_out_ar_bits_arid    (dn_ar_id),
      .io_out_ar_bits_arlen   (dn_ar_len),
      .io_out_ar_bits_arsize  (dn_ar_size),
      .io_out_ar_bits_arburst (dn_ar_burst),
      .io_out_ar_bits_arlock  (dn_ar_lock),
      .io_out_ar_bits_arcache (dn_ar_cache),
      .io_out_ar_bits_arprot  (dn_ar_prot),
      .io_out_r_ready         (dn_r_ready),
      .io_out_r_valid         (dn_r_valid),
      .io_out_r_bits_rresp    (dn_r_resp),
      .io_out_r_bits_rdata    (dn_r_data),
      .io_out_r_bits_rlast    (dn_r_last),
      .io_out_r_bits_rid      (dn_r_id)
   );

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(2),
      .ADDRESS_WIDTH(32),
      .DATA_WIDTH(32),
      .AWUSER_WIDTH(1),
      .WUSER_WIDTH(1),
      .BUSER_WIDTH(1),
      .ARUSER_WIDTH(1),
      .RUSER_WIDTH(1),
      .MAX_WR_BURSTS(1),
      .MAX_RD_BURSTS(1),
      .MAX_WR_LENGTH(8),
      .MAX_RD_LENGTH(8),
      .MAXWAIT(8),
      .VERIFY_AGENT_TYPE(SOURCE),
      .PROTOCOL_TYPE(AXI4FULL),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b1),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b1),
      .FULL_WR_STRB(1'b0),
      .OPTIONAL_RESET(1'b1),
      .EXCLUSIVE_ACCESS(1'b0)
   ) master_axi_checker (
      .ACLK     (clock),
      .ARESETn  (!reset),
      .AWID     (write_axi_id),
      .AWADDR   (up_aw_addr),
      .AWLEN    (up_aw_len),
      .AWSIZE   (3'b010),
      .AWBURST  (write_axi_burst),
      .AWLOCK   (1'b0),
      .AWCACHE  (write_axi_cache),
      .AWPROT   (write_axi_prot),
      .AWQOS    (4'h0),
      .AWREGION (4'h0),
      .AWUSER   (1'b0),
      .AWVALID  (up_aw_valid),
      .AWREADY  (up_aw_ready),
      .WDATA    (up_w_data),
      .WSTRB    (up_w_strb),
      .WLAST    (up_w_last),
      .WUSER    (1'b0),
      .WVALID   (up_w_valid),
      .WREADY   (up_w_ready),
      .BID      (up_b_id),
      .BRESP    (up_b_resp),
      .BUSER    (1'b0),
      .BVALID   (up_b_valid),
      .BREADY   (up_b_ready),
      .ARID     (read_axi_id),
      .ARADDR   (up_ar_addr),
      .ARLEN    (up_ar_len),
      .ARSIZE   (3'b010),
      .ARBURST  (read_axi_burst),
      .ARLOCK   (1'b0),
      .ARCACHE  (read_axi_cache),
      .ARPROT   (read_axi_prot),
      .ARQOS    (4'h0),
      .ARREGION (4'h0),
      .ARUSER   (1'b0),
      .ARVALID  (up_ar_valid),
      .ARREADY  (up_ar_ready),
      .RID      (up_r_id),
      .RDATA    (up_r_data),
      .RRESP    (up_r_resp),
      .RLAST    (up_r_last),
      .RUSER    (1'b0),
      .RVALID   (up_r_valid),
      .RREADY   (up_r_ready),
      .CSYSREQ  (1'b0),
      .CSYSACK  (1'b0),
      .CACTIVE  (1'b0),
      .proof_write_dep_aw_seen   (m_write_dep_aw_seen),
      .proof_write_dep_awid      (m_write_dep_awid),
      .proof_write_dep_awaddr    (m_write_dep_awaddr),
      .proof_write_dep_awlen     (m_write_dep_awlen),
      .proof_write_dep_awsize    (m_write_dep_awsize),
      .proof_write_dep_awburst   (m_write_dep_awburst),
      .proof_write_dep_w_count   (m_write_dep_w_count),
      .proof_write_dep_w_seen    (m_write_dep_w_seen),
      .proof_write_dep_wlast_seen(m_write_dep_wlast_seen),
      .proof_read_dep_ar_seen    (m_read_dep_ar_seen),
      .proof_read_dep_arid       (m_read_dep_arid),
      .proof_read_dep_arlen      (m_read_dep_arlen),
      .proof_read_dep_r_count    (m_read_dep_r_count)
   );

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(2),
      .ADDRESS_WIDTH(32),
      .DATA_WIDTH(32),
      .AWUSER_WIDTH(1),
      .WUSER_WIDTH(1),
      .BUSER_WIDTH(1),
      .ARUSER_WIDTH(1),
      .RUSER_WIDTH(1),
      .MAX_WR_BURSTS(1),
      .MAX_RD_BURSTS(1),
      .MAX_WR_LENGTH(8),
      .MAX_RD_LENGTH(8),
      .MAXWAIT(8),
      .VERIFY_AGENT_TYPE(DESTINATION),
      .PROTOCOL_TYPE(AXI4FULL),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b1),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b1),
      .FULL_WR_STRB(1'b0),
      .OPTIONAL_RESET(1'b1),
      .EXCLUSIVE_ACCESS(1'b0)
   ) slave_axi_checker (
      .ACLK     (clock),
      .ARESETn  (!reset),
      .AWID     (dn_aw_id),
      .AWADDR   (dn_aw_addr),
      .AWLEN    (dn_aw_len),
      .AWSIZE   (dn_aw_size),
      .AWBURST  (dn_aw_burst),
      .AWLOCK   (dn_aw_lock),
      .AWCACHE  (dn_aw_cache),
      .AWPROT   (dn_aw_prot),
      .AWQOS    (4'h0),
      .AWREGION (4'h0),
      .AWUSER   (1'b0),
      .AWVALID  (dn_aw_valid),
      .AWREADY  (dn_aw_ready),
      .WDATA    (dn_w_data),
      .WSTRB    (dn_w_strb),
      .WLAST    (dn_w_last),
      .WUSER    (1'b0),
      .WVALID   (dn_w_valid),
      .WREADY   (dn_w_ready),
      .BID      (dn_b_id),
      .BRESP    (dn_b_resp),
      .BUSER    (1'b0),
      .BVALID   (dn_b_valid),
      .BREADY   (dn_b_ready),
      .ARID     (dn_ar_id),
      .ARADDR   (dn_ar_addr),
      .ARLEN    (dn_ar_len),
      .ARSIZE   (dn_ar_size),
      .ARBURST  (dn_ar_burst),
      .ARLOCK   (dn_ar_lock),
      .ARCACHE  (dn_ar_cache),
      .ARPROT   (dn_ar_prot),
      .ARQOS    (4'h0),
      .ARREGION (4'h0),
      .ARUSER   (1'b0),
      .ARVALID  (dn_ar_valid),
      .ARREADY  (dn_ar_ready),
      .RID      (dn_r_id),
      .RDATA    (dn_r_data),
      .RRESP    (dn_r_resp),
      .RLAST    (dn_r_last),
      .RUSER    (1'b0),
      .RVALID   (dn_r_valid),
      .RREADY   (dn_r_ready),
      .CSYSREQ  (1'b0),
      .CSYSACK  (1'b0),
      .CACTIVE  (1'b0),
      .proof_write_dep_aw_seen   (s_write_dep_aw_seen),
      .proof_write_dep_awid      (s_write_dep_awid),
      .proof_write_dep_awaddr    (s_write_dep_awaddr),
      .proof_write_dep_awlen     (s_write_dep_awlen),
      .proof_write_dep_awsize    (s_write_dep_awsize),
      .proof_write_dep_awburst   (s_write_dep_awburst),
      .proof_write_dep_w_count   (s_write_dep_w_count),
      .proof_write_dep_w_seen    (s_write_dep_w_seen),
      .proof_write_dep_wlast_seen(s_write_dep_wlast_seen),
      .proof_read_dep_ar_seen    (s_read_dep_ar_seen),
      .proof_read_dep_arid       (s_read_dep_arid),
      .proof_read_dep_arlen      (s_read_dep_arlen),
      .proof_read_dep_r_count    (s_read_dep_r_count)
   );

   always @(posedge clock) begin
      f_past_valid <= 1'b1;

      if (!f_past_valid)
         assume(reset);
      else
         assume(!reset);

      if (reset) begin
         phase <= PH_WRITE_REQ;
         post_reset_seen <= 1'b0;
         traffic_started <= 1'b0;
         write_aw_done <= 1'b0;
         write_req_beat <= 4'd0;
         read_rsp_beat <= 4'd0;
         write_burst_len <= f_next_write_len;
         read_burst_len <= f_next_read_len;
         write_axi_burst <= f_next_write_burst;
         read_axi_burst <= f_next_read_burst;
         write_axi_id <= f_next_write_id;
         read_axi_id <= f_next_read_id;
         write_axi_cache <= f_next_aw_cache;
         read_axi_cache <= f_next_ar_cache;
         write_axi_prot <= f_next_aw_prot;
         read_axi_prot <= f_next_ar_prot;
         dn_aw_ready <= 1'b0;
         dn_w_ready <= 1'b0;
         dn_b_valid <= 1'b0;
         dn_b_resp <= 2'b00;
         dn_b_id <= 2'b00;
         dn_ar_ready <= 1'b0;
         dn_r_valid <= 1'b0;
         dn_r_resp <= 2'b00;
         dn_r_data <= 32'h1234_5678;
         dn_r_last <= 1'b0;
         dn_r_id <= 2'b00;
         slave_seen_aw <= 1'b0;
         slave_seen_w <= 1'b0;
         slave_seen_wlast <= 1'b0;
         slave_seen_ar <= 1'b0;
         saved_aw_id <= 2'b00;
         saved_ar_id <= 2'b00;
         saved_aw_addr <= 32'h0;
         saved_aw_len <= 8'h00;
         saved_aw_size <= 3'b000;
         saved_aw_burst <= 2'b00;
         slave_write_beat_count <= 9'h000;
         read_beats_left <= 8'h00;
      end
      else begin
         if (!post_reset_seen)
            post_reset_seen <= 1'b1;
         else if (!traffic_started)
            traffic_started <= 1'b1;

         if (up_aw_fire)
            write_aw_done <= 1'b1;

         case (phase)
            PH_WRITE_REQ:
               if (up_w_fire) begin
                  if (up_w_last)
                     phase <= PH_WRITE_RSP;
                  else
                     write_req_beat <= write_req_beat + 4'd1;
               end
            PH_WRITE_RSP:
               if (up_b_fire) begin
                  phase <= PH_READ_REQ;
                  write_aw_done <= 1'b0;
                  write_req_beat <= 4'd0;
                  read_burst_len <= f_next_read_len;
                  read_axi_burst <= f_next_read_burst;
                  read_axi_id <= f_next_read_id;
                  read_axi_cache <= f_next_ar_cache;
                  read_axi_prot <= f_next_ar_prot;
               end
            PH_READ_REQ:
               if (up_ar_fire) begin
                  read_rsp_beat <= 4'd0;
                  phase <= PH_READ_RSP;
               end
            PH_READ_RSP:
               if (up_r_fire && !up_r_last)
                  read_rsp_beat <= read_rsp_beat + 4'd1;
            default:
               phase <= PH_WRITE_REQ;
         endcase

         if (dn_aw_ready && dn_aw_valid)
            dn_aw_ready <= 1'b0;
         else if (!dn_aw_ready && dn_aw_valid)
            dn_aw_ready <= 1'b1;
         else
            dn_aw_ready <= 1'b0;

         if (dn_w_ready && dn_w_valid)
            dn_w_ready <= 1'b0;
         else if (!dn_w_ready && dn_w_valid)
            dn_w_ready <= 1'b1;
         else
            dn_w_ready <= 1'b0;

         if (dn_ar_ready && dn_ar_valid)
            dn_ar_ready <= 1'b0;
         else if (!dn_ar_ready && dn_ar_valid && !slave_read_busy)
            dn_ar_ready <= 1'b1;
         else
            dn_ar_ready <= 1'b0;

         if (dn_aw_fire) begin
            slave_seen_aw <= 1'b1;
            saved_aw_id <= dn_aw_id;
            saved_aw_addr <= dn_aw_addr;
            saved_aw_len <= dn_aw_len;
            saved_aw_size <= dn_aw_size;
            saved_aw_burst <= dn_aw_burst;
         end
         if (dn_w_fire) begin
            slave_seen_w <= 1'b1;
            if (dn_w_last)
               slave_seen_wlast <= 1'b1;
            else
               slave_write_beat_count <= slave_write_beat_count + 9'h001;
         end
         if (dn_ar_fire) begin
            slave_seen_ar <= 1'b1;
            saved_ar_id <= dn_ar_id;
         end

         if (!dn_b_valid && ((slave_seen_aw || dn_aw_fire) && (slave_seen_wlast || (dn_w_fire && dn_w_last)))) begin
            dn_b_valid <= 1'b1;
            dn_b_resp <= 2'b00;
            dn_b_id <= dn_aw_fire ? dn_aw_id : saved_aw_id;
         end
         else if (dn_b_fire) begin
            dn_b_valid <= 1'b0;
            slave_seen_aw <= 1'b0;
            slave_seen_w <= 1'b0;
            slave_seen_wlast <= 1'b0;
            slave_write_beat_count <= 9'h000;
         end

         if (!dn_r_valid && (slave_seen_ar || dn_ar_fire)) begin
            dn_r_valid <= 1'b1;
            dn_r_resp <= 2'b00;
            dn_r_data <= 32'h1234_5678;
            dn_r_last <= (dn_ar_fire ? dn_ar_len : read_beats_left) == 8'h00;
            dn_r_id <= dn_ar_fire ? dn_ar_id : saved_ar_id;
            read_beats_left <= dn_ar_fire ? dn_ar_len : read_beats_left;
         end
         else if (dn_r_fire && read_beats_left == 8'h00) begin
            dn_r_valid <= 1'b0;
            dn_r_last <= 1'b0;
            slave_seen_ar <= 1'b0;
         end
         else if (dn_r_fire) begin
            read_beats_left <= read_beats_left - 8'h01;
            dn_r_data <= dn_r_data + 32'h1;
            dn_r_last <= read_beats_left == 8'h01;
         end
      end
   end

   cl1_oss_source_driver_unreachable_invariants #(
      .ID_WIDTH(2),
      .ADDRESS_WIDTH(32)
   ) source_driver_invariants (
      .clock(clock),
      .reset(reset),
      .traffic_started(traffic_started),
      .done(1'b0),
      .phase(phase),
      .write_aw_done(write_aw_done),
      .write_req_beat(write_req_beat),
      .read_rsp_beat(read_rsp_beat),
      .write_burst_len(write_burst_len),
      .read_burst_len(read_burst_len),
      .write_axi_burst(write_axi_burst),
      .read_axi_burst(read_axi_burst),
      .write_axi_id(write_axi_id),
      .read_axi_id(read_axi_id),
      .write_axi_cache(write_axi_cache),
      .read_axi_cache(read_axi_cache),
      .write_axi_prot(write_axi_prot),
      .read_axi_prot(read_axi_prot),
      .up_aw_addr(up_aw_addr),
      .up_aw_len(up_aw_len),
      .up_aw_size(3'b010),
      .m_write_dep_awid(m_write_dep_awid),
      .m_write_dep_aw_seen(m_write_dep_aw_seen),
      .m_write_dep_awaddr(m_write_dep_awaddr),
      .m_write_dep_awlen(m_write_dep_awlen),
      .m_write_dep_awsize(m_write_dep_awsize),
      .m_write_dep_awburst(m_write_dep_awburst),
      .m_write_dep_w_count(m_write_dep_w_count),
      .m_write_dep_w_seen(m_write_dep_w_seen),
      .m_write_dep_wlast_seen(m_write_dep_wlast_seen),
      .m_read_dep_ar_seen(m_read_dep_ar_seen),
      .m_read_dep_arid(m_read_dep_arid),
      .m_read_dep_arlen(m_read_dep_arlen),
      .m_read_dep_r_count(m_read_dep_r_count),
      .b_valid(up_b_valid),
      .b_id(up_b_id),
      .b_resp(up_b_resp),
      .r_valid(up_r_valid),
      .r_id(up_r_id),
      .r_resp(up_r_resp)
   );

   cl1_oss_slave_model_unreachable_invariants #(
      .ID_WIDTH(2)
   ) slave_model_invariants (
      .clock(clock),
      .reset(reset),
      .no_slave_read_expected((phase == PH_WRITE_REQ) || (phase == PH_WRITE_RSP)),
      .slave_seen_aw(slave_seen_aw),
      .slave_seen_w(slave_seen_w),
      .slave_seen_wlast(slave_seen_wlast),
      .slave_seen_ar(slave_seen_ar),
      .saved_aw_id(saved_aw_id),
      .saved_ar_id(saved_ar_id),
      .saved_aw_addr(saved_aw_addr),
      .saved_aw_len(saved_aw_len),
      .saved_aw_size(saved_aw_size),
      .saved_aw_burst(saved_aw_burst),
      .slave_write_beat_count(slave_write_beat_count),
      .read_beats_left(read_beats_left),
      .dn_aw_len(dn_aw_len),
      .dn_w_valid(dn_w_valid),
      .dn_w_last(dn_w_last),
      .dn_b_valid(dn_b_valid),
      .dn_b_id(dn_b_id),
      .dn_ar_valid(dn_ar_valid),
      .dn_ar_ready(dn_ar_ready),
      .dn_r_valid(dn_r_valid),
      .dn_r_last(dn_r_last),
      .slave_read_busy(slave_read_busy),
      .s_write_dep_aw_seen(s_write_dep_aw_seen),
      .s_write_dep_awid(s_write_dep_awid),
      .s_write_dep_awaddr(s_write_dep_awaddr),
      .s_write_dep_awlen(s_write_dep_awlen),
      .s_write_dep_awsize(s_write_dep_awsize),
      .s_write_dep_awburst(s_write_dep_awburst),
      .s_write_dep_w_count(s_write_dep_w_count),
      .s_write_dep_w_seen(s_write_dep_w_seen),
      .s_write_dep_wlast_seen(s_write_dep_wlast_seen),
      .s_read_dep_ar_seen(s_read_dep_ar_seen),
      .s_read_dep_arid(s_read_dep_arid),
      .s_read_dep_arlen(s_read_dep_arlen),
      .s_read_dep_r_count(s_read_dep_r_count)
   );

   cl1_oss_axi4_to_cachebus_source_unreachable_invariants axi2cb_invariants (
      .clock(clock),
      .reset(reset),
      .source_phase(phase),
      .source_write_aw_done(write_aw_done),
      .source_write_req_beat(write_req_beat),
      .source_read_rsp_beat(read_rsp_beat),
      .source_write_burst_len(write_burst_len),
      .source_read_burst_len(read_burst_len),
      .bridge_state(axi2cb_state),
      .bridge_aw_pending(axi2cb_aw_pending),
      .bridge_aw_len(axi2cb_aw_len),
      .bridge_write_index(axi2cb_write_index),
      .bridge_w_buf_valid(axi2cb_w_buf_valid),
      .bridge_w_buf_last(axi2cb_w_buf_last),
      .bridge_ar_pending(axi2cb_ar_pending),
      .bridge_ar_len(axi2cb_ar_len),
      .bridge_rsp_last(axi2cb_rsp_last),
      .m_read_dep_ar_seen(m_read_dep_ar_seen),
      .m_read_dep_arlen(m_read_dep_arlen),
      .m_read_dep_r_count(m_read_dep_r_count)
   );

endmodule

`default_nettype wire
