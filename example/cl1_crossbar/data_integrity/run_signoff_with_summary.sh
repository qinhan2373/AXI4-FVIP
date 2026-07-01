#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
example_dir=$(cd -- "${script_dir}/.." && pwd)
root_dir=$(cd -- "${script_dir}/../../.." && pwd)
sby_cmd=${SBY:-sby}
python_cmd=${PYTHON:-python3}

if [[ -d /home/ICer/oss-cad-suite/bin ]]; then
  export PATH="/home/ICer/oss-cad-suite/bin:${PATH}"
fi

runset=${RUNSET:-signoff}
mode=${MODE:-bmc}
depth=${DEPTH:-64}
quiet=${QUIET:-0}
protocol_constraints=${DI_PROTOCOL_CONSTRAINTS:-0}
keep_going=${DI_KEEP_GOING:-0}
timestamp=${TIMESTAMP:-$(date +%Y%m%d_%H%M%S)}
work_name=${DI_WORK_NAME:-"cl1_crossbar_data_integrity_${runset}_${mode}"}
work_root=${WORK_ROOT:-"${script_dir}/work/${work_name}"}
summary="${work_root}/summary.md"
overwrite_work=${DI_OVERWRITE_WORK:-1}

crossbar_dir=${CL1_CROSSBAR_DIR:-${example_dir}}
axi2cachebus_dir=${CL1_CROSSBAR_AXI2CACHEBUS_DIR:-${crossbar_dir}}
crossbar_dir=$(cd -- "${crossbar_dir}" && pwd)
axi2cachebus_dir=$(cd -- "${axi2cachebus_dir}" && pwd)

crossbar_rtl="${crossbar_dir}/CrossbarCacheTop.sv"
axi2cachebus_rtl="${axi2cachebus_dir}/axi4toCacheBus.sv"

if [[ ! -f "${crossbar_rtl}" ]]; then
  echo "Missing CL1 crossbar RTL: ${crossbar_rtl}" >&2
  exit 1
fi

if [[ ! -f "${axi2cachebus_rtl}" ]]; then
  echo "Missing Axi4ToCacheBus RTL: ${axi2cachebus_rtl}" >&2
  exit 1
fi

if [[ "${overwrite_work}" == "1" ]]; then
  rm -rf "${work_root}"
fi
mkdir -p "${work_root}"

declare -a targets=()
declare -a target_descs=()
declare -a target_defines=()
declare -a target_keeps=()

add_target() {
  local name=$1
  local desc=$2
  local defs=$3
  local keeps=$4

  targets+=("${name}")
  target_descs+=("${desc}")
  target_defines+=("${defs}")
  target_keeps+=("${keeps}")
}

base_defs="\
CL1_XBAR_DI_ENABLE \
CL1_XBAR_SYMBOLIC_ADDR_MODE \
CL1_XBAR_ENABLE_PROOF_IF \
AXI4_DI_CROSSBAR_DI_ENABLE \
AXI4_DI_CROSSBAR_SYMBOLIC_ADDR_MODE \
AXI4_DI_CROSSBAR_SYMBOLIC_WDATA \
AXI4_DI_CROSSBAR_SYMBOLIC_WSTRB"

wpath_helper_defs="\
AXI4_DI_CROSSBAR_ASSUME_PROOF_HELPERS_WPATH_PREREQ"

wpath_closure_defs="\
${wpath_helper_defs} \
AXI4_DI_CROSSBAR_ASSUME_WPATH \
AXI4_DI_CROSSBAR_ASSUME_WPATH_COMMIT_ACTUAL \
AXI4_DI_CROSSBAR_ASSUME_COMMIT_SEEN \
AXI4_DI_CROSSBAR_ASSUME_COMMIT_SOURCE_VALID \
AXI4_DI_CROSSBAR_ASSUME_COMMIT_ACTUAL_BEFORE_B"

