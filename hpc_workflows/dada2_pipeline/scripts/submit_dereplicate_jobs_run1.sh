#!/usr/bin/env bash
set -euo pipefail

# submit_dereplicate_jobs_run1.sh
#
# Purpose:
#   (Optional) generate per-amplicon R scripts, then generate per-amplicon sbatch files
#   from a template containing placeholder "AMP", and submit them via sbatch.
#
# Usage examples:
#   bash submit_dereplicate_jobs_run1.sh
#   bash submit_dereplicate_jobs_run1.sh --dry-run
#   bash submit_dereplicate_jobs_run1.sh --amplicons "ITS1,V1V2,V3V4"
#   bash submit_dereplicate_jobs_run1.sh --template hpc_workflows/dada2_pipeline/slurm/submit_dereplicate_run1.sbatch
#
# Notes:
#   - This script assumes the sbatch template contains the literal string "AMP" to substitute.
#   - By default it runs a local generator script if present (can be disabled with --no-generate).

DEFAULT_AMPLICONS="ITS1,V1V2,V2V3,V3V4,V4V5,V5V7,V7V9"
AMPLICONS_CSV="${DEFAULT_AMPLICONS}"

TEMPLATE="submit_dereplicate_run1.sbatch"
OUT_DIR="generated_sbatch"
DRY_RUN=0
RUN_GENERATOR=1
GENERATOR="create_dereplicate_scripts_run1.sh"

usage() {
  cat <<EOF
Usage: submit_dereplicate_jobs_run1.sh [options]

Options:
  --amplicons   Comma-separated list (default: ${DEFAULT_AMPLICONS})
  --template    Path to sbatch template (default: ${TEMPLATE})
  --out-dir     Directory for generated sbatch files (default: ${OUT_DIR})
  --no-generate Do not run the R-script generator step
  --generator   Path to generator script (default: ${GENERATOR})
  --dry-run     Print actions without running sbatch
  -h, --help    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --amplicons)   AMPLICONS_CSV="$2"; shift 2 ;;
    --template)    TEMPLATE="$2"; shift 2 ;;
    --out-dir)     OUT_DIR="$2"; shift 2 ;;
    --no-generate) RUN_GENERATOR=0; shift ;;
    --generator)   GENERATOR="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "ERROR: sbatch template not found: ${TEMPLATE}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

# Optional: generate per-amplicon R scripts first
if [[ "${RUN_GENERATOR}" -eq 1 ]]; then
  if [[ -f "${GENERATOR}" ]]; then
    if [[ "${DRY_RUN}" -eq 1 ]]; then
      echo "[DRY RUN] bash ${GENERATOR}"
    else
      bash "${GENERATOR}"
    fi
  else
    echo "WARNING: generator script not found (${GENERATOR}); continuing without generation." >&2
  fi
fi

IFS=',' read -r -a AMPLICONS <<< "${AMPLICONS_CSV}"

for amp in "${AMPLICONS[@]}"; do
  sbatch_file="${OUT_DIR}/submit_dereplicate_${amp}.sbatch"

  # Substitute literal AMP token
  sed "s/AMP/${amp}/g" "${TEMPLATE}" > "${sbatch_file}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "[DRY RUN] sbatch ${sbatch_file}"
  else
    job_id="$(sbatch "${sbatch_file}" | awk '{print $NF}')"
    echo "Submitted ${sbatch_file}  (job ${job_id})"
  fi
done

