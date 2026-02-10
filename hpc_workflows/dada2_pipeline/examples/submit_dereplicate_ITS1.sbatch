#!/usr/bin/env bash
#SBATCH --job-name=dereplicate_ITS1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=05:00:00
#SBATCH --partition=single
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
##SBATCH --account=YOUR_ACCOUNT   # optional: uncomment if required on your cluster

set -euo pipefail
mkdir -p logs

# ----------------------------
# Configurable paths
# ----------------------------
PIPELINE_ROOT="${PIPELINE_ROOT:-/path/to/run1}"
SCRIPTS_DIR="${SCRIPTS_DIR:-${PIPELINE_ROOT}/scripts}"
INPUT_BASE="${INPUT_BASE:-${PIPELINE_ROOT}/filtered}"
OUTPUT_BASE="${OUTPUT_BASE:-${PIPELINE_ROOT}/outputs/dereplicated}"
R_ENV_NAME="${R_ENV_NAME:-updated_r_env}"

# ----------------------------
# Environment activation (edit as needed for your cluster)
# ----------------------------
## Conda activation (override via CONDA_SH environment variable)
if [[ -n "${CONDA_SH:-}" && -f "${CONDA_SH}" ]]; then
  source "${CONDA_SH}"
  conda activate "${R_ENV_NAME}"
else
  echo "WARNING: CONDA_SH not set or file not found; ensure R + dada2 are available." >&2
fi

# ----------------------------
# Run
# ----------------------------
Rscript "${SCRIPTS_DIR}/dereplicate_ITS1.R" \
  --input-base "${INPUT_BASE}" \
  --output-base "${OUTPUT_BASE}"