rpath_helper_defs="\
AXI4_DI_CROSSBAR_ASSUME_PROOF_HELPERS_READ_PIPE \
AXI4_DI_CROSSBAR_ASSUME_AR_REQUEST_CONTRACT \
AXI4_DI_CROSSBAR_ASSUME_READ_SNAPSHOT_CONTRACT \
AXI4_DI_CROSSBAR_ASSUME_READ_SNAPSHOT_MEMORY_MODEL \
AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_READ_CONTROL \
AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_NO_WRITE_DURING_READ \
AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_MEMORY_EXPECTED_LANES \
AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_EXPECTED_LANES \
AXI4_DI_CROSSBAR_ASSUME_DOWNSTREAM_R_LATCH_EXPECTED \
AXI4_DI_CROSSBAR_ASSUME_RPATH_PRELUDE \
AXI4_DI_CROSSBAR_ASSUME_RPATH_LOCAL \
AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_IMAGE \
AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_EXPECTED \
AXI4_DI_CROSSBAR_ASSUME_RPATH_FIFO_LATCH \
AXI4_DI_CROSSBAR_ASSUME_RPATH_DOWNSTREAM_PAIR \
AXI4_DI_CROSSBAR_ASSUME_RPATH_EXPECTED_DOWNSTREAM \
AXI4_DI_CROSSBAR_ASSUME_SOURCE_R_DOWNSTREAM"

proof_helper_wpath_targets="\
*/c:inv_di_xbar_cachebus_* \
*/c:inv_di_xbar_axi2cb_* \
*/c:inv_di_xbar_write_pipe_* \
*/c:inv_di_xbar_buscut_* \
*/c:inv_di_xbar_downstream_last_no_pending_nonlast \
*/c:inv_di_xbar_selected_awlen_matches_source"

proof_helper_read_targets="\
*/c:inv_di_xbar_read_pipe_*"

wpath_base_targets="\
*/c:ap_di_xbar_output_aw_matches_tracked \
*/c:ap_di_xbar_output_w_expected_valid \
*/c:ap_di_xbar_output_w_data_matches_write \
*/c:ap_di_xbar_output_w_strb_matches_write \
*/c:ap_di_xbar_output_w_last_matches_write \
*/c:ap_di_xbar_output_w_tracked_matches_write \
*/c:ap_di_xbar_output_w_fifo_no_overflow"

wpath_commit_targets="\
*/c:ap_di_xbar_output_w_commit_actual_valid \
*/c:ap_di_xbar_output_w_commit_actual_lane* \
*/c:ap_di_xbar_output_w_commit_actual_matches_source \
*/c:ap_di_xbar_commit_downstream_seen_before_b \
*/c:ap_di_xbar_commit_source_expected_valid_before_b \
*/c:ap_di_xbar_commit_actual_matches_before_b"

commit_direct_target="\
*/c:ap_di_xbar_commit_model_matches_observer"

