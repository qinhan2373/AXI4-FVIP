/*  AXI4 Formal Properties.
 *
 *  OSS-compatible AXI4 protocol checker wrapper.
 *
 *  This wrapper keeps the public interface of the original protocol checker,
 *  but passes flattened parameters into the five converted channel checkers.
 *  Low-power and exclusive-access cross-channel checkers are intentionally not
 *  instantiated here because they have not been converted in this OSS flow.
 */
`default_nettype none

module amba_axi4_protocol_checker_oss #(
   parameter int unsigned ID_WIDTH = 4,
   parameter int unsigned ADDRESS_WIDTH = 32,
   parameter int unsigned DATA_WIDTH = 64,
   parameter int unsigned AWUSER_WIDTH = 32,
   parameter int unsigned WUSER_WIDTH = 32,
   parameter int unsigned BUSER_WIDTH = 32,
   parameter int unsigned ARUSER_WIDTH = 32,
   parameter int unsigned RUSER_WIDTH = 32,
   parameter int unsigned MAX_WR_BURSTS = 4,
   parameter int unsigned MAX_RD_BURSTS = 4,
   parameter int unsigned MAX_WR_LENGTH = 8,
   parameter int unsigned MAX_RD_LENGTH = 8,
   parameter int unsigned MAXWAIT = 16,
   parameter int unsigned VERIFY_AGENT_TYPE = amba_axi4_protocol_checker_pkg::SOURCE,
   parameter int unsigned PROTOCOL_TYPE = amba_axi4_protocol_checker_pkg::AXI4LITE,
   parameter bit INTERFACE_REQS = 1'b1,
   parameter bit ENABLE_COVER = 1'b1,
   parameter bit ENABLE_XPROP = 1'b1,
   parameter bit ARM_RECOMMENDED = 1'b1,
   parameter bit CHECK_PARAMETERS = 1'b1,
   parameter bit OPTIONAL_WSTRB = 1'b1,
   parameter bit FULL_WR_STRB = 1'b1,
   parameter bit OPTIONAL_RESET = 1'b1,
   parameter bit FORMAL_INIT_GUARD = OPTIONAL_RESET,
   parameter bit EXCLUSIVE_ACCESS = 1'b1,
   parameter bit OPTIONAL_LP = 1'b1,
   localparam int unsigned STRB_WIDTH = DATA_WIDTH / 8
) (
   input wire                         ACLK,
   input wire                         ARESETn,

   // Write Address Channel (AW)
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

   // Write Data Channel (W)
   input wire [DATA_WIDTH-1:0]        WDATA,
   input wire [STRB_WIDTH-1:0]        WSTRB,
   input wire                         WLAST,
   input wire [WUSER_WIDTH-1:0]       WUSER,
   input wire                         WVALID,
   input wire                         WREADY,

   // Write Response Channel (B)
   input wire [ID_WIDTH-1:0]          BID,
   input wire [1:0]                   BRESP,
   input wire [BUSER_WIDTH-1:0]       BUSER,
   input wire                         BVALID,
   input wire                         BREADY,

   // Read Address Channel (AR)
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

   // Read Data Channel (R)
   input wire [ID_WIDTH-1:0]          RID,
   input wire [DATA_WIDTH-1:0]        RDATA,
   input wire [1:0]                   RRESP,
   input wire                         RLAST,
   input wire [RUSER_WIDTH-1:0]       RUSER,
   input wire                         RVALID,
   input wire                         RREADY,

   // Low Power Interface. Reserved here until the low-power checker is
   // converted to the same OSS-compatible style.
   input wire                         CSYSREQ,
   input wire                         CSYSACK,
   input wire                         CACTIVE,

   output wire                        proof_write_dep_aw_seen,
   output wire [ID_WIDTH-1:0]         proof_write_dep_awid,
   output wire [ADDRESS_WIDTH-1:0]    proof_write_dep_awaddr,
   output wire [7:0]                  proof_write_dep_awlen,
   output wire [2:0]                  proof_write_dep_awsize,
   output wire [1:0]                  proof_write_dep_awburst,
   output wire [8:0]                  proof_write_dep_w_count,
   output wire                        proof_write_dep_w_seen,
   output wire                        proof_write_dep_wlast_seen,
   output wire                        proof_read_dep_ar_seen,
   output wire [ID_WIDTH-1:0]         proof_read_dep_arid,
   output wire [7:0]                  proof_read_dep_arlen,
   output wire [8:0]                  proof_read_dep_r_count
);

   // Hide the formal initial sample from the converted channel checkers so
   // synchronous-reset DUT state can settle on the first reset clock edge.
   // Do not use an initial assume here: in the SBY/SMT flow it is preserved as
   // a normal assumption and makes the second time step unsatisfiable.
   reg checker_inputs_live = 1'b0;

   always @(posedge ACLK) begin
      checker_inputs_live <= 1'b1;
   end

   wire oss_checker_inputs_live = !FORMAL_INIT_GUARD || checker_inputs_live;
   wire oss_checker_aresetn = oss_checker_inputs_live && ARESETn;

   wire [ID_WIDTH-1:0] awid_checked = oss_checker_inputs_live ? AWID : '0;
   wire [ADDRESS_WIDTH-1:0] awaddr_checked = oss_checker_inputs_live ? AWADDR : '0;
   wire [7:0] awlen_checked = oss_checker_inputs_live ? AWLEN : '0;
   wire [2:0] awsize_checked = oss_checker_inputs_live ? AWSIZE : '0;
   wire [1:0] awburst_checked = oss_checker_inputs_live ? AWBURST : '0;
   wire awlock_checked = oss_checker_inputs_live ? AWLOCK : 1'b0;
   wire [3:0] awcache_checked = oss_checker_inputs_live ? AWCACHE : '0;
   wire [2:0] awprot_checked = oss_checker_inputs_live ? AWPROT : '0;
   wire [3:0] awqos_checked = oss_checker_inputs_live ? AWQOS : '0;
   wire [3:0] awregion_checked = oss_checker_inputs_live ? AWREGION : '0;
   wire [AWUSER_WIDTH-1:0] awuser_checked = oss_checker_inputs_live ? AWUSER : '0;
   wire awvalid_checked = oss_checker_inputs_live ? AWVALID : 1'b0;
   wire awready_checked = oss_checker_inputs_live ? AWREADY : 1'b0;

   wire [DATA_WIDTH-1:0] wdata_checked = oss_checker_inputs_live ? WDATA : '0;
   wire [STRB_WIDTH-1:0] wstrb_checked = oss_checker_inputs_live ? WSTRB : '0;
   wire wlast_checked = oss_checker_inputs_live ? WLAST : 1'b0;
   wire [WUSER_WIDTH-1:0] wuser_checked = oss_checker_inputs_live ? WUSER : '0;
   wire wvalid_checked = oss_checker_inputs_live ? WVALID : 1'b0;
   wire wready_checked = oss_checker_inputs_live ? WREADY : 1'b0;

   wire [ID_WIDTH-1:0] bid_checked = oss_checker_inputs_live ? BID : '0;
   wire [1:0] bresp_checked = oss_checker_inputs_live ? BRESP : '0;
   wire [BUSER_WIDTH-1:0] buser_checked = oss_checker_inputs_live ? BUSER : '0;
   wire bvalid_checked = oss_checker_inputs_live ? BVALID : 1'b0;
   wire bready_checked = oss_checker_inputs_live ? BREADY : 1'b0;

   wire [ID_WIDTH-1:0] arid_checked = oss_checker_inputs_live ? ARID : '0;
   wire [ADDRESS_WIDTH-1:0] araddr_checked = oss_checker_inputs_live ? ARADDR : '0;
   wire [7:0] arlen_checked = oss_checker_inputs_live ? ARLEN : '0;
   wire [2:0] arsize_checked = oss_checker_inputs_live ? ARSIZE : '0;
   wire [1:0] arburst_checked = oss_checker_inputs_live ? ARBURST : '0;
   wire arlock_checked = oss_checker_inputs_live ? ARLOCK : 1'b0;
   wire [3:0] arcache_checked = oss_checker_inputs_live ? ARCACHE : '0;
   wire [2:0] arprot_checked = oss_checker_inputs_live ? ARPROT : '0;
   wire [3:0] arqos_checked = oss_checker_inputs_live ? ARQOS : '0;
   wire [3:0] arregion_checked = oss_checker_inputs_live ? ARREGION : '0;
   wire [ARUSER_WIDTH-1:0] aruser_checked = oss_checker_inputs_live ? ARUSER : '0;
   wire arvalid_checked = oss_checker_inputs_live ? ARVALID : 1'b0;
   wire arready_checked = oss_checker_inputs_live ? ARREADY : 1'b0;

   wire [ID_WIDTH-1:0] rid_checked = oss_checker_inputs_live ? RID : '0;
   wire [DATA_WIDTH-1:0] rdata_checked = oss_checker_inputs_live ? RDATA : '0;
   wire [1:0] rresp_checked = oss_checker_inputs_live ? RRESP : '0;
   wire rlast_checked = oss_checker_inputs_live ? RLAST : 1'b0;
   wire [RUSER_WIDTH-1:0] ruser_checked = oss_checker_inputs_live ? RUSER : '0;
   wire rvalid_checked = oss_checker_inputs_live ? RVALID : 1'b0;
   wire rready_checked = oss_checker_inputs_live ? RREADY : 1'b0;

   wire                        proof_write_dep_aw_seen_internal;
   wire [ID_WIDTH-1:0]         proof_write_dep_awid_internal;
   wire [ADDRESS_WIDTH-1:0]    proof_write_dep_awaddr_internal;
   wire [7:0]                  proof_write_dep_awlen_internal;
   wire [2:0]                  proof_write_dep_awsize_internal;
   wire [1:0]                  proof_write_dep_awburst_internal;
   wire [8:0]                  proof_write_dep_w_count_internal;
   wire                        proof_write_dep_w_seen_internal;
   wire                        proof_write_dep_wlast_seen_internal;
   wire                        proof_read_dep_ar_seen_internal;
   wire [ID_WIDTH-1:0]         proof_read_dep_arid_internal;
   wire [7:0]                  proof_read_dep_arlen_internal;
   wire [8:0]                  proof_read_dep_r_count_internal;

   assign proof_write_dep_aw_seen = proof_write_dep_aw_seen_internal;
   assign proof_write_dep_awid = proof_write_dep_awid_internal;
   assign proof_write_dep_awaddr = proof_write_dep_awaddr_internal;
   assign proof_write_dep_awlen = proof_write_dep_awlen_internal;
   assign proof_write_dep_awsize = proof_write_dep_awsize_internal;
   assign proof_write_dep_awburst = proof_write_dep_awburst_internal;
   assign proof_write_dep_w_count = proof_write_dep_w_count_internal;
   assign proof_write_dep_w_seen = proof_write_dep_w_seen_internal;
   assign proof_write_dep_wlast_seen = proof_write_dep_wlast_seen_internal;
   assign proof_read_dep_ar_seen = proof_read_dep_ar_seen_internal;
   assign proof_read_dep_arid = proof_read_dep_arid_internal;
   assign proof_read_dep_arlen = proof_read_dep_arlen_internal;
   assign proof_read_dep_r_count = proof_read_dep_r_count_internal;

   amba_axi4_write_address_channel #(
      .ID_WIDTH(ID_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .AWUSER_WIDTH(AWUSER_WIDTH),
      .MAX_WR_BURSTS(MAX_WR_BURSTS),
      .MAX_WR_LENGTH(MAX_WR_LENGTH),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .INTERFACE_REQS(INTERFACE_REQS),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .CHECK_PARAMETERS(CHECK_PARAMETERS),
      .OPTIONAL_RESET(OPTIONAL_RESET),
      .EXCLUSIVE_ACCESS(EXCLUSIVE_ACCESS)
   ) AW_channel_checker (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .AWID(awid_checked),
      .AWADDR(awaddr_checked),
      .AWLEN(awlen_checked),
      .AWSIZE(awsize_checked),
      .AWBURST(awburst_checked),
      .AWLOCK(awlock_checked),
      .AWCACHE(awcache_checked),
      .AWPROT(awprot_checked),
      .AWQOS(awqos_checked),
      .AWREGION(awregion_checked),
      .AWUSER(awuser_checked),
      .AWVALID(awvalid_checked),
      .AWREADY(awready_checked)
   );

   amba_axi4_write_data_channel #(
      .DATA_WIDTH(DATA_WIDTH),
      .WUSER_WIDTH(WUSER_WIDTH),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .CHECK_PARAMETERS(CHECK_PARAMETERS),
      .OPTIONAL_WSTRB(OPTIONAL_WSTRB),
      .FULL_WR_STRB(FULL_WR_STRB),
      .OPTIONAL_RESET(OPTIONAL_RESET)
   ) W_channel_checker (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .WDATA(wdata_checked),
      .WSTRB(wstrb_checked),
      .WLAST(wlast_checked),
      .WUSER(wuser_checked),
      .WVALID(wvalid_checked),
      .WREADY(wready_checked)
   );

   amba_axi4_write_response_channel #(
      .ID_WIDTH(ID_WIDTH),
      .BUSER_WIDTH(BUSER_WIDTH),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .OPTIONAL_RESET(OPTIONAL_RESET),
      .EXCLUSIVE_ACCESS(EXCLUSIVE_ACCESS)
   ) B_channel_checker (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .BID(bid_checked),
      .BRESP(bresp_checked),
      .BUSER(buser_checked),
      .BVALID(bvalid_checked),
      .BREADY(bready_checked)
   );

`ifdef OSS_CL1_LIGHTWEIGHT_WRITE_DEPENDENCIES
   amba_axi4_write_response_dependencies_cl1_oss #(
