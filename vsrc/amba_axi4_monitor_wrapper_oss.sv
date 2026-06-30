/* OSS-compatible AXI4 protocol monitor wrapper.
 *
 * This module keeps a simple flat-parameter interface for SBY/riscv-formal
 * environments and hides proof-only helper outputs from the converted checker.
 */
`default_nettype none

module amba_axi4_monitor_wrapper_oss #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 64,
   parameter int unsigned AWUSER_WIDTH = 1,
   parameter int unsigned WUSER_WIDTH = 1,
   parameter int unsigned BUSER_WIDTH = 1,
   parameter int unsigned ARUSER_WIDTH = 1,
   parameter int unsigned RUSER_WIDTH = 1,
   parameter int unsigned MAX_WR_BURSTS = 4,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAX_WR_LENGTH = 8,
   parameter int unsigned MAX_RD_LENGTH = 8,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::MONITOR,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4FULL,
   parameter bit INTERFACE_REQS = 1'b1,
   parameter bit ENABLE_COVER = 1'b0,
   parameter bit ENABLE_XPROP = 1'b0,
   parameter bit ARM_RECOMMENDED = 1'b0,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_WSTRB = 1'b1,
   parameter bit FULL_WR_STRB = 1'b0,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit FORMAL_INIT_GUARD = OPTIONAL_RESET,
   parameter bit EXCLUSIVE_ACCESS = 1'b0,
   parameter bit OPTIONAL_LP = 1'b0,
   localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8
) (
   input wire                         ACLK,
   input wire                         ARESETn,

   input wire [ID_WIDTH-1:0]          AWID,
   input wire [ADDRESS_WIDTH-1:0]     AWADDR,
   input wire [7:0]                   AWLEN,
   input wire [2:0]                   AWSIZE,
   input wire [1:0]                   AWBURST,
   input wire                         AWLOCK,
   input wire [3:0]                   AWCACHE,
   input wire [2:0]                   AWPROT,
   input wire [3:0]                   AWQOS,
   input wire [3:0]                   AWREGION,
   input wire [AWUSER_WIDTH-1:0]      AWUSER,
   input wire                         AWVALID,
   input wire                         AWREADY,

   input wire [DATA_WIDTH-1:0]        WDATA,
   input wire [STRB_WIDTH-1:0]        WSTRB,
   input wire                         WLAST,
   input wire [WUSER_WIDTH-1:0]       WUSER,
   input wire                         WVALID,
   input wire                         WREADY,

   input wire [ID_WIDTH-1:0]          BID,
   input wire [1:0]                   BRESP,
   input wire [BUSER_WIDTH-1:0]       BUSER,
   input wire                         BVALID,
   input wire                         BREADY,

   input wire [ID_WIDTH-1:0]          ARID,
   input wire [ADDRESS_WIDTH-1:0]     ARADDR,
   input wire [7:0]                   ARLEN,
   input wire [2:0]                   ARSIZE,
   input wire [1:0]                   ARBURST,
   input wire                         ARLOCK,
   input wire [3:0]                   ARCACHE,
   input wire [2:0]                   ARPROT,
   input wire [3:0]                   ARQOS,
   input wire [3:0]                   ARREGION,
   input wire [ARUSER_WIDTH-1:0]      ARUSER,
   input wire                         ARVALID,
   input wire                         ARREADY,

   input wire [ID_WIDTH-1:0]          RID,
   input wire [DATA_WIDTH-1:0]        RDATA,
   input wire [1:0]                   RRESP,
   input wire                         RLAST,
   input wire [RUSER_WIDTH-1:0]       RUSER,
   input wire                         RVALID,
   input wire                         RREADY,

   input wire                         CSYSREQ,
   input wire                         CSYSACK,
   input wire                         CACTIVE
);

   wire                        proof_write_dep_aw_seen;
   wire [ID_WIDTH-1:0]         proof_write_dep_awid;
   wire [ADDRESS_WIDTH-1:0]    proof_write_dep_awaddr;
   wire [7:0]                  proof_write_dep_awlen;
   wire [2:0]                  proof_write_dep_awsize;
   wire [1:0]                  proof_write_dep_awburst;
   wire [8:0]                  proof_write_dep_w_count;
   wire                        proof_write_dep_w_seen;
   wire                        proof_write_dep_wlast_seen;
   wire                        proof_read_dep_ar_seen;
   wire [ID_WIDTH-1:0]         proof_read_dep_arid;
   wire [7:0]                  proof_read_dep_arlen;
   wire [8:0]                  proof_read_dep_r_count;

   amba_axi4_protocol_checker_oss #(
      .ID_WIDTH(ID_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .AWUSER_WIDTH(AWUSER_WIDTH),
      .WUSER_WIDTH(WUSER_WIDTH),
      .BUSER_WIDTH(BUSER_WIDTH),
      .ARUSER_WIDTH(ARUSER_WIDTH),
      .RUSER_WIDTH(RUSER_WIDTH),
      .MAX_WR_BURSTS(MAX_WR_BURSTS),
      .MAX_RD_BURSTS(MAX_RD_BURSTS),
      .MAX_WR_LENGTH(MAX_WR_LENGTH),
      .MAX_RD_LENGTH(MAX_RD_LENGTH),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .INTERFACE_REQS(INTERFACE_REQS),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .CHECK_PARAMETERS(CHECK_PARAMETERS),
      .OPTIONAL_WSTRB(OPTIONAL_WSTRB),
      .FULL_WR_STRB(FULL_WR_STRB),
      .OPTIONAL_RESET(OPTIONAL_RESET),
      .FORMAL_INIT_GUARD(FORMAL_INIT_GUARD),
      .EXCLUSIVE_ACCESS(EXCLUSIVE_ACCESS),
      .OPTIONAL_LP(OPTIONAL_LP)
   ) axi_checker (
      .ACLK(ACLK),
      .ARESETn(ARESETn),
      .AWID(AWID),
      .AWADDR(AWADDR),
      .AWLEN(AWLEN),
      .AWSIZE(AWSIZE),
      .AWBURST(AWBURST),
      .AWLOCK(AWLOCK),
      .AWCACHE(AWCACHE),
      .AWPROT(AWPROT),
      .AWQOS(AWQOS),
      .AWREGION(AWREGION),
      .AWUSER(AWUSER),
      .AWVALID(AWVALID),
      .AWREADY(AWREADY),
      .WDATA(WDATA),
      .WSTRB(WSTRB),
      .WLAST(WLAST),
      .WUSER(WUSER),
      .WVALID(WVALID),
      .WREADY(WREADY),
      .BID(BID),
      .BRESP(BRESP),
      .BUSER(BUSER),
      .BVALID(BVALID),
      .BREADY(BREADY),
      .ARID(ARID),
      .ARADDR(ARADDR),
      .ARLEN(ARLEN),
      .ARSIZE(ARSIZE),
      .ARBURST(ARBURST),
      .ARLOCK(ARLOCK),
      .ARCACHE(ARCACHE),
      .ARPROT(ARPROT),
      .ARQOS(ARQOS),
      .ARREGION(ARREGION),
      .ARUSER(ARUSER),
      .ARVALID(ARVALID),
      .ARREADY(ARREADY),
      .RID(RID),
      .RDATA(RDATA),
      .RRESP(RRESP),
      .RLAST(RLAST),
      .RUSER(RUSER),
      .RVALID(RVALID),
      .RREADY(RREADY),
      .CSYSREQ(CSYSREQ),
      .CSYSACK(CSYSACK),
      .CACTIVE(CACTIVE),
      .proof_write_dep_aw_seen(proof_write_dep_aw_seen),
      .proof_write_dep_awid(proof_write_dep_awid),
      .proof_write_dep_awaddr(proof_write_dep_awaddr),
      .proof_write_dep_awlen(proof_write_dep_awlen),
      .proof_write_dep_awsize(proof_write_dep_awsize),
      .proof_write_dep_awburst(proof_write_dep_awburst),
      .proof_write_dep_w_count(proof_write_dep_w_count),
      .proof_write_dep_w_seen(proof_write_dep_w_seen),
      .proof_write_dep_wlast_seen(proof_write_dep_wlast_seen),
      .proof_read_dep_ar_seen(proof_read_dep_ar_seen),
      .proof_read_dep_arid(proof_read_dep_arid),
      .proof_read_dep_arlen(proof_read_dep_arlen),
      .proof_read_dep_r_count(proof_read_dep_r_count)
   );

endmodule

`default_nettype wire
