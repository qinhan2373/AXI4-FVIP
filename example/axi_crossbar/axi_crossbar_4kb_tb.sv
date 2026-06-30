`default_nettype none

module axi_crossbar_4kb_tb (
   input wire clk,
   input wire rst
);

   localparam int unsigned MONITOR = amba_axi4_protocol_checker_pkg::MONITOR;
   localparam int unsigned AXI4FULL = amba_axi4_protocol_checker_pkg::AXI4FULL;
   localparam logic [1:0] INCR = amba_axi4_protocol_checker_pkg::INCR;

   localparam int unsigned S_COUNT = 1;
   localparam int unsigned M_COUNT = 1;
   localparam int unsigned DATA_WIDTH = 32;
   localparam int unsigned ADDR_WIDTH = 32;
   localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8;
   localparam int unsigned S_ID_WIDTH = 4;
   localparam int unsigned M_ID_WIDTH = S_ID_WIDTH + $clog2(S_COUNT);
   localparam int unsigned USER_WIDTH = 1;

   reg f_past_valid = 1'b0;
   reg ar_sent = 1'b0;

   wire [S_COUNT*S_ID_WIDTH-1:0] s_axi_awid = '0;
   wire [S_COUNT*ADDR_WIDTH-1:0] s_axi_awaddr = '0;
   wire [S_COUNT*8-1:0] s_axi_awlen = '0;
   wire [S_COUNT*3-1:0] s_axi_awsize = '0;
   wire [S_COUNT*2-1:0] s_axi_awburst = '0;
   wire [S_COUNT-1:0] s_axi_awlock = '0;
   wire [S_COUNT*4-1:0] s_axi_awcache = '0;
   wire [S_COUNT*3-1:0] s_axi_awprot = '0;
   wire [S_COUNT*4-1:0] s_axi_awqos = '0;
   wire [S_COUNT*USER_WIDTH-1:0] s_axi_awuser = '0;
   wire [S_COUNT-1:0] s_axi_awvalid = '0;
   wire [S_COUNT-1:0] s_axi_awready;

   wire [S_COUNT*DATA_WIDTH-1:0] s_axi_wdata = '0;
   wire [S_COUNT*STRB_WIDTH-1:0] s_axi_wstrb = '0;
   wire [S_COUNT-1:0] s_axi_wlast = '0;
   wire [S_COUNT*USER_WIDTH-1:0] s_axi_wuser = '0;
   wire [S_COUNT-1:0] s_axi_wvalid = '0;
   wire [S_COUNT-1:0] s_axi_wready;

   wire [S_COUNT*S_ID_WIDTH-1:0] s_axi_bid;
   wire [S_COUNT*2-1:0] s_axi_bresp;
   wire [S_COUNT*USER_WIDTH-1:0] s_axi_buser;
   wire [S_COUNT-1:0] s_axi_bvalid;
   wire [S_COUNT-1:0] s_axi_bready = '0;

   // 0xff0 + (ARLEN+1) * 4 bytes - 1 = 0x1003, crossing a 4KB boundary.
   wire [S_COUNT*S_ID_WIDTH-1:0] s_axi_arid = '0;
   wire [S_COUNT*ADDR_WIDTH-1:0] s_axi_araddr = 32'h0000_0ff0;
   wire [S_COUNT*8-1:0] s_axi_arlen = 8'h04;
   wire [S_COUNT*3-1:0] s_axi_arsize = 3'd2;
   wire [S_COUNT*2-1:0] s_axi_arburst = INCR;
   wire [S_COUNT-1:0] s_axi_arlock = '0;
   wire [S_COUNT*4-1:0] s_axi_arcache = 4'h0;
   wire [S_COUNT*3-1:0] s_axi_arprot = 3'h0;
   wire [S_COUNT*4-1:0] s_axi_arqos = '0;
   wire [S_COUNT*USER_WIDTH-1:0] s_axi_aruser = '0;
   wire [S_COUNT-1:0] s_axi_arvalid = !rst && !ar_sent;
   wire [S_COUNT-1:0] s_axi_arready;

   wire [S_COUNT*S_ID_WIDTH-1:0] s_axi_rid;
   wire [S_COUNT*DATA_WIDTH-1:0] s_axi_rdata;
   wire [S_COUNT*2-1:0] s_axi_rresp;
   wire [S_COUNT-1:0] s_axi_rlast;
   wire [S_COUNT*USER_WIDTH-1:0] s_axi_ruser;
   wire [S_COUNT-1:0] s_axi_rvalid;
   wire [S_COUNT-1:0] s_axi_rready = '0;

   wire [M_COUNT*M_ID_WIDTH-1:0] m_axi_awid;
   wire [M_COUNT*ADDR_WIDTH-1:0] m_axi_awaddr;
   wire [M_COUNT*8-1:0] m_axi_awlen;
   wire [M_COUNT*3-1:0] m_axi_awsize;
   wire [M_COUNT*2-1:0] m_axi_awburst;
   wire [M_COUNT-1:0] m_axi_awlock;
   wire [M_COUNT*4-1:0] m_axi_awcache;
   wire [M_COUNT*3-1:0] m_axi_awprot;
   wire [M_COUNT*4-1:0] m_axi_awqos;
   wire [M_COUNT*4-1:0] m_axi_awregion;
   wire [M_COUNT*USER_WIDTH-1:0] m_axi_awuser;
   wire [M_COUNT-1:0] m_axi_awvalid;
   wire [M_COUNT-1:0] m_axi_awready = '0;

   wire [M_COUNT*DATA_WIDTH-1:0] m_axi_wdata;
   wire [M_COUNT*STRB_WIDTH-1:0] m_axi_wstrb;
   wire [M_COUNT-1:0] m_axi_wlast;
   wire [M_COUNT*USER_WIDTH-1:0] m_axi_wuser;
   wire [M_COUNT-1:0] m_axi_wvalid;
   wire [M_COUNT-1:0] m_axi_wready = '0;

   wire [M_COUNT*M_ID_WIDTH-1:0] m_axi_bid = '0;
   wire [M_COUNT*2-1:0] m_axi_bresp = '0;
   wire [M_COUNT*USER_WIDTH-1:0] m_axi_buser = '0;
   wire [M_COUNT-1:0] m_axi_bvalid = '0;
   wire [M_COUNT-1:0] m_axi_bready;

   wire [M_COUNT*M_ID_WIDTH-1:0] m_axi_arid;
   wire [M_COUNT*ADDR_WIDTH-1:0] m_axi_araddr;
   wire [M_COUNT*8-1:0] m_axi_arlen;
   wire [M_COUNT*3-1:0] m_axi_arsize;
   wire [M_COUNT*2-1:0] m_axi_arburst;
   wire [M_COUNT-1:0] m_axi_arlock;
   wire [M_COUNT*4-1:0] m_axi_arcache;
   wire [M_COUNT*3-1:0] m_axi_arprot;
   wire [M_COUNT*4-1:0] m_axi_arqos;
   wire [M_COUNT*4-1:0] m_axi_arregion;
   wire [M_COUNT*USER_WIDTH-1:0] m_axi_aruser;
   wire [M_COUNT-1:0] m_axi_arvalid;
   wire [M_COUNT-1:0] m_axi_arready = '1;

   wire [M_COUNT*M_ID_WIDTH-1:0] m_axi_rid = '0;
   wire [M_COUNT*DATA_WIDTH-1:0] m_axi_rdata = '0;
   wire [M_COUNT*2-1:0] m_axi_rresp = '0;
   wire [M_COUNT-1:0] m_axi_rlast = '0;
   wire [M_COUNT*USER_WIDTH-1:0] m_axi_ruser = '0;
   wire [M_COUNT-1:0] m_axi_rvalid = '0;
   wire [M_COUNT-1:0] m_axi_rready;

   axi_crossbar #(
      .S_COUNT(S_COUNT),
      .M_COUNT(M_COUNT),
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH),
      .STRB_WIDTH(STRB_WIDTH),
      .S_ID_WIDTH(S_ID_WIDTH),
      .M_ID_WIDTH(M_ID_WIDTH),
      .AWUSER_WIDTH(USER_WIDTH),
      .WUSER_WIDTH(USER_WIDTH),
      .BUSER_WIDTH(USER_WIDTH),
      .ARUSER_WIDTH(USER_WIDTH),
      .RUSER_WIDTH(USER_WIDTH)
   ) dut (
      .clk(clk),
      .rst(rst),
      .s_axi_awid(s_axi_awid),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awlen(s_axi_awlen),
      .s_axi_awsize(s_axi_awsize),
      .s_axi_awburst(s_axi_awburst),
      .s_axi_awlock(s_axi_awlock),
      .s_axi_awcache(s_axi_awcache),
      .s_axi_awprot(s_axi_awprot),
      .s_axi_awqos(s_axi_awqos),
      .s_axi_awuser(s_axi_awuser),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wlast(s_axi_wlast),
      .s_axi_wuser(s_axi_wuser),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bid(s_axi_bid),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_buser(s_axi_buser),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_arid(s_axi_arid),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arlen(s_axi_arlen),
      .s_axi_arsize(s_axi_arsize),
      .s_axi_arburst(s_axi_arburst),
      .s_axi_arlock(s_axi_arlock),
      .s_axi_arcache(s_axi_arcache),
      .s_axi_arprot(s_axi_arprot),
      .s_axi_arqos(s_axi_arqos),
      .s_axi_aruser(s_axi_aruser),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rid(s_axi_rid),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rlast(s_axi_rlast),
      .s_axi_ruser(s_axi_ruser),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
      .m_axi_awid(m_axi_awid),
      .m_axi_awaddr(m_axi_awaddr),
      .m_axi_awlen(m_axi_awlen),
      .m_axi_awsize(m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awlock(m_axi_awlock),
      .m_axi_awcache(m_axi_awcache),
      .m_axi_awprot(m_axi_awprot),
      .m_axi_awqos(m_axi_awqos),
      .m_axi_awregion(m_axi_awregion),
      .m_axi_awuser(m_axi_awuser),
      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awready(m_axi_awready),
      .m_axi_wdata(m_axi_wdata),
      .m_axi_wstrb(m_axi_wstrb),
      .m_axi_wlast(m_axi_wlast),
      .m_axi_wuser(m_axi_wuser),
      .m_axi_wvalid(m_axi_wvalid),
      .m_axi_wready(m_axi_wready),
      .m_axi_bid(m_axi_bid),
      .m_axi_bresp(m_axi_bresp),
      .m_axi_buser(m_axi_buser),
      .m_axi_bvalid(m_axi_bvalid),
      .m_axi_bready(m_axi_bready),
      .m_axi_arid(m_axi_arid),
      .m_axi_araddr(m_axi_araddr),
      .m_axi_arlen(m_axi_arlen),
      .m_axi_arsize(m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arlock(m_axi_arlock),
      .m_axi_arcache(m_axi_arcache),
      .m_axi_arprot(m_axi_arprot),
      .m_axi_arqos(m_axi_arqos),
      .m_axi_arregion(m_axi_arregion),
      .m_axi_aruser(m_axi_aruser),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arready(m_axi_arready),
      .m_axi_rid(m_axi_rid),
      .m_axi_rdata(m_axi_rdata),
      .m_axi_rresp(m_axi_rresp),
      .m_axi_rlast(m_axi_rlast),
      .m_axi_ruser(m_axi_ruser),
      .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rready(m_axi_rready)
   );

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(M_ID_WIDTH),
      .ADDRESS_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .AWUSER_WIDTH(USER_WIDTH),
      .WUSER_WIDTH(USER_WIDTH),
      .BUSER_WIDTH(USER_WIDTH),
      .ARUSER_WIDTH(USER_WIDTH),
      .RUSER_WIDTH(USER_WIDTH),
      .MAX_WR_BURSTS(1),
      .MAX_RD_BURSTS(1),
      .MAX_WR_LENGTH(256),
      .MAX_RD_LENGTH(256),
      .MAXWAIT(8),
      .VERIFY_AGENT_TYPE(MONITOR),
      .PROTOCOL_TYPE(AXI4FULL),
      .INTERFACE_REQS(1'b1),
      .ENABLE_COVER(1'b0),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b1),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b1),
      .FULL_WR_STRB(1'b0),
      .OPTIONAL_RESET(1'b1),
      .EXCLUSIVE_ACCESS(1'b0)
   ) source_chk (
      .ACLK(clk),
      .ARESETn(!rst),
      .AWID(m_axi_awid),
      .AWADDR(m_axi_awaddr),
      .AWLEN(m_axi_awlen),
      .AWSIZE(m_axi_awsize),
      .AWBURST(m_axi_awburst),
      .AWLOCK(m_axi_awlock),
      .AWCACHE(m_axi_awcache),
      .AWPROT(m_axi_awprot),
      .AWQOS(m_axi_awqos),
      .AWREGION(m_axi_awregion),
      .AWUSER(m_axi_awuser),
      .AWVALID(m_axi_awvalid),
      .AWREADY(m_axi_awready),
      .WDATA(m_axi_wdata),
      .WSTRB(m_axi_wstrb),
      .WLAST(m_axi_wlast),
      .WUSER(m_axi_wuser),
      .WVALID(m_axi_wvalid),
      .WREADY(m_axi_wready),
      .BID(m_axi_bid),
      .BRESP(m_axi_bresp),
      .BUSER(m_axi_buser),
      .BVALID(m_axi_bvalid),
      .BREADY(m_axi_bready),
      .ARID(m_axi_arid),
      .ARADDR(m_axi_araddr),
      .ARLEN(m_axi_arlen),
      .ARSIZE(m_axi_arsize),
      .ARBURST(m_axi_arburst),
      .ARLOCK(m_axi_arlock),
      .ARCACHE(m_axi_arcache),
      .ARPROT(m_axi_arprot),
      .ARQOS(m_axi_arqos),
      .ARREGION(m_axi_arregion),
      .ARUSER(m_axi_aruser),
      .ARVALID(m_axi_arvalid),
      .ARREADY(m_axi_arready),
      .RID(m_axi_rid),
      .RDATA(m_axi_rdata),
      .RRESP(m_axi_rresp),
      .RLAST(m_axi_rlast),
      .RUSER(m_axi_ruser),
      .RVALID(m_axi_rvalid),
      .RREADY(m_axi_rready),
      .CSYSREQ(1'b0),
      .CSYSACK(1'b0),
      .CACTIVE(1'b0)
   );

   initial assume(rst);

   always @(posedge clk) begin
      f_past_valid <= 1'b1;

      if (!f_past_valid)
         assume(rst);
      else
         assume(!rst);

      if (rst)
         ar_sent <= 1'b0;
      else if (s_axi_arvalid && s_axi_arready)
         ar_sent <= 1'b1;
   end

   always @(posedge clk) begin
      if (!rst) begin
         cv_m_ar_4kb_crossing: cover (
            m_axi_arvalid && m_axi_arburst == INCR && m_axi_araddr[11:0] == 12'hff0 &&
            m_axi_arlen == 8'h04 && m_axi_arsize == 3'd2
         );
      end
   end

endmodule

`default_nettype wire