downstream_ar_targets="\
*/c:ap_di_xbar_output_ar_matches_tracked \
*/c:ap_di_xbar_read_snapshot_created \
*/c:ap_di_xbar_read_snapshot_captures_tracked_beat \
*/c:ap_di_xbar_no_compare_without_snapshot \
*/c:ap_di_xbar_read_snapshot_matches_memory_model \
*/c:ap_di_xbar_downstream_read_active_matches_memory \
*/c:ap_di_xbar_downstream_read_index_matches_memory \
*/c:ap_di_xbar_downstream_tracked_beat_matches_memory \
*/c:ap_di_xbar_downstream_no_write_during_read \
*/c:ap_di_xbar_downstream_memory_expected_lane* \
*/c:ap_di_xbar_downstream_tracked_r_matches_expected \
*/c:ap_di_xbar_downstream_expected_valid \
*/c:ap_di_xbar_downstream_expected_resp_okay \
*/c:ap_di_xbar_downstream_expected_lane* \
*/c:ap_di_xbar_downstream_tracked_r_latch_matches_expected \
*/c:ap_di_xbar_downstream_tracked_r_latch_lane* \
*/c:ap_di_xbar_bridge_tracked_r_preserved \
*/c:ap_di_xbar_rpath_expected_valid \
*/c:ap_di_xbar_rpath_data_matches_bridge \
*/c:ap_di_xbar_rpath_data_lane* \
*/c:ap_di_xbar_rpath_last_matches_bridge \
*/c:ap_di_xbar_rpath_tracked_matches_bridge \
*/c:ap_di_xbar_rpath_fifo_no_overflow \
*/c:ap_di_xbar_rpath_fifo_entry*_image_matches_bridge \
*/c:ap_di_xbar_rpath_fifo_entry*_expected_matches_downstream \
*/c:ap_di_xbar_rpath_fifo_entry*_latch_matches_downstream \
*/c:ap_di_xbar_rpath_downstream_image_matches_bridge \
*/c:ap_di_xbar_rpath_downstream_image_matches_latch \
*/c:ap_di_xbar_rpath_expected_tracked_matches_downstream \
*/c:ap_di_xbar_rpath_resp_okay_when_tracked \
*/c:ap_di_xbar_rpath_source_r_matches_downstream_tracked \
*/c:ap_di_xbar_rdata_matches_snapshot \
*/c:ap_di_xbar_rlast_matches_expected_final_beat \
*/c:ap_di_xbar_wstrb_lane*_readback \
*/c:ap_di_xbar_wstrb_readback_matches_all_lanes"

downstream_memory_targets="\
*/c:ap_di_xbar_memory_*"

add_write_commit_targets() {
  local profile_name=$1
  local profile_defs=$2

  add_target \
    "${profile_name}-proof-helper-wpath-prereq" \
    "crossbar proof-only write-path prerequisite invariants" \
    "${base_defs} ${profile_defs}" \
    "${proof_helper_wpath_targets}"

  add_target \
    "${profile_name}-wpath-base" \
    "source-to-downstream AW/W tracked write-path data transfer" \
    "${base_defs} ${profile_defs} ${wpath_helper_defs}" \
    "${wpath_base_targets}"

  add_target \
    "${profile_name}-wpath-commit" \
    "write commit actual/seen/source-valid helper set" \
    "${base_defs} ${profile_defs} ${wpath_helper_defs} AXI4_DI_CROSSBAR_ASSUME_WPATH" \
    "${wpath_commit_targets}"
}

add_downstream_aww_targets() {
  local profile_defs="\
CL1_XBAR_DI_WRITE_ONLY_TRANSACTION \
AXI4_DI_CROSSBAR_DI_WRITE_ONLY_TRANSACTION \
AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE \
AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE"

  add_write_commit_targets "downstream-aww" "${profile_defs}"
  add_target \
    "downstream-aww-main" \
    "downstream AW/W backpressure write commit signoff sink" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs}" \
    "${commit_direct_target}"
}

add_upstream_bp_targets() {
  local profile_defs="\
AXI4_DI_CROSSBAR_UPSTREAM_BACKPRESSURE"

  add_write_commit_targets "upstream-bp" "${profile_defs}"
  add_target \
    "upstream-bp-write-main" \
    "upstream B/R backpressure write commit signoff sink" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs}" \
    "${commit_direct_target}"
  add_target \
    "upstream-bp-readback" \
    "upstream B/R backpressure readback signoff property set" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs} ${rpath_helper_defs}" \
    "${downstream_ar_targets}"
}

add_downstream_ar_targets() {
  local profile_defs="\
AXI4_DI_CROSSBAR_UPSTREAM_BACKPRESSURE \
AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE"

  add_write_commit_targets "downstream-ar" "${profile_defs}"
  add_target \
    "proof-helper-read-pipe" \
    "crossbar proof-only read-pipeline invariants" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs}" \
    "${proof_helper_read_targets}"
  add_target \
    "downstream-ar-memory" \
    "downstream memory read/write data contract property set" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs}" \
    "${downstream_memory_targets}"
  add_target \
    "downstream-ar-main" \
    "downstream AR backpressure readback signoff property set" \
    "${base_defs} ${profile_defs} ${wpath_closure_defs} ${rpath_helper_defs} AXI4_DI_CROSSBAR_ASSUME_MEMORY_MODEL" \
    "${downstream_ar_targets}"
}

