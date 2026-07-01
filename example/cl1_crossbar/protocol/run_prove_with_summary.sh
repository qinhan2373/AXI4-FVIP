#!/usr/bin/env bash
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
example_dir=$(cd -- "${script_dir}/.." && pwd)
root_dir=$(cd -- "${script_dir}/../../.." && pwd)
task=${1:-prove}
sby_cmd=${SBY:-sby}
python_cmd=${PYTHON:-python3}

crossbar_dir=${CL1_CROSSBAR_DIR:-${example_dir}}
axi2cachebus_dir=${CL1_CROSSBAR_AXI2CACHEBUS_DIR:-${crossbar_dir}}
crossbar_dir=$(cd -- "${crossbar_dir}" && pwd) || exit 1
axi2cachebus_dir=$(cd -- "${axi2cachebus_dir}" && pwd) || exit 1

crossbar_rtl="${crossbar_dir}/CrossbarCacheTop.sv"
axi2cachebus_rtl="${axi2cachebus_dir}/axi4toCacheBus.sv"
generated_sby=".cl1_crossbar_checker.generated.sby"

if [[ ! -f "${crossbar_rtl}" ]]; then
  echo "Missing CL1 crossbar RTL: ${crossbar_rtl}" >&2
  exit 1
fi

if [[ ! -f "${axi2cachebus_rtl}" ]]; then
  echo "Missing Axi4ToCacheBus RTL: ${axi2cachebus_rtl}" >&2
  exit 1
fi

cd "${script_dir}" || exit 1

sed \
  -e "s|read -formal -sv axi4toCacheBus.sv|read -formal -sv ${axi2cachebus_rtl}|" \
  -e "s|read -formal -sv CrossbarCacheTop.sv|read -formal -sv ${crossbar_rtl}|" \
  -e "s|^axi4toCacheBus.sv$|${axi2cachebus_rtl}|" \
  -e "s|^CrossbarCacheTop.sv$|${crossbar_rtl}|" \
  cl1_crossbar_checker.sby > "${generated_sby}"

status=0
"${sby_cmd}" -f "${generated_sby}" "${task}" || status=$?

work_dir=".cl1_crossbar_checker.generated_${task}"
summary_file="${work_dir}/property_summary.txt"
if [[ -d "${work_dir}" ]]; then
  if "${python_cmd}" "${root_dir}/ci/summarize_sby_properties.py" "${work_dir}" --write "${summary_file}" &&
     [[ -f "${summary_file}" && -f "${work_dir}/logfile.txt" ]]; then
    {
      echo ""
      echo "===== SBY PROPERTY SUMMARY ====="
      cat "${summary_file}"
    } >> "${work_dir}/logfile.txt"
    echo "Property summary written to ${summary_file}"
  fi
else
  echo "No SBY work directory found: ${work_dir}" >&2
fi

exit "${status}"
