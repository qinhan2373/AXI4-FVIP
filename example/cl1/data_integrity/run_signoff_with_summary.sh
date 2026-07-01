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
work_name=${DI_WORK_NAME:-"cl1_bridge_data_integrity_${runset}_${mode}"}
work_root=${WORK_ROOT:-"${script_dir}/work/${work_name}"}
summary="${work_root}/summary.md"
overwrite_work=${DI_OVERWRITE_WORK:-1}

bridge_dir=${CL1_BRIDGE_DIR:-${example_dir}}
axi2cachebus_dir=${CL1_AXI2CACHEBUS_DIR:-${bridge_dir}}
bridge_dir=$(cd -- "${bridge_dir}" && pwd)
axi2cachebus_dir=$(cd -- "${axi2cachebus_dir}" && pwd)

bridge_rtl="${bridge_dir}/CacheBus2Axi4Top.sv"
axi2cachebus_rtl="${axi2cachebus_dir}/axi4toCacheBus.sv"

if [[ ! -f "${bridge_rtl}" ]]; then
  echo "Missing CL1 bridge RTL: ${bridge_rtl}" >&2
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

read_flags=""
keep_patterns=""
target_defs=""
target_desc=""

add_define() {
  read_flags="${read_flags} -D${1}"
}

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

single_bridge_commit_direct="*/c:ap_di_bridge_commit_model_matches_observer"
single_bridge_bridge_r="*/c:ap_di_bridge_rpath_tracked_r_preserved"
single_bridge_downstream_expected="*/c:ap_di_bridge_rpath_downstream_tracked_r_matches_expected"
single_bridge_memory_model="*/c:ap_di_bridge_commit_memory_matches_downstream_model"
single_bridge_commit_downstream_expected="*/c:ap_di_bridge_commit_expected_valid_when_seen */c:ap_di_bridge_commit_downstream_word_matches_expected */c:ap_di_bridge_commit_downstream_matches_expected"
single_bridge_commit_observer_expected="*/c:ap_di_bridge_commit_expected_valid_when_seen */c:ap_di_bridge_commit_observer_matches_expected"
single_bridge_readback_tracked="\
*/c:ap_di_common_wpath_aw_targets_tracked_addr \
*/c:ap_di_common_bpath_b_only_after_write_data \
*/c:ap_di_common_rpath_ar_after_write_commit \
*/c:ap_di_common_rpath_ar_targets_tracked_addr \
*/c:ap_di_common_readback_snapshot_created \
*/c:ap_di_common_readback_no_compare_without_snapshot \
*/c:ap_di_common_readback_rdata_matches_snapshot \
*/c:ap_di_common_readback_wstrb_matches_all_lanes \
*/c:ap_di_common_readback_wstrb_lane* \
*/c:ap_di_common_wstrb_write_commit_updates_enabled_lanes \
*/c:ap_di_common_wstrb_updates_enabled_lanes \
*/c:ap_di_common_wstrb_preserves_disabled_lanes \
*/c:ap_di_common_wstrb_no_update_before_bresp \
*/c:ap_di_common_wpath_aw_burst_profile \
*/c:ap_di_common_rpath_ar_burst_profile \
*/c:ap_di_common_rpath_read_response_okay \
*/c:ap_di_common_readback_snapshot_captures_tracked_beat \
*/c:ap_di_common_rpath_rlast_matches_expected_final_beat \
*/c:ap_di_common_wstrb_write_commit_updates_tracked_beat \
*/c:ap_di_common_wpath_wlast_matches_final_beat \
*/c:ap_di_common_wpath_write_beat_index_in_range"

declare -a targets=()
declare -a target_descs=()
declare -a target_defines=()
declare -a target_keeps=()

add_single_bridge_targets() {
  add_target \
    "upstream-bp" \
    "upstream B/R backpressure commit-direct target" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE" \
    "${single_bridge_commit_direct}"

  add_downstream_aww_allbeat_target
  add_downstream_ar_allbeat_targets
}

add_downstream_aww_allbeat_target() {
  add_target \
    "downstream-aww" \
    "downstream AW/W backpressure commit-direct target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_WRITE_ONLY_TRANSACTION AXI4_DI_WINDOW_DOWNSTREAM_AW_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_W_BACKPRESSURE" \
    "${single_bridge_commit_direct}"
}

