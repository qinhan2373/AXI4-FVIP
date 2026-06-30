# riscv-formal AXI Monitor 接入模板

该目录提供 OSS/SBY 环境下的 AXI protocol monitor 接入模板，用于把
`AXI4-OSS` 中的协议检查器接入 riscv-formal 流程。该模板只检查协议，
不包含数据一致性检查。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `riscv_formal_axi_monitor_template.sv` | 单个 AXI 接口的 monitor 封装模板，可在 riscv-formal testbench 中实例化多次。 |
| `riscv_formal_axi_monitor.sby.template` | SBY 文件模板，列出 OSS checker 所需的 `read -formal` 和 `[files]` 清单。 |

## 推荐接入位置

```text
riscv-formal testbench
  |
  |-- RVFI checker observes instruction retire
  |
  `-- DUT / SoC
        |
        |-- AXI master interface ---------------> riscv_formal_axi_monitor_template
        |
        `-- optional interconnect output -------> riscv_formal_axi_monitor_template
```

如果 DUT 顶层直接暴露 AXI 信号，直接连接 monitor。若 DUT 暴露的是
CoreBus、TileLink 或其他自定义总线，需要在对应 example/testbench 中加入
DUT 专属的 bus-to-AXI 观察转换头，再把转换后的 AXI 信号连接到 monitor。
该转换头属于 DUT 接入层，不放入公共 monitor 模板。

## 接入步骤

1. 将 `AXI4-OSS` 路径加入 riscv-formal 工程，或者把 `AXI4-OSS/vsrc`、
   `AXI4-OSS/formal/cl1_profile_filter.ys` 和本目录模板复制到工程内。
2. 在 riscv-formal 的 top/testbench 中实例化
   `riscv_formal_axi_monitor_template`，把 DUT 发出的 AXI 信号连接进去。
3. 按 `riscv_formal_axi_monitor.sby.template` 将 checker 源文件加入 SBY
   `[files]` 和 `[script]`。
4. 在 `prep -top <top>` 后执行 `script cl1_profile_filter.ys`，将检查范围限定
   为 CL1 当前支持的 AXI4 子集。
5. 运行 riscv-formal 原有任务，同时观察 AXI monitor 的 assert 结果。

## 实例化示例

```systemverilog
riscv_formal_axi_monitor_template #(
   .ID_WIDTH(2),
   .ADDRESS_WIDTH(32),
   .DATA_WIDTH(32),
   .MAX_WR_BURSTS(1),
   .MAX_RD_BURSTS(1),
   .MAX_WR_LENGTH(1),
   .MAX_RD_LENGTH(1)
) ibus_axi_monitor (
   .clock(clock),
   .reset(reset),

   .axi_aw_id('0),
   .axi_aw_addr('0),
   .axi_aw_len(8'h0),
   .axi_aw_size(3'h2),
   .axi_aw_burst(2'b01),
   .axi_aw_lock(1'b0),
   .axi_aw_cache(4'h0),
   .axi_aw_prot(3'h0),
   .axi_aw_qos(4'h0),
   .axi_aw_region(4'h0),
   .axi_aw_user('0),
   .axi_aw_valid(1'b0),
   .axi_aw_ready(1'b0),

   .axi_w_data('0),
   .axi_w_strb('0),
   .axi_w_last(1'b0),
   .axi_w_user('0),
   .axi_w_valid(1'b0),
   .axi_w_ready(1'b0),

   .axi_b_id('0),
   .axi_b_resp(2'b00),
   .axi_b_user('0),
   .axi_b_valid(1'b0),
   .axi_b_ready(1'b0),

   .axi_ar_id(ibus_arid),
   .axi_ar_addr(ibus_araddr),
   .axi_ar_len(ibus_arlen),
   .axi_ar_size(ibus_arsize),
   .axi_ar_burst(ibus_arburst),
   .axi_ar_lock(1'b0),
   .axi_ar_cache(4'h0),
   .axi_ar_prot(3'h0),
   .axi_ar_qos(4'h0),
   .axi_ar_region(4'h0),
   .axi_ar_user('0),
   .axi_ar_valid(ibus_arvalid),
   .axi_ar_ready(ibus_arready),

   .axi_r_id(ibus_rid),
   .axi_r_data(ibus_rdata),
   .axi_r_resp(ibus_rresp),
   .axi_r_last(ibus_rlast),
   .axi_r_user('0),
   .axi_r_valid(ibus_rvalid),
   .axi_r_ready(ibus_rready)
);
```

读-only 端口可以将 AW/W/B 通道 tie-off 为 idle，如上例所示。读写端口需要
连接全部五个 AXI 通道。

## 结果判读

monitor 是被动观察模块，不驱动 DUT，也不替代 riscv-formal 的 RVFI 检查。
当 AXI 协议被违反时，SBY 会报告对应的 FVIP assertion 名称，例如
`ap_AR_STABLE_ARADDR` 或 `ap_AW_STABLE_AWADDR`。这些名称来自
`AXI4-OSS/vsrc` 中的现有协议性质。

公开示例可参考：

```text
AXI4-OSS/example/cl1
AXI4-OSS/example/cl1_crossbar
```

这些 example 展示了在 SymbiYosys 环境中实例化 AXI monitor，并对 CL1
profile 范围内的 AXI 行为进行检查的方式。