case "${runset}" in
  signoff|minimal|full)
    add_upstream_bp_targets
    add_downstream_aww_targets
    add_downstream_ar_targets
    ;;
  upstream-bp)
    add_upstream_bp_targets
    ;;
  downstream-aww)
    add_downstream_aww_targets
    ;;
  downstream-aww-main)
    add_target \
      "downstream-aww-main" \
      "downstream AW/W backpressure write commit signoff sink" \
      "${base_defs} CL1_XBAR_DI_WRITE_ONLY_TRANSACTION AXI4_DI_CROSSBAR_DI_WRITE_ONLY_TRANSACTION AXI4_DI_CROSSBAR_DOWNSTREAM_AW_BACKPRESSURE AXI4_DI_CROSSBAR_DOWNSTREAM_W_BACKPRESSURE ${wpath_closure_defs}" \
      "${commit_direct_target}"
    ;;
  downstream-ar)
    add_downstream_ar_targets
    ;;
  downstream-ar-main)
    add_target \
      "downstream-ar-main" \
      "downstream AR backpressure readback signoff property set" \
      "${base_defs} AXI4_DI_CROSSBAR_UPSTREAM_BACKPRESSURE AXI4_DI_CROSSBAR_DOWNSTREAM_AR_BACKPRESSURE ${wpath_closure_defs} ${rpath_helper_defs} AXI4_DI_CROSSBAR_ASSUME_MEMORY_MODEL" \
      "${downstream_ar_targets}"
    ;;
  proof-helpers)
    add_target \
      "proof-helper-wpath-prereq" \
      "crossbar proof-only write-path prerequisite invariants" \
      "${base_defs}" \
      "${proof_helper_wpath_targets}"
    add_target \
      "proof-helper-read-pipe" \
      "crossbar proof-only read-pipeline invariants" \
      "${base_defs}" \
      "${proof_helper_read_targets}"
    ;;
  compile-smoke)
    add_target \
      "compile-smoke" \
      "single low-cost property used to validate parsing and target selection" \
      "${base_defs}" \
      "*/c:ap_di_xbar_output_aw_matches_tracked"
    ;;
  *)
    echo "Unknown RUNSET=${runset}; supported: signoff, minimal, full, upstream-bp, downstream-aww, downstream-aww-main, downstream-ar, downstream-ar-main, proof-helpers, compile-smoke" >&2
    exit 2
    ;;
esac

