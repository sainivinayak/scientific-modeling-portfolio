#!/usr/bin/env bash
#SBATCH --job-name=error_learning_AMP
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=01:30:00
#SBATCH --partition=single
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
##SBATCH --account=YOUR_ACCOUNT   # optional: uncomment and set if your cluster requires it

set -euo pipefail
mkdir -p logs

# ----------------------------
# User-configurable parameters
# ----------------------------
PIPELINE_ROOT="${PIPELINE_ROOT:-/path/to/run1}"
R_ENV_NAME="${R_ENV_NAME:-updated_r_env}"

SCRIPTS_DIR="${SCRIPTS_DIR:-${PIPELINE_ROOT}/scripts}"

# ----------------------------
# Environment activation
# ----------------------------
# module load ...

## Conda activation (override via CONDA_SH environment variable)
if [[ -n "${CONDA_SH:-}" && -f "${CONDA_SH}" ]]; then
  source "${CONDA_SH}"
  conda activate "${R_ENV_NAME}"
else
  echo "WARNING: CONDA_SH not set or file not found; ensure R + dada2 are available in the environment." >&2
fi

# ----------------------------
# Run
# ----------------------------
Rscript "${SCRIPTS_DIR}/error_learning_AMP.R"

