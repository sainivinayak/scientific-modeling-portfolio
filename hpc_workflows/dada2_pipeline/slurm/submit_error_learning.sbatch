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

if [[ -f "/usr/local/packages/conda/23.11.0/etc/profile.d/conda.sh" ]]; then
  source "/usr/local/packages/conda/23.11.0/etc/profile.d/conda.sh"
  conda activate "${R_ENV_NAME}"
else
  echo "WARNING: conda.sh not found; ensure R + dada2 are available in the environment." >&2
fi

# ----------------------------
# Run
# ----------------------------
Rscript "${SCRIPTS_DIR}/error_learning_AMP.R"

