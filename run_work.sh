#!/usr/bin/env bash
# PBS launcher for nf-core/smrnaseq
# ADJUST (if needed): queue/walltime/account in the PBS header below.

#PBS -N nf_smrna
#PBS -q batch                 # ← EDIT if your queue differs
#PBS -l nodes=1:ppn=2,mem=8g,walltime=72:00:00   # ← EDIT if needed
#PBS -A rsu                   # ← remove/change if not used
#PBS -j oe
#PBS -o logs/${PBS_JOBNAME}.${PBS_JOBID}.out

set -euo pipefail
cd "${PBS_O_WORKDIR:-$PWD}"; mkdir -p logs

module purge
module load java/jdk-21.0.2    
module load singularity/3.11.4 

SHEET="${1:-sample_sheet.csv}"
OUTDIR="${2:-results/test}"
GENOME="${3:-GRCh38}"               
SPECIES="${4:-hsa}"

[[ -f "$SHEET" ]] || { echo "[ERROR] No such samplesheet: $SHEET" >&2; exit 1; }
mkdir -p "$OUTDIR"

cmd=( nextflow run nf-core/smrnaseq -r 2.4.0
      -c nextflow.config
      -profile singularity,rtu
      --input "$SHEET"
      --mirtrace_species "$SPECIES"
      --outdir "$OUTDIR"
      -with-report    "$OUTDIR/pipeline_report.html"
      -with-trace     "$OUTDIR/pipeline_trace.txt"
      -with-timeline  "$OUTDIR/pipeline_timeline.html"
      -resume )

[[ -n "$GENOME" ]] && cmd+=( --genome "$GENOME" )

echo "[INFO] ${cmd[*]}"
exec "${cmd[@]}"
