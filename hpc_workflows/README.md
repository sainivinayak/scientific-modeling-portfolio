# HPC Workflows

This directory contains reproducible Slurm-based HPC workflow patterns for scalable scientific data processing.

## Overview

The workflows here are designed to run on a Slurm cluster.  They use template-driven R scripts and sbatch files to parallelize processing across multiple amplicons.  All workflows assume you have a conda environment (or modules) providing R and the **dada2** package.  You control where data are read and written via environment variables, and you can customise the list of amplicons to process.

### How to use the DADA2 pipeline

The `dada2_pipeline/` submodule demonstrates high‑throughput processing of marker‑gene amplicons.  To run it:

1. **Prepare a pipeline root**.  Choose a working directory (e.g. `/scratch/projects/myproject/run1`) containing a `filtered/` subdirectory with your per‑amplicon filtered FASTQ files.  Define this directory in the `PIPELINE_ROOT` environment variable when submitting jobs.

2. **Generate per‑amplicon R scripts (optional)**.  From within `hpc_workflows/dada2_pipeline/scripts` you can pre‑generate the R scripts used by the sbatch jobs:

   ```bash
   cd hpc_workflows/dada2_pipeline/scripts
   # Generate dereplication scripts for selected amplicons
   bash create_dereplicate_scripts_run1.sh --amplicons "ITS1,V3V4" --script-dir "$PIPELINE_ROOT/scripts"
   # Generate error learning scripts for selected amplicons
   bash create_error_learning_scripts.sh --amplicons "ITS1,V3V4" --script-dir "$PIPELINE_ROOT/scripts"
   ```

   These scripts will create `dereplicate_<AMP>.R` and `error_learning_<AMP>.R` under `${PIPELINE_ROOT}/scripts`.

3. **Generate and submit sbatch jobs**.  Use the submit drivers to create per‑amplicon sbatch files from templates and optionally submit them:

   ```bash
   # Still in hpc_workflows/dada2_pipeline/scripts
   # Generate dereplication sbatch files and submit them
   bash submit_dereplicate_jobs_run1.sh \
     --amplicons "ITS1,V3V4" \
     --out-dir generated_derep_sbatch \
     --template ../slurm/submit_dereplicate_run1.sbatch

   # Generate error‑learning sbatch files and submit them
   bash submit_error_learning_jobs.sh \
     --amplicons "ITS1,V3V4" \
     --out-dir generated_error_sbatch \
     --template ../slurm/submit_error_learning.sbatch
   ```

   Passing `--dry-run` to either script will print the commands without submitting any jobs.

4. **Configure your environment**.  Before submission you must ensure R and dada2 are available.  You can either load appropriate modules or activate a conda environment.  The sbatch templates expect the variable `R_ENV_NAME` to name the conda environment and an optional `CONDA_SH` pointing to the `conda.sh` activation script.  For example:

   ```bash
   export PIPELINE_ROOT=/scratch/projects/myproject/run1
   export INPUT_BASE=${PIPELINE_ROOT}/filtered
   export OUTPUT_BASE=${PIPELINE_ROOT}/outputs
   export R_ENV_NAME=my_dada2_env
   export CONDA_SH=$HOME/miniconda3/etc/profile.d/conda.sh
   ```

   You can pass these via `sbatch --export=ALL,...` or set them in your shell before running the submit drivers.

5. **Submit jobs**.  The submit scripts will call `sbatch` for each amplicon, generating logs under `logs/`.  Monitor job outputs in the logs directory.

### Submodules

- `dada2_pipeline/` — template-based DADA2 execution across multiple amplicons.  See its README for details.