write_sby() {
  local path=$1
  local defs=$2
  local keeps=$3
  local flags=""
  local engine_opts=""
  local remove_protocol_constraints=""
  local def

  for def in ${defs}; do
    flags="${flags} -D${def}"
  done

  if [[ "${keep_going}" == "1" ]]; then
    engine_opts=" --keep-going"
  fi

  if [[ "${protocol_constraints}" != "1" ]]; then
    remove_protocol_constraints=$'select -set protocol_constraints */c:cp_*\nchformal -assume -remove @protocol_constraints'
  fi

  cat > "${path}" <<EOF_SBY
[options]
mode ${mode}
depth ${depth}
expect pass

[engines]
smtbmc${engine_opts} boolector

[script]
read -formal -sv${flags} amba_axi4_protocol_checker_pkg.sv
read -formal -sv${flags} oss_amba_axi4_definition_of_axi4_lite.sv
read -formal -sv${flags} oss_amba_axi4_single_interface_requirements.sv
read -formal -sv${flags} oss_amba_axi4_transaction_structure.sv
read -formal -sv${flags} oss_amba_axi4_transaction_attributes.sv
read -formal -sv${flags} oss_amba_axi4_atomic_accesses.sv
read -formal -sv${flags} amba_axi4_write_address_channel.oss.sv
read -formal -sv${flags} amba_axi4_write_data_channel.oss.sv
read -formal -sv${flags} amba_axi4_write_response_channel.oss.sv
read -formal -sv${flags} amba_axi4_read_address_channel.oss.sv
read -formal -sv${flags} amba_axi4_read_data_channel.oss.sv
read -formal -sv${flags} amba_axi4_write_response_dependencies.oss.sv
read -formal -sv${flags} amba_axi4_write_response_dependencies_cl1_oss.sv
read -formal -sv${flags} amba_axi4_read_response_dependencies.oss.sv
read -formal -sv${flags} -DOSS_CL1_LIGHTWEIGHT_WRITE_DEPENDENCIES amba_axi4_protocol_checker_oss.sv
read -formal -sv${flags} amba_axi4_data_integrity_pkg.sv
read -formal -sv${flags} amba_axi4_di_golden_memory_core.sv
read -formal -sv${flags} amba_axi4_data_integrity_word_properties.sv
read -formal -sv${flags} amba_axi4_data_integrity_window_properties.sv
read -formal -sv${flags} amba_axi4_data_integrity_window.sv
read -formal -sv${flags} amba_axi4_di_crossbar_source_driver_properties.sv
read -formal -sv${flags} amba_axi4_di_crossbar_downstream_memory_properties.sv
read -formal -sv${flags} amba_axi4_di_crossbar_data_integrity_properties.sv
read -formal -sv${flags} amba_axi4_di_crossbar_observer_properties.sv
read -formal -sv${flags} amba_axi4_di_crossbar_proof_helpers.sv
read -formal -sv${flags} amba_axi4_di_crossbar_axi_source_driver.sv
read -formal -sv${flags} amba_axi4_di_crossbar_model.sv
read -formal -sv${flags} amba_axi4_di_crossbar_downstream_golden_memory.sv
read -formal -sv${flags} amba_axi4_di_crossbar_observers.sv
read -formal -sv${flags} amba_axi4_di_crossbar_smoke_covers.sv
read -formal -sv${flags} axi4toCacheBus.sv
read -formal -sv${flags} CrossbarCacheTop.sv
read -formal -sv${flags} data_integrity_crossbar_tb.sv
prep -top data_integrity_crossbar_tb
chformal -cover -remove
${remove_protocol_constraints}
select -set keep ${keeps}
select -assert-min 1 @keep
chformal -assert -remove @keep %n

[files]
${root_dir}/vsrc/amba_axi4_protocol_checker_pkg.sv
${root_dir}/vsrc/axi4_spec/oss_amba_axi4_definition_of_axi4_lite.sv
${root_dir}/vsrc/axi4_spec/oss_amba_axi4_single_interface_requirements.sv
${root_dir}/vsrc/axi4_spec/oss_amba_axi4_transaction_structure.sv
${root_dir}/vsrc/axi4_spec/oss_amba_axi4_transaction_attributes.sv
${root_dir}/vsrc/axi4_spec/oss_amba_axi4_atomic_accesses.sv
${root_dir}/vsrc/amba_axi4_write_address_channel.oss.sv
${root_dir}/vsrc/amba_axi4_write_data_channel.oss.sv
${root_dir}/vsrc/amba_axi4_write_response_channel.oss.sv
${root_dir}/vsrc/amba_axi4_read_address_channel.oss.sv
${root_dir}/vsrc/amba_axi4_read_data_channel.oss.sv
${root_dir}/vsrc/axi4_lib/amba_axi4_write_response_dependencies.oss.sv
${root_dir}/vsrc/axi4_lib/amba_axi4_write_response_dependencies_cl1_oss.sv
${root_dir}/vsrc/axi4_lib/amba_axi4_read_response_dependencies.oss.sv
${root_dir}/vsrc/amba_axi4_protocol_checker_oss.sv
${root_dir}/vsrc/data_integrity/amba_axi4_data_integrity_pkg.sv
${root_dir}/vsrc/data_integrity/amba_axi4_di_golden_memory_core.sv
${root_dir}/vsrc/data_integrity/amba_axi4_data_integrity_word_properties.sv
${root_dir}/vsrc/data_integrity/amba_axi4_data_integrity_window_properties.sv
${root_dir}/vsrc/data_integrity/amba_axi4_data_integrity_window.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_source_driver_properties.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_downstream_memory_properties.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_data_integrity_properties.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_observer_properties.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_proof_helpers.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_axi_source_driver.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_model.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_downstream_golden_memory.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_observers.sv
${root_dir}/vsrc/data_integrity/crossbar/amba_axi4_di_crossbar_smoke_covers.sv
${axi2cachebus_rtl}
${crossbar_rtl}
${script_dir}/data_integrity_crossbar_tb.sv
EOF_SBY
}

