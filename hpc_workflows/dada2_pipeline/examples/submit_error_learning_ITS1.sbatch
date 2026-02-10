#!/usr/bin/env bash
#SBATCH --job-name=error_learning_ITS1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=01:30:00
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
OUTPUT_BASE="${OUTPUT_BASE:-${PIPELINE_ROOT}/filtered}"
R_ENV_NAME="${R_ENV_NAME:-updated_r_env}"

# ----------------------------
# Environment activation (edit as needed for your cluster)
# ----------------------------
if [[ -f "/usr/local/packages/conda/23.11.0/etc/profile.d/conda.sh" ]]; then
  source "/usr/local/packages/conda/23.11.0/etc/profile.d/conda.sh"
  conda activate "${R_ENV_NAME}"
else
  echo "WARNING: conda.sh not found; ensure R + dada2 are available." >&2
fi

# ----------------------------
# Run
# ----------------------------
Rscript "${SCRIPTS_DIR}/error_learning_ITS1.R" \
  --input-base "${INPUT_BASE}" \
  --output-base "${OUTPUT_BASE}"

