#!/usr/bin/env bash
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd -- "${script_dir}/../.." && pwd)
task=${1:-prove}
sby_cmd=${SBY:-sby}
python_cmd=${PYTHON:-python3}

bridge_dir=${CL1_BRIDGE_DIR:-${script_dir}}
axi2cachebus_dir=${CL1_AXI2CACHEBUS_DIR:-${bridge_dir}}
bridge_dir=$(cd -- "${bridge_dir}" && pwd) || exit 1
axi2cachebus_dir=$(cd -- "${axi2cachebus_dir}" && pwd) || exit 1

bridge_rtl="${bridge_dir}/CacheBus2Axi4Top.sv"
axi2cachebus_rtl="${axi2cachebus_dir}/axi4toCacheBus.sv"
generated_sby=".cachebus2axi4_checker.generated.sby"

if [[ ! -f "${bridge_rtl}" ]]; then
  echo "Missing CL1 bridge RTL: ${bridge_rtl}" >&2
  exit 1
fi

if [[ ! -f "${axi2cachebus_rtl}" ]]; then
  echo "Missing Axi4ToCacheBus RTL: ${axi2cachebus_rtl}" >&2
  exit 1
fi

cd "${script_dir}" || exit 1

sed \
  -e "s|read -formal -sv axi4toCacheBus.sv|read -formal -sv ${axi2cachebus_rtl}|" \
  -e "s|read -formal -sv CacheBus2Axi4Top.sv|read -formal -sv ${bridge_rtl}|" \
  -e "s|^axi4toCacheBus.sv$|${axi2cachebus_rtl}|" \
  -e "s|^CacheBus2Axi4Top.sv$|${bridge_rtl}|" \
  cachebus2axi4_checker.sby > "${generated_sby}"

status=0
"${sby_cmd}" -f "${generated_sby}" "${task}" || status=$?

work_dir=".cachebus2axi4_checker.generated_${task}"
summary_file="${work_dir}/property_summary.txt"
if [[ -d "${work_dir}" ]]; then
  "${python_cmd}" "${root_dir}/ci/summarize_sby_properties.py" "${work_dir}" --write "${summary_file}"
  if [[ -f "${work_dir}/logfile.txt" ]]; then
    {
      echo ""
      echo "===== SBY PROPERTY SUMMARY ====="
      cat "${summary_file}"
    } >> "${work_dir}/logfile.txt"
  fi
  echo "Property summary written to ${summary_file}"
else
  echo "No SBY work directory found: ${work_dir}" >&2
fi

exit "${status}"