add_downstream_ar_allbeat_targets() {
  add_target \
    "downstream-ar-readback-tracked" \
    "downstream AR backpressure readback-tracked target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_ASSUME_STRUCTURAL_PATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_readback_tracked}"

  add_target \
    "downstream-ar-bridge-r" \
    "downstream AR backpressure bridge-r target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_bridge_r}"

  add_target \
    "downstream-ar-downstream-expected" \
    "downstream AR backpressure downstream-expected target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_ASSUME_COMMIT_EXPECTED AXI4_DI_SINGLE_BRIDGE_ASSUME_MEMORY_MODEL AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_downstream_expected}"

  add_target \
    "downstream-ar-commit-downstream-expected" \
    "downstream AR helper commit-downstream-expected target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_commit_downstream_expected}"

  add_target \
    "downstream-ar-commit-observer-expected" \
    "downstream AR helper commit-observer-expected target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_commit_observer_expected}"

  add_target \
    "downstream-ar-memory-model" \
    "downstream AR helper memory-model target, all tracked beats" \
    "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
    "${single_bridge_memory_model}"
}

case "${runset}" in
  signoff|minimal)
    add_single_bridge_targets
    ;;
  full)
    add_single_bridge_targets
    ;;
  downstream-aww)
    add_downstream_aww_allbeat_target
    ;;
  downstream-ar)
    add_downstream_ar_allbeat_targets
    ;;
  downstream-ar-main)
    add_target \
      "downstream-ar-readback-tracked" \
      "downstream AR backpressure readback-tracked target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_ASSUME_STRUCTURAL_PATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_readback_tracked}"

    add_target \
      "downstream-ar-bridge-r" \
      "downstream AR backpressure bridge-r target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_bridge_r}"

    add_target \
      "downstream-ar-downstream-expected" \
      "downstream AR backpressure downstream-expected target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_ASSUME_COMMIT_EXPECTED AXI4_DI_SINGLE_BRIDGE_ASSUME_MEMORY_MODEL AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_downstream_expected}"
    ;;
  downstream-ar-helpers)
    add_target \
      "downstream-ar-commit-downstream-expected" \
      "downstream AR helper commit-downstream-expected target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_commit_downstream_expected}"

    add_target \
      "downstream-ar-commit-observer-expected" \
      "downstream AR helper commit-observer-expected target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_commit_observer_expected}"

    add_target \
      "downstream-ar-memory-model" \
      "downstream AR helper memory-model target, all tracked beats" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE AXI4_DI_WINDOW_DOWNSTREAM_AR_BACKPRESSURE" \
      "${single_bridge_memory_model}"
    ;;
  upstream-bp)
    add_target \
      "upstream-bp" \
      "upstream B/R backpressure commit-direct target" \
      "AXI4_DI_SINGLE_BRIDGE_ASSUME_WPATH AXI4_DI_SINGLE_BRIDGE_UPSTREAM_BACKPRESSURE" \
      "${single_bridge_commit_direct}"
    ;;
  *)
    echo "Unknown RUNSET=${runset}; supported: signoff, minimal, full, upstream-bp, downstream-aww, downstream-ar, downstream-ar-main, downstream-ar-helpers" >&2
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
read -formal -sv${flags} amba_axi4_di_single_bridge_source_properties.sv
read -formal -sv${flags} amba_axi4_di_single_bridge_data_integrity_properties.sv
read -formal -sv${flags} amba_axi4_di_single_bridge_source.sv
read -formal -sv${flags} amba_axi4_di_single_bridge_model.sv
read -formal -sv${flags} axi4toCacheBus.sv
read -formal -sv${flags} CacheBus2Axi4Top.sv
read -formal -sv${flags} data_integrity_single_bridge_smoke_tb.sv
prep -top data_integrity_single_bridge_smoke_tb
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
${root_dir}/vsrc/data_integrity/single_bridge/amba_axi4_di_single_bridge_source_properties.sv
${root_dir}/vsrc/data_integrity/single_bridge/amba_axi4_di_single_bridge_data_integrity_properties.sv
${root_dir}/vsrc/data_integrity/single_bridge/amba_axi4_di_single_bridge_source.sv
${root_dir}/vsrc/data_integrity/single_bridge/amba_axi4_di_single_bridge_model.sv
${axi2cachebus_rtl}
${bridge_rtl}
${script_dir}/data_integrity_single_bridge_smoke_tb.sv
EOF_SBY
}

{
  echo "# CL1 Bridge OSS Data-Integrity Signoff Summary"
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
done

echo
echo "Summary written to ${summary}"
exit "${status}"