`else
   amba_axi4_write_response_dependencies #(
`endif
      .ID_WIDTH(ID_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .MAX_WR_BURSTS(MAX_WR_BURSTS),
      .MAX_RD_BURSTS(MAX_RD_BURSTS),
      .MAX_WR_LENGTH(MAX_WR_LENGTH),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE)
   ) write_response_dependencies (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .AWID(awid_checked),
      .BID(bid_checked),
      .AWADDR(awaddr_checked),
      .AWLEN(awlen_checked),
      .AWSIZE(awsize_checked),
      .AWBURST(awburst_checked),
      .WSTRB(wstrb_checked),
      .BVALID(bvalid_checked),
      .BREADY(bready_checked),
      .AWVALID(awvalid_checked),
      .AWREADY(awready_checked),
      .WVALID(wvalid_checked),
      .WREADY(wready_checked),
      .WLAST(wlast_checked)
`ifdef OSS_CL1_LIGHTWEIGHT_WRITE_DEPENDENCIES
      ,
      .proof_aw_seen(proof_write_dep_aw_seen_internal),
      .proof_awid(proof_write_dep_awid_internal),
      .proof_awaddr(proof_write_dep_awaddr_internal),
      .proof_awlen(proof_write_dep_awlen_internal),
      .proof_awsize(proof_write_dep_awsize_internal),
      .proof_awburst(proof_write_dep_awburst_internal),
      .proof_w_count(proof_write_dep_w_count_internal),
      .proof_w_seen(proof_write_dep_w_seen_internal),
      .proof_wlast_seen(proof_write_dep_wlast_seen_internal)
`endif
   );

