# DADA2 HPC Pipeline (Template-Based)

This module demonstrates:

- **Template‑driven R script generation** – the `r_templates/` directory contains skeleton R scripts with `AMP` placeholders.  Generator scripts in `scripts/` produce per‑amplicon R files under a target `scripts/` directory.
- **Slurm sbatch templating** – sbatch templates live in `slurm/` and use placeholders for the amplicon names and environment variables.  Submit drivers substitute these tokens to create per‑amplicon job files.
- **Per‑amplicon job parallelisation** – the submit scripts iterate over a comma‑separated list of amplicons, generating and submitting one job per amplicon.
- **Conda‑based environment activation** – sbatch templates source a conda activation script via the `CONDA_SH` environment variable and activate `R_ENV_NAME`.  You must set these variables when submitting jobs.
- **Structured input/output organisation** – environment variables `PIPELINE_ROOT`, `INPUT_BASE`, `OUTPUT_BASE` control where reads are found and where outputs are written.  Use `sbatch --export` to override defaults.

### Running the pipeline

To run the DADA2 pipeline you typically:

1. Choose a pipeline root directory containing filtered FASTQ files (`${PIPELINE_ROOT}/filtered/<AMP>/`), and export `PIPELINE_ROOT` accordingly.
2. Generate per‑amplicon R scripts using the generator scripts if they do not already exist.
3. Use the submit drivers to create sbatch files from the templates and submit them.  By default they will look for the templates in `../slurm/`; specify `--template` explicitly if you relocate them.
4. Ensure `R_ENV_NAME` names an installed conda environment containing the **dada2** package.  If your conda is not in the default location, set `CONDA_SH` to the path of `conda.sh`.

See the top‑level `hpc_workflows/README.md` for a complete walkthrough and examples.
