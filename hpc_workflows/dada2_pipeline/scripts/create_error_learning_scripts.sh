#!/usr/bin/env bash
set -euo pipefail

# create_error_learning_scripts.sh
#
# Purpose:
#   Generate per-amplicon DADA2 error-learning R scripts from a single template
#   containing placeholder "AMP".
#
# Usage:
#   bash create_error_learning_scripts.sh
#   bash create_error_learning_scripts.sh --amplicons "ITS1,V3V4"
#   bash create_error_learning_scripts.sh --pipeline-root /path/to/run1
#   bash create_error_learning_scripts.sh --scripts-dir /path/to/run1/scripts
#   bash create_error_learning_scripts.sh --input-base /path/to/run1/filtered --output-base /path/to/run1/filtered
#
# Notes:
#   - Generated scripts are named: error_learning_<amplicon>.R
#   - No hard-coded personal paths; uses variables in generated R scripts.

DEFAULT_AMPLICONS="ITS1,V1V2,V2V3,V3V4,V4V5,V5V7,V7V9"
AMPLICONS_CSV="${DEFAULT_AMPLICONS}"

PIPELINE_ROOT="${PIPELINE_ROOT:-/path/to/run1}"
SCRIPTS_DIR=""
INPUT_BASE=""
OUTPUT_BASE=""

usage() {
  cat <<EOF
Usage: create_error_learning_scripts.sh [options]

Options:
  --amplicons     Comma-separated list (default: ${DEFAULT_AMPLICONS})
  --pipeline-root Base pipeline directory (default: \$PIPELINE_ROOT or /path/to/run1)
  --scripts-dir   Where to write generated R scripts (default: <pipeline-root>/scripts)
  --input-base    Base directory containing filtered reads per amplicon (default: <pipeline-root>/filtered)
  --output-base   Base directory for writing errF/errR per amplicon (default: <pipeline-root>/filtered)
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --amplicons)     AMPLICONS_CSV="$2"; shift 2 ;;
    --pipeline-root) PIPELINE_ROOT="$2"; shift 2 ;;
    --scripts-dir)   SCRIPTS_DIR="$2"; shift 2 ;;
    --input-base)    INPUT_BASE="$2"; shift 2 ;;
    --output-base)   OUTPUT_BASE="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

SCRIPTS_DIR="${SCRIPTS_DIR:-${PIPELINE_ROOT}/scripts}"
INPUT_BASE="${INPUT_BASE:-${PIPELINE_ROOT}/filtered}"
OUTPUT_BASE="${OUTPUT_BASE:-${PIPELINE_ROOT}/filtered}"

mkdir -p "${SCRIPTS_DIR}"

# -------- Template R script (uses AMP placeholder) --------
# Generated R scripts will:
#   - read filtered reads from: <INPUT_BASE>/<AMP>/
#   - write error models to:    <OUTPUT_BASE>/<AMP>/
#   - bind threads to SLURM_CPUS_PER_TASK if present
template_script='
suppressPackageStartupMessages({
  library(dada2)
})

AMP <- "AMP"

input_directory  <- file.path(Sys.getenv("INPUT_BASE", "INPUT_BASE_PLACEHOLDER"), AMP)
output_directory <- file.path(Sys.getenv("OUTPUT_BASE","OUTPUT_BASE_PLACEHOLDER"), AMP)

pattern_r1 <- "_R1.fastq_filtered.fastq.gz"
pattern_r2 <- "_R2.fastq_filtered.fastq.gz"

if (!dir.exists(input_directory)) stop("Input directory not found: ", input_directory)
if (!dir.exists(output_directory)) dir.create(output_directory, recursive = TRUE)

filtFs <- list.files(input_directory, pattern = pattern_r1, full.names = TRUE)
filtRs <- list.files(input_directory, pattern = pattern_r2, full.names = TRUE)

if (length(filtFs) == 0) stop("No forward reads found in: ", input_directory)
if (length(filtRs) == 0) stop("No reverse reads found in: ", input_directory)

# Bind DADA2 threads to Slurm allocation if present
n_threads <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1"))
if (is.na(n_threads) || n_threads < 1) n_threads <- 1

message("Amplicon: ", AMP)
message("Input:    ", input_directory)
message("Output:   ", output_directory)
message("Threads:  ", n_threads)
message("Pairs F/R:", length(filtFs), " / ", length(filtRs))

errF <- learnErrors(filtFs, multithread = n_threads)
errR <- learnErrors(filtRs, multithread = n_threads)

saveRDS(errF, file.path(output_directory, "errF.rds"))
saveRDS(errR, file.path(output_directory, "errR.rds"))
'

# Inject default placeholders for INPUT_BASE / OUTPUT_BASE so script is runnable
template_script="${template_script//INPUT_BASE_PLACEHOLDER/${INPUT_BASE}}"
template_script="${template_script//OUTPUT_BASE_PLACEHOLDER/${OUTPUT_BASE}}"

IFS=',' read -r -a AMPLICONS <<< "${AMPLICONS_CSV}"

for amplicon in "${AMPLICONS[@]}"; do
  script_content="${template_script//AMP/${amplicon}}"
  script_file="${SCRIPTS_DIR}/error_learning_${amplicon}.R"
  printf "%s\n" "${script_content}" > "${script_file}"
  echo "Wrote: ${script_file}"
done

