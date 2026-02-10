#!/usr/bin/env bash
set -euo pipefail

# submit_error_learning_jobs.sh
#
# Purpose:
#   Generate per-amplicon sbatch files from a template containing placeholder "AMP",
#   then submit them via sbatch.
#
# Usage examples:
#   bash submit_error_learning_jobs.sh
#   bash submit_error_learning_jobs.sh --dry-run
#   bash submit_error_learning_jobs.sh --amplicons "ITS1,V1V2,V3V4"
#   bash submit_error_learning_jobs.sh --template hpc_workflows/dada2_pipeline/slurm/submit_error_learning.sbatch

DEFAULT_AMPLICONS="ITS1,V1V2,V2V3,V3V4,V4V5,V5V7,V7V9"
AMPLICONS_CSV="${DEFAULT_AMPLICONS}"

TEMPLATE="submit_error_learning.sbatch"
OUT_DIR="generated_sbatch"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: submit_error_learning_jobs.sh [options]

Options:
  --amplicons   Comma-separated list (default: ${DEFAULT_AMPLICONS})
  --template    Path to sbatch template (default: ${TEMPLATE})
  --out-dir     Directory for generated sbatch files (default: ${OUT_DIR})
  --dry-run     Print actions without running sbatch
  -h, --help    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --amplicons) AMPLICONS_CSV="$2"; shift 2 ;;
    --template)  TEMPLATE="$2"; shift 2 ;;
    --out-dir)   OUT_DIR="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "ERROR: sbatch template not found: ${TEMPLATE}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

IFS=',' read -r -a AMPLICONS <<< "${AMPLICONS_CSV}"

for amp in "${AMPLICONS[@]}"; do
  sbatch_file="${OUT_DIR}/submit_error_learning_${amp}.sbatch"

  sed "s/AMP/${amp}/g" "${TEMPLATE}" > "${sbatch_file}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "[DRY RUN] sbatch ${sbatch_file}"
  else
    job_id="$(sbatch "${sbatch_file}" | awk '{print $NF}')"
    echo "Submitted ${sbatch_file}  (job ${job_id})"
  fi
done

