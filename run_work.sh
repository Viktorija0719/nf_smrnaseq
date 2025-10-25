#!/usr/bin/env bash
#PBS -N nf_smrna_work
#PBS -q batch
# Driver (Nextflow) job is light; tasks run as separate PBS jobs.
# Increase if your site requires more for the launcher itself.
#PBS -l nodes=1:ppn=2,mem=8g,walltime=72:00:00
#PBS -A rsu
#PBS -j oe
#PBS -o logs/${PBS_JOBNAME}.${PBS_JOBID}.out

set -euo pipefail

#############################################
# 0) housekeeping & small helpers
#############################################
cd "${PBS_O_WORKDIR:-$PWD}"
mkdir -p logs

err() { echo "[ERROR] $*" >&2; exit 1; }
log() { echo "[INFO]  $*" >&2; }

#############################################
# 1) parse args / defaults
#############################################
# Usage:
#   qsub -- run_work.sh [SHEET] [OUTDIR] [GENOME] [SPECIES]
#
# Examples:
#   qsub -- run_work.sh metadata/Combined_Sample_IDs_CAD_test.csv results/smrna_pbs_sing/test_subset
#   qsub -- run_work.sh metadata/Combined_Sample_IDs_CAD_1_2.csv  results/smrna_pbs_sing/all_CAD GRCh38 hsa

SHEET="${1:-sample_sheet.csv}"
OUTDIR="${2:-results/test}"
GENOME="${3:-GRCh38}"    
SPECIES="${4:-hsa}"

ADAPTER="${ADAPTER:-TGGAATTCTCGGGTGCCAAGG}"
FASTP_MIN_LENGTH="${FASTP_MIN_LENGTH:-18}"
FASTP_MAX_LENGTH="${FASTP_MAX_LENGTH:-30}"

[[ -f "$SHEET" ]] || err "Samplesheet not found: $SHEET"
mkdir -p "$OUTDIR"

#############################################
# 2) driver environment (Nextflow itself)
#############################################
module purge
module load java/jdk-21.0.2
module load singularity/3.11.4

# Keep heavy caches on BeeGFS
export NXF_WORK="${NXF_WORK:-/home_beegfs/${USER}/.nxf_work}"
export SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR:-/home_beegfs/${USER}/.singularity_cache}"
export APPTAINER_CACHEDIR="$SINGULARITY_CACHEDIR"
export NXF_SINGULARITY_CACHEDIR="$SINGULARITY_CACHEDIR"
export SINGULARITY_BINDPATH="${SINGULARITY_BINDPATH:-/home_beegfs,/mnt/beegfs2,/tmp}"
export APPTAINER_BINDPATH="$SINGULARITY_BINDPATH"
mkdir -p "$NXF_WORK" "$SINGULARITY_CACHEDIR"

# Optional: tune Nextflow JVM for the launcher
export NXF_OPTS="${NXF_OPTS:--Xms512m -Xmx4g}"

log "Launcher node: $(hostname)"
log "Nextflow: $(nextflow -version | head -n1)"
log "Singularity: $(singularity --version)"
log "WorkDir: $NXF_WORK"
log "CacheDir: $SINGULARITY_CACHEDIR"
log "Sheet: $SHEET"
log "Outdir: $OUTDIR"
log "Adapter: $ADAPTER, min=${FASTP_MIN_LENGTH}, max=${FASTP_MAX_LENGTH}, genome=${GENOME}, species=${SPECIES}"

#############################################
# 3) run nf-core/smrnaseq
#############################################
CMD=( nextflow run nf-core/smrnaseq -r 2.4.0
      -profile singularity
      -c nextflow.config
      --input "$SHEET"
      --adapter "$ADAPTER"
      --fastp_min_length "$FASTP_MIN_LENGTH"
      --fastp_max_length "$FASTP_MAX_LENGTH"
      --mirtrace_species "$SPECIES"
      --outdir "$OUTDIR"
      -with-report "$OUTDIR/pipeline_report.html"
      -with-trace  "$OUTDIR/pipeline_trace.txt"
      -with-timeline "$OUTDIR/pipeline_timeline.html"
      -resume )

# include genome if provided (empty to omit)
[[ -n "$GENOME" ]] && CMD+=( --genome "$GENOME" )

log "Launching: ${CMD[*]}"
"${CMD[@]}"

