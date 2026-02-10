#!/usr/bin/env bash
set -euo pipefail

# create_dereplicate_scripts_run1.sh
#
# Purpose:
#   Generate per-amplicon DADA2 dereplication R scripts from a single template
#   containing placeholder "AMP".
#
# Usage:
#   bash create_dereplicate_scripts_run1.sh
#   bash create_dereplicate_scripts_run1.sh --amplicons "ITS1,V3V4"
#   bash create_dereplicate_scripts_run1.sh --pipeline-root /path/to/run1
#   bash create_dereplicate_scripts_run1.sh --input-base /path/to/run1/filtered --output-base /path/to/run1/outputs/dereplicated
#
# Notes:
#   - Generated scripts are named: dereplicate_<amplicon>.R
#   - Writes derepF_<AMP>.rds and derepR_<AMP>.rds to per-amplicon output folder.

DEFAULT_AMPLICONS="ITS1,V1V2,V2V3,V3V4,V4V5,V5V7,V7V9"
AMPLICONS_CSV="${DEFAULT_AMPLICONS}"

PIPELINE_ROOT="${PIPELINE_ROOT:-/path/to/run1}"
SCRIPTS_DIR=""
INPUT_BASE=""
OUTPUT_BASE=""

usage() {
  cat <<EOF
Usage: create_dereplicate_scripts_run1.sh [options]

Options:
  --amplicons     Comma-separated list (default: ${DEFAULT_AMPLICONS})
  --pipeline-root Base pipeline directory (default: \$PIPELINE_ROOT or /path/to/run1)
  --scripts-dir   Where to write generated R scripts (default: <pipeline-root>/scripts)
  --input-base    Base directory containing filtered reads per amplicon (default: <pipeline-root>/filtered)
  --output-base   Base directory for derep outputs per amplicon (default: <pipeline-root>/outputs/dereplicated)
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
OUTPUT_BASE="${OUTPUT_BASE:-${PIPELINE_ROOT}/outputs/dereplicated}"

mkdir -p "${SCRIPTS_DIR}"

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

fwd_files <- list.files(input_directory, pattern = pattern_r1, full.names = TRUE)
rev_files <- list.files(input_directory, pattern = pattern_r2, full.names = TRUE)

if (length(fwd_files) == 0) stop("No forward reads found in: ", input_directory)
if (length(rev_files) == 0) stop("No reverse reads found in: ", input_directory)

message("Amplicon: ", AMP)
message("Input:    ", input_directory)
message("Output:   ", output_directory)
message("F/R files:", length(fwd_files), " / ", length(rev_files))

derepF <- derepFastq(fwd_files, verbose = TRUE)
saveRDS(derepF, file.path(output_directory, paste0("derepF_", AMP, ".rds")))

derepR <- derepFastq(rev_files, verbose = TRUE)
saveRDS(derepR, file.path(output_directory, paste0("derepR_", AMP, ".rds")))
'

template_script="${template_script//INPUT_BASE_PLACEHOLDER/${INPUT_BASE}}"
template_script="${template_script//OUTPUT_BASE_PLACEHOLDER/${OUTPUT_BASE}}"

IFS=',' read -r -a AMPLICONS <<< "${AMPLICONS_CSV}"

for amplicon in "${AMPLICONS[@]}"; do
  script_content="${template_script//AMP/${amplicon}}"
  script_file="${SCRIPTS_DIR}/dereplicate_${amplicon}.R"
  printf "%s\n" "${script_content}" > "${script_file}"
  echo "Wrote: ${script_file}"
done

