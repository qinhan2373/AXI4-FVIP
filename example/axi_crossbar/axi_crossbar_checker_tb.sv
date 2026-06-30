`default_nettype none

module axi_crossbar_checker_tb (
   input wire clk,
   input wire rst
);

   localparam int unsigned SOURCE = amba_axi4_protocol_checker_pkg::SOURCE;
   localparam int unsigned DESTINATION = amba_axi4_protocol_checker_pkg::DESTINATION;
   localparam int unsigned AXI4FULL = amba_axi4_protocol_checker_pkg::AXI4FULL;

   localparam int unsigned DATA_WIDTH = 32;
   localparam int unsigned ADDR_WIDTH = 32;
   localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8;
   localparam int unsigned S_ID_WIDTH = 4;
   localparam int unsigned M_ID_WIDTH = 4;
   localparam int unsigned USER_WIDTH = 1;
   localparam int unsigned MAXWAIT = 20;

   reg f_past_valid = 1'b0;
   initial assume(rst);
   initial assume(!f_past_valid);

   always @(posedge clk) begin
      f_past_valid <= 1'b1;
      if (!f_past_valid)
         assume(rst);
      else
         assume(!rst);
   end

   (* anyseq *) logic [S_ID_WIDTH-1:0]  s_axi_awid;
   (* anyseq *) logic [ADDR_WIDTH-1:0]  s_axi_awaddr;
   (* anyseq *) logic [7:0]             s_axi_awlen;
   (* anyseq *) logic [2:0]             s_axi_awsize;
   (* anyseq *) logic [1:0]             s_axi_awburst;
   (* anyseq *) logic                   s_axi_awlock;
   (* anyseq *) logic [3:0]             s_axi_awcache;
   (* anyseq *) logic [2:0]             s_axi_awprot;
   (* anyseq *) logic [3:0]             s_axi_awqos;
   (* anyseq *) logic [USER_WIDTH-1:0]  s_axi_awuser;
   (* anyseq *) logic                   s_axi_awvalid;
   wire                                 s_axi_awready;

   (* anyseq *) logic [DATA_WIDTH-1:0]  s_axi_wdata;
   (* anyseq *) logic [STRB_WIDTH-1:0]  s_axi_wstrb;
   (* anyseq *) logic                   s_axi_wlast;
   (* anyseq *) logic [USER_WIDTH-1:0]  s_axi_wuser;
   (* anyseq *) logic                   s_axi_wvalid;
   wire                                 s_axi_wready;

   wire [S_ID_WIDTH-1:0]                s_axi_bid;
   wire [1:0]                           s_axi_bresp;
   wire [USER_WIDTH-1:0]                s_axi_buser;
   wire                                 s_axi_bvalid;
   (* anyseq *) logic                   s_axi_bready;

   (* anyseq *) logic [S_ID_WIDTH-1:0]  s_axi_arid;
   (* anyseq *) logic [ADDR_WIDTH-1:0]  s_axi_araddr;
   (* anyseq *) logic [7:0]             s_axi_arlen;
   (* anyseq *) logic [2:0]             s_axi_arsize;
   (* anyseq *) logic [1:0]             s_axi_arburst;
   (* anyseq *) logic                   s_axi_arlock;
   (* anyseq *) logic [3:0]             s_axi_arcache;
   (* anyseq *) logic [2:0]             s_axi_arprot;
   (* anyseq *) logic [3:0]             s_axi_arqos;
   (* anyseq *) logic [USER_WIDTH-1:0]  s_axi_aruser;
   (* anyseq *) logic                   s_axi_arvalid;
   wire                                 s_axi_arready;

   wire [S_ID_WIDTH-1:0]                s_axi_rid;
   wire [DATA_WIDTH-1:0]                s_axi_rdata;
   wire [1:0]                           s_axi_rresp;
   wire                                 s_axi_rlast;
   wire [USER_WIDTH-1:0]                s_axi_ruser;
   wire                                 s_axi_rvalid;
   (* anyseq *) logic                   s_axi_rready;

   wire [M_ID_WIDTH-1:0]                m_axi_awid;
   wire [ADDR_WIDTH-1:0]                m_axi_awaddr;
   wire [7:0]                           m_axi_awlen;
   wire [2:0]                           m_axi_awsize;
   wire [1:0]                           m_axi_awburst;
   wire                                 m_axi_awlock;
   wire [3:0]                           m_axi_awcache;
   wire [2:0]                           m_axi_awprot;
   wire [3:0]                           m_axi_awqos;
   wire [3:0]                           m_axi_awregion;
   wire [USER_WIDTH-1:0]                m_axi_awuser;
   wire                                 m_axi_awvalid;
   (* anyseq *) logic                   m_axi_awready;

   wire [DATA_WIDTH-1:0]                m_axi_wdata;
   wire [STRB_WIDTH-1:0]                m_axi_wstrb;
   wire                                 m_axi_wlast;
   wire [USER_WIDTH-1:0]                m_axi_wuser;
   wire                                 m_axi_wvalid;
   (* anyseq *) logic                   m_axi_wready;

   wire [M_ID_WIDTH-1:0]                m_axi_bid;
   wire [1:0]                           m_axi_bresp;
   wire [USER_WIDTH-1:0]                m_axi_buser;
   wire                                 m_axi_bvalid;
   wire                                 m_axi_bready;

   wire [M_ID_WIDTH-1:0]                m_axi_arid;
   wire [ADDR_WIDTH-1:0]                m_axi_araddr;
   wire [7:0]                           m_axi_arlen;
   wire [2:0]                           m_axi_arsize;
   wire [1:0]                           m_axi_arburst;
   wire                                 m_axi_arlock;
   wire [3:0]                           m_axi_arcache;
   wire [2:0]                           m_axi_arprot;
   wire [3:0]                           m_axi_arqos;
   wire [3:0]                           m_axi_arregion;
   wire [USER_WIDTH-1:0]                m_axi_aruser;
   wire                                 m_axi_arvalid;
   (* anyseq *) logic                   m_axi_arready;

   wire [M_ID_WIDTH-1:0]                m_axi_rid;
   wire [DATA_WIDTH-1:0]                m_axi_rdata;
   wire [1:0]                           m_axi_rresp;
   wire                                 m_axi_rlast;
   wire [USER_WIDTH-1:0]                m_axi_ruser;
   wire                                 m_axi_rvalid;
   wire                                 m_axi_rready;

   axi_crossbar #(
      .S_COUNT(1),
      .M_COUNT(1),
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

   wire m_axi_aw_fire = m_axi_awvalid && m_axi_awready;
   wire m_axi_w_fire = m_axi_wvalid && m_axi_wready;
   wire m_axi_b_fire = m_axi_bvalid && m_axi_bready;
   wire m_axi_ar_fire = m_axi_arvalid && m_axi_arready;
   wire m_axi_r_fire = m_axi_rvalid && m_axi_rready;

   reg slave_aw_pending = 1'b0;
   reg slave_wlast_pending = 1'b0;
   reg slave_bvalid = 1'b0;
   reg [M_ID_WIDTH-1:0] slave_bid = '0;
   reg slave_rvalid = 1'b0;
   reg [M_ID_WIDTH-1:0] slave_rid = '0;
   reg [7:0] slave_rbeats_left = 8'h00;

   always @(posedge clk) begin
      if (rst) begin
         slave_aw_pending <= 1'b0;
         slave_wlast_pending <= 1'b0;
         slave_bvalid <= 1'b0;
         slave_bid <= '0;
         slave_rvalid <= 1'b0;
         slave_rid <= '0;
         slave_rbeats_left <= 8'h00;
      end else begin
         if (m_axi_aw_fire) begin
            slave_aw_pending <= 1'b1;
            slave_bid <= m_axi_awid;
         end

         if (m_axi_w_fire && m_axi_wlast)
            slave_wlast_pending <= 1'b1;

         if (slave_bvalid) begin
            if (m_axi_b_fire)
               slave_bvalid <= 1'b0;
         end else if (slave_aw_pending && slave_wlast_pending) begin
            slave_bvalid <= 1'b1;
            slave_aw_pending <= 1'b0;
            slave_wlast_pending <= 1'b0;
         end

         if (slave_rvalid) begin
            if (m_axi_r_fire) begin
               if (slave_rbeats_left == 8'h00)
                  slave_rvalid <= 1'b0;
               else
                  slave_rbeats_left <= slave_rbeats_left - 8'h01;
            end
         end else if (m_axi_ar_fire) begin
            slave_rvalid <= 1'b1;
            slave_rid <= m_axi_arid;
            slave_rbeats_left <= m_axi_arlen;
         end
      end
   end

   assign m_axi_bid = slave_bid;
   assign m_axi_bresp = 2'b00;
   assign m_axi_buser = '0;
   assign m_axi_bvalid = slave_bvalid;
   assign m_axi_rid = slave_rid;
   assign m_axi_rdata = '0;
   assign m_axi_rresp = 2'b00;
   assign m_axi_rlast = slave_rvalid && (slave_rbeats_left == 8'h00);
   assign m_axi_ruser = '0;
   assign m_axi_rvalid = slave_rvalid;

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
      .MAX_WR_LENGTH(1),
      .MAX_RD_LENGTH(1),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(SOURCE),
      .PROTOCOL_TYPE(AXI4FULL),
      .INTERFACE_REQS(1'b1),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b1),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b1),
      .FULL_WR_STRB(1'b1),
      .OPTIONAL_RESET(1'b0),
      .FORMAL_INIT_GUARD(1'b1),
      .EXCLUSIVE_ACCESS(1'b1)
   ) source_chk (
      .ACLK(clk), .ARESETn(!rst),
      .AWID(m_axi_awid), .AWADDR(m_axi_awaddr), .AWLEN(m_axi_awlen), .AWSIZE(m_axi_awsize),
      .AWBURST(m_axi_awburst), .AWLOCK(m_axi_awlock), .AWCACHE(m_axi_awcache), .AWPROT(m_axi_awprot),
      .AWQOS(m_axi_awqos), .AWREGION(m_axi_awregion), .AWUSER(m_axi_awuser), .AWVALID(m_axi_awvalid),
      .AWREADY(m_axi_awready), .WDATA(m_axi_wdata), .WSTRB(m_axi_wstrb), .WLAST(m_axi_wlast),
      .WUSER(m_axi_wuser), .WVALID(m_axi_wvalid), .WREADY(m_axi_wready), .BID(m_axi_bid),
      .BRESP(m_axi_bresp), .BUSER(m_axi_buser), .BVALID(m_axi_bvalid), .BREADY(m_axi_bready),
      .ARID(m_axi_arid), .ARADDR(m_axi_araddr), .ARLEN(m_axi_arlen), .ARSIZE(m_axi_arsize),
      .ARBURST(m_axi_arburst), .ARLOCK(m_axi_arlock), .ARCACHE(m_axi_arcache), .ARPROT(m_axi_arprot),
      .ARQOS(m_axi_arqos), .ARREGION(m_axi_arregion), .ARUSER(m_axi_aruser), .ARVALID(m_axi_arvalid),
      .ARREADY(m_axi_arready), .RID(m_axi_rid), .RDATA(m_axi_rdata), .RRESP(m_axi_rresp),
      .RLAST(m_axi_rlast), .RUSER(m_axi_ruser), .RVALID(m_axi_rvalid), .RREADY(m_axi_rready),
      .CSYSREQ(1'b0), .CSYSACK(1'b0), .CACTIVE(1'b0)
   );

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(S_ID_WIDTH),
      .ADDRESS_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .AWUSER_WIDTH(USER_WIDTH),
      .WUSER_WIDTH(USER_WIDTH),
      .BUSER_WIDTH(USER_WIDTH),
      .ARUSER_WIDTH(USER_WIDTH),
      .RUSER_WIDTH(USER_WIDTH),
      .MAX_WR_BURSTS(1),
      .MAX_RD_BURSTS(1),
      .MAX_WR_LENGTH(1),
      .MAX_RD_LENGTH(1),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(DESTINATION),
      .PROTOCOL_TYPE(AXI4FULL),
      .INTERFACE_REQS(1'b1),
      .ENABLE_COVER(1'b1),
      .ENABLE_XPROP(1'b0),
      .ARM_RECOMMENDED(1'b0),
      .CHECK_PARAMETERS(1'b1),
      .OPTIONAL_WSTRB(1'b1),
      .FULL_WR_STRB(1'b1),
      .OPTIONAL_RESET(1'b0),
      .FORMAL_INIT_GUARD(1'b1),
      .EXCLUSIVE_ACCESS(1'b1)
   ) dest_chk (
      .ACLK(clk), .ARESETn(!rst),
      .AWID(s_axi_awid), .AWADDR(s_axi_awaddr), .AWLEN(s_axi_awlen), .AWSIZE(s_axi_awsize),
      .AWBURST(s_axi_awburst), .AWLOCK(s_axi_awlock), .AWCACHE(s_axi_awcache), .AWPROT(s_axi_awprot),
      .AWQOS(s_axi_awqos), .AWREGION(4'h0), .AWUSER(s_axi_awuser), .AWVALID(s_axi_awvalid),
      .AWREADY(s_axi_awready), .WDATA(s_axi_wdata), .WSTRB(s_axi_wstrb), .WLAST(s_axi_wlast),
      .WUSER(s_axi_wuser), .WVALID(s_axi_wvalid), .WREADY(s_axi_wready), .BID(s_axi_bid),
      .BRESP(s_axi_bresp), .BUSER(s_axi_buser), .BVALID(s_axi_bvalid), .BREADY(s_axi_bready),
      .ARID(s_axi_arid), .ARADDR(s_axi_araddr), .ARLEN(s_axi_arlen), .ARSIZE(s_axi_arsize),
      .ARBURST(s_axi_arburst), .ARLOCK(s_axi_arlock), .ARCACHE(s_axi_arcache), .ARPROT(s_axi_arprot),
      .ARQOS(s_axi_arqos), .ARREGION(4'h0), .ARUSER(s_axi_aruser), .ARVALID(s_axi_arvalid),
      .ARREADY(s_axi_arready), .RID(s_axi_rid), .RDATA(s_axi_rdata), .RRESP(s_axi_rresp),
      .RLAST(s_axi_rlast), .RUSER(s_axi_ruser), .RVALID(s_axi_rvalid), .RREADY(s_axi_rready),
      .CSYSREQ(1'b0), .CSYSACK(1'b0), .CACTIVE(1'b0)
   );

   always @(posedge clk) begin
      cover (!rst);
      cover (!rst && s_axi_arvalid);
      cover (!rst && s_axi_arvalid && s_axi_arready);
      cover (!rst && m_axi_arvalid);
      cover (!rst && m_axi_arvalid && m_axi_arready);
   end

endmodule

`default_nettype wire