{
  echo "# CL1 Crossbar OSS Data-Integrity Signoff Summary"
  echo
  echo "- runset: ${runset}"
  echo "- mode: ${mode}"
  echo "- depth: ${depth}"
  echo "- work_dir: ${work_root}"
  echo "- protocol_constraints: ${protocol_constraints}"
  echo "- keep_going: ${keep_going}"
  echo "- overwrite_work: ${overwrite_work}"
  echo "- generated: ${timestamp}"
  echo
  echo "| Target | Result | Runtime | Assertions | Log |"
  echo "| --- | --- | ---: | ---: | --- |"
} > "${summary}"

status=0
for index in "${!targets[@]}"; do
  target=${targets[${index}]}
  desc=${target_descs[${index}]}
  defs=${target_defines[${index}]}
  keeps=${target_keeps[${index}]}
  target_dir="${work_root}/${target}"
  sby_file="${target_dir}/${target}.sby"
  sby_work="${target_dir}/${target}_${mode}"
  prop_summary="${sby_work}/property_summary.txt"
  console_log="${target_dir}/sby.console.log"
  start_epoch=$(date +%s)

  mkdir -p "${target_dir}"
  write_sby "${sby_file}" "${defs}" "${keeps}"

  echo "Running ${target}: ${desc}"
  if [[ "${quiet}" == "1" ]]; then
    if (cd "${target_dir}" && "${sby_cmd}" -f -d "${target}_${mode}" "${target}.sby") >"${console_log}" 2>&1; then
      result="PASS"
    else
      result="FAIL"
      status=1
      tail -80 "${console_log}" >&2 || true
    fi
  elif (cd "${target_dir}" && "${sby_cmd}" -f -d "${target}_${mode}" "${target}.sby"); then
    result="PASS"
  else
    result="FAIL"
    status=1
  fi

  end_epoch=$(date +%s)
  runtime="$((end_epoch - start_epoch))s"
  assertion_count="n/a"

  if [[ -d "${sby_work}" ]]; then
    "${python_cmd}" "${root_dir}/ci/summarize_sby_properties.py" "${sby_work}" --write "${prop_summary}" >/dev/null || true
    if [[ -f "${prop_summary}" ]]; then
      assertion_count=$(awk '/^ASSERT:/ {print $2; exit}' "${prop_summary}")
      {
        echo ""
        echo "===== SBY PROPERTY SUMMARY ====="
        cat "${prop_summary}"
      } >> "${sby_work}/logfile.txt"
    fi
  fi

  rel_log="${sby_work#${script_dir}/}/logfile.txt"
  echo "| ${target} | ${result} | ${runtime} | ${assertion_count} | \`${rel_log}\` |" >> "${summary}"

  if [[ "${status}" != "0" && "${keep_going}" != "1" ]]; then
    break
  fi
done

echo
echo "Summary written to ${summary}"
exit "${status}"
