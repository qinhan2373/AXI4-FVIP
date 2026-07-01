#!/usr/bin/env bash
set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd -- "${script_dir}/../../.." && pwd)
task=${1:-bmc}
sby_cmd=${SBY:-sby}
python_cmd=${PYTHON:-python3}

if [[ -d /home/ICer/oss-cad-suite/bin ]]; then
  export PATH="/home/ICer/oss-cad-suite/bin:${PATH}"
fi

cd "${script_dir}" || exit 1

status=0
"${sby_cmd}" -f data_integrity_single_bridge_smoke.sby "${task}" || status=$?

work_dir="data_integrity_single_bridge_smoke_${task}"
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
