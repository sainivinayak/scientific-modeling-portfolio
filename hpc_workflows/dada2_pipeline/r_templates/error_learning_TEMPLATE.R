#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dada2)
})

# ---------------------------------------------
# CLI parsing (base R, no extra dependencies)
# ---------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  i <- which(args == flag)
  if (length(i) == 0) return(default)
  if (i == length(args)) stop("Missing value after ", flag)
  args[i + 1]
}
has_flag <- function(flag) any(args == flag)

amplicon    <- get_arg("--amplicon")
input_base  <- get_arg("--input-base")
output_base <- get_arg("--output-base", input_base) # common to save in same folder
pattern_r1  <- get_arg("--pattern-r1", "_R1.fastq_filtered.fastq.gz")
pattern_r2  <- get_arg("--pattern-r2", "_R2.fastq_filtered.fastq.gz")
force       <- has_flag("--force")

if (is.null(amplicon) || is.null(input_base)) {
  stop(
    "Usage:\n",
    "  error_learning_TEMPLATE.R --amplicon AMP --input-base DIR [--output-base DIR]\n",
    "                           [--pattern-r1 P] [--pattern-r2 P] [--force]\n\n",
    "Example:\n",
    "  Rscript error_learning_TEMPLATE.R --amplicon ITS1 --input-base /path/to/filtered"
  )
}

input_directory  <- file.path(input_base, amplicon)
output_directory <- file.path(output_base, amplicon)

if (!dir.exists(input_directory)) stop("Input directory not found: ", input_directory)
if (!dir.exists(output_directory)) dir.create(output_directory, recursive = TRUE)

out_errF <- file.path(output_directory, "errF.rds")
out_errR <- file.path(output_directory, "errR.rds")

if (!force && file.exists(out_errF) && file.exists(out_errR)) {
  message("Outputs already exist; skipping (use --force to recompute): ", amplicon)
  quit(status = 0)
}

# Bind DADA2 threading to Slurm allocation if present
n_threads <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1"))
if (is.na(n_threads) || n_threads < 1) n_threads <- 1

message("Amplicon: ", amplicon)
message("Input:    ", input_directory)
message("Output:   ", output_directory)
message("Threads:  ", n_threads)

filtFs <- list.files(input_directory, pattern = pattern_r1, full.names = TRUE)
filtRs <- list.files(input_directory, pattern = pattern_r2, full.names = TRUE)

if (length(filtFs) == 0) stop("No forward reads found with pattern: ", pattern_r1)
if (length(filtRs) == 0) stop("No reverse reads found with pattern: ", pattern_r2)

# Robust pairing check (match by basename after removing pattern)
key_from_path <- function(x, pat) sub(pat, "", basename(x), fixed = TRUE)

keysF <- key_from_path(filtFs, pattern_r1)
keysR <- key_from_path(filtRs, pattern_r2)

ordF <- order(keysF); ordR <- order(keysR)
filtFs <- filtFs[ordF]; keysF <- keysF[ordF]
filtRs <- filtRs[ordR]; keysR <- keysR[ordR]

if (!setequal(keysF, keysR)) {
  missing_in_R <- setdiff(keysF, keysR)
  missing_in_F <- setdiff(keysR, keysF)
  stop(
    "Forward/Reverse pairing mismatch.\n",
    "Missing in reverse: ", paste(missing_in_R[1:min(10, length(missing_in_R))], collapse = ", "), "\n",
    "Missing in forward: ", paste(missing_in_F[1:min(10, length(missing_in_F))], collapse = ", ")
  )
}

# Align reverse to forward order
filtRs <- filtRs[match(keysF, keysR)]

message("Pairs: ", length(filtFs))

errF <- learnErrors(filtFs, multithread = n_threads)
errR <- learnErrors(filtRs, multithread = n_threads)

saveRDS(errF, out_errF)
saveRDS(errR, out_errR)

message("Saved: ", out_errF)
message("Saved: ", out_errR)

