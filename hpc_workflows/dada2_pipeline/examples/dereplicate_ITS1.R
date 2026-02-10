#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dada2)
})

# dereplicate_ITS1.R
# Portfolio-safe ITS1 example:
# - No hard-coded absolute paths
# - Uses CLI args / env vars for bases
# - Validates R1/R2 pairing
# - Skips if outputs exist unless --force

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  i <- which(args == flag)
  if (length(i) == 0) return(default)
  if (i == length(args)) stop("Missing value after ", flag)
  args[i + 1]
}
has_flag <- function(flag) any(args == flag)

amplicon <- "ITS1"

input_base  <- get_arg("--input-base", Sys.getenv("INPUT_BASE", unset = NA_character_))
output_base <- get_arg("--output-base", Sys.getenv("OUTPUT_BASE", unset = NA_character_))
pattern_r1  <- get_arg("--pattern-r1", "_R1.fastq_filtered.fastq.gz")
pattern_r2  <- get_arg("--pattern-r2", "_R2.fastq_filtered.fastq.gz")
force       <- has_flag("--force")

if (is.na(input_base) || input_base == "") {
  stop(
    "Missing --input-base (or env INPUT_BASE).\n",
    "Example:\n",
    "  Rscript dereplicate_ITS1.R --input-base /path/to/filtered --output-base /path/to/outputs/dereplicated [--force]\n"
  )
}
if (is.na(output_base) || output_base == "") output_base <- input_base

input_directory  <- file.path(input_base, amplicon)
output_directory <- file.path(output_base, amplicon)

if (!dir.exists(input_directory)) stop("Input directory not found: ", input_directory)
if (!dir.exists(output_directory)) dir.create(output_directory, recursive = TRUE)

out_derepF <- file.path(output_directory, paste0("derepF_", amplicon, ".rds"))
out_derepR <- file.path(output_directory, paste0("derepR_", amplicon, ".rds"))

if (!force && file.exists(out_derepF) && file.exists(out_derepR)) {
  message("Outputs already exist; skipping (use --force to recompute): ", amplicon)
  quit(status = 0)
}

message("Amplicon: ", amplicon)
message("Input:    ", input_directory)
message("Output:   ", output_directory)

fwd_files <- list.files(input_directory, pattern = pattern_r1, full.names = TRUE)
rev_files <- list.files(input_directory, pattern = pattern_r2, full.names = TRUE)

if (length(fwd_files) == 0) stop("No forward reads found with pattern: ", pattern_r1)
if (length(rev_files) == 0) stop("No reverse reads found with pattern: ", pattern_r2)

# Pairing validation by key extracted from filename
key_from_path <- function(x, pat) sub(pat, "", basename(x), fixed = TRUE)

keysF <- key_from_path(fwd_files, pattern_r1)
keysR <- key_from_path(rev_files, pattern_r2)

ordF <- order(keysF); ordR <- order(keysR)
fwd_files <- fwd_files[ordF]; keysF <- keysF[ordF]
rev_files <- rev_files[ordR]; keysR <- keysR[ordR]

if (!setequal(keysF, keysR)) {
  missing_in_R <- setdiff(keysF, keysR)
  missing_in_F <- setdiff(keysR, keysF)
  stop(
    "Forward/Reverse pairing mismatch.\n",
    "Missing in reverse: ", paste(missing_in_R[1:min(10, length(missing_in_R))], collapse = ", "), "\n",
    "Missing in forward: ", paste(missing_in_F[1:min(10, length(missing_in_F))], collapse = ", ")
  )
}

# Align reverse order to forward order
rev_files <- rev_files[match(keysF, keysR)]

message("Pairs: ", length(fwd_files))

derepF <- derepFastq(fwd_files, verbose = TRUE)
saveRDS(derepF, out_derepF)

derepR <- derepFastq(rev_files, verbose = TRUE)
saveRDS(derepR, out_derepR)

message("Saved: ", out_derepF)
message("Saved: ", out_derepR)