`ifndef OSS_CL1_LIGHTWEIGHT_WRITE_DEPENDENCIES
   assign proof_write_dep_aw_seen_internal = 1'b0;
   assign proof_write_dep_awid_internal = '0;
   assign proof_write_dep_awaddr_internal = '0;
   assign proof_write_dep_awlen_internal = '0;
   assign proof_write_dep_awsize_internal = '0;
   assign proof_write_dep_awburst_internal = '0;
   assign proof_write_dep_w_count_internal = '0;
   assign proof_write_dep_w_seen_internal = 1'b0;
   assign proof_write_dep_wlast_seen_internal = 1'b0;
`endif

   amba_axi4_read_address_channel #(
      .ID_WIDTH(ID_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ARUSER_WIDTH(ARUSER_WIDTH),
      .MAX_RD_BURSTS(MAX_RD_BURSTS),
      .MAX_RD_LENGTH(MAX_RD_LENGTH),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .CHECK_PARAMETERS(CHECK_PARAMETERS),
      .OPTIONAL_RESET(OPTIONAL_RESET),
      .EXCLUSIVE_ACCESS(EXCLUSIVE_ACCESS)
   ) AR_channel_checker (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .ARID(arid_checked),
      .ARADDR(araddr_checked),
      .ARLEN(arlen_checked),
      .ARSIZE(arsize_checked),
      .ARBURST(arburst_checked),
      .ARLOCK(arlock_checked),
      .ARCACHE(arcache_checked),
      .ARPROT(arprot_checked),
      .ARQOS(arqos_checked),
      .ARREGION(arregion_checked),
      .ARUSER(aruser_checked),
      .ARVALID(arvalid_checked),
      .ARREADY(arready_checked)
   );

   amba_axi4_read_data_channel #(
      .ID_WIDTH(ID_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .RUSER_WIDTH(RUSER_WIDTH),
      .MAX_RD_BURSTS(MAX_RD_BURSTS),
      .MAXWAIT(MAXWAIT),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE),
      .ENABLE_COVER(ENABLE_COVER),
      .ENABLE_XPROP(ENABLE_XPROP),
      .ARM_RECOMMENDED(ARM_RECOMMENDED),
      .CHECK_PARAMETERS(CHECK_PARAMETERS),
      .OPTIONAL_RESET(OPTIONAL_RESET),
      .EXCLUSIVE_ACCESS(EXCLUSIVE_ACCESS)
   ) R_channel_checker (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .ARID(arid_checked),
      .ARADDR(araddr_checked),
      .ARLEN(arlen_checked),
      .ARSIZE(arsize_checked),
      .ARBURST(arburst_checked),
      .ARVALID(arvalid_checked),
      .ARREADY(arready_checked),
      .RID(rid_checked),
      .RDATA(rdata_checked),
      .RRESP(rresp_checked),
      .RLAST(rlast_checked),
      .RUSER(ruser_checked),
      .RVALID(rvalid_checked),
      .RREADY(rready_checked)
   );

   amba_axi4_read_response_dependencies #(
      .ID_WIDTH(ID_WIDTH),
      .MAX_RD_BURSTS(MAX_RD_BURSTS),
      .MAX_RD_LENGTH(MAX_RD_LENGTH),
      .VERIFY_AGENT_TYPE(VERIFY_AGENT_TYPE),
      .PROTOCOL_TYPE(PROTOCOL_TYPE)
   ) read_response_dependencies (
      .ACLK(ACLK),
      .ARESETn(oss_checker_aresetn),
      .ARID(arid_checked),
      .RID(rid_checked),
      .ARLEN(arlen_checked),
      .ARVALID(arvalid_checked),
      .ARREADY(arready_checked),
      .RVALID(rvalid_checked),
      .RREADY(rready_checked),
      .RLAST(rlast_checked),
      .proof_ar_seen(proof_read_dep_ar_seen_internal),
      .proof_arid(proof_read_dep_arid_internal),
      .proof_arlen(proof_read_dep_arlen_internal),
      .proof_r_count(proof_read_dep_r_count_internal)
   );

   // Keep currently unsupported top-level options and low-power signals visible
   // without changing checker behavior.
   wire unused_oss_checker_inputs = OPTIONAL_LP ^ CSYSREQ ^ CSYSACK ^ CACTIVE;

endmodule // amba_axi4_protocol_checker_oss

`default_nettype wire
