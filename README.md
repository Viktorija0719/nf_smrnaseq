# nf_smrnaseq · PBS + Singularity wrapper for **nf-core/smrnaseq**

This repository is a lightweight, reproducible wrapper to run the **nf-core/smrnaseq** small-RNA-seq pipeline on an HPC cluster that uses **PBS** for scheduling and **Singularity** for containers.

It contains only:

* A sample sheet (`sample_sheet.csv`)
* A cluster/container config (`nextflow.config`)
* A PBS launcher (`run_work.sh`)

Raw sequencing files and large results are **not** kept in Git.



## Typical project layout

```
nf_smrnaseq/
├── data/                    # (not in Git)
├── nextflow.config
├── run_work.sh
├── sample_sheet.csv
└── README.md
```


## 1) Install Nextflow (on the HPC login node)

> Requires: a working Java module (we use `java/jdk-21.0.2`).

```bash
module load java/jdk-21.0.2

# Install Nextflow to ~/bin and put it on PATH
wget -qO- https://get.nextflow.io | bash
mkdir -p ~/bin && mv nextflow ~/bin && echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify
nextflow info
#  Version: 25.10.0 build 10289
#  Runtime: Groovy 4.0.28 on Java 21.0.2 ...
```


## 2) Pull the pipeline

```bash
nextflow pull nf-core/smrnaseq
# Docs for 2.4.0: https://nf-co.re/smrnaseq/2.4.0/
```


## 3) Create the three project files

### 3.1 `sample_sheet.csv`

(One column per `sample` and `fastq_1` path, single-end miRNA.)

```csv
sample,fastq_1
KG51,/mnt/beegfs2/home/vikja01/rna_seq/data/fastq/miRNA_S8141Nr48.1.fastq.gz
KG52,/mnt/beegfs2/home/vikja01/rna_seq/data/fastq/miRNA_S8141Nr49.1.fastq.gz
KG53,/mnt/beegfs2/home/vikja01/rna_seq/data/fastq/miRNA_S8141Nr19.1.fastq.gz
KG54,/mnt/beegfs2/home/vikja01/rna_seq/data/fastq/miRNA_S8141Nr50.1.fastq.gz
KG55,/mnt/beegfs2/home/vikja01/rna_seq/data/fastq/miRNA_S8141Nr20.1.fastq.gz
```

### 3.2 `nextflow.config`

(PBS executor, Singularity containers, bind/caches on BeeGFS, and a safe shell.
The `beforeScript` makes sure each task loads Singularity and that host Java does not leak into containers.)



### 3.3 `run_work.sh`

(PBS driver that launches Nextflow. The heavy steps are submitted as separate PBS jobs by Nextflow.)


## Run

Submit the driver job (default uses `sample_sheet.csv` and outputs to `results/test`):

```bash
qsub run_work.sh
```

Or specify inputs/outputs:

```bash
qsub -- run_work.sh sample_sheet.csv results//test_subset
# or add genome/species explicitly
qsub -- run_work.sh sample_sheet.csv results/test_subset GRCh38 hsa
```




## Outputs you should see

After a successful run, your `--outdir` will look like this (top level):

```
results/test
├── fastp/
├── genome_quant/
├── mirdeep2/
├── mirna_quant/
├── mirtrace/
├── multiqc/
├── pipeline_info/
├── pipeline_report.html
├── pipeline_timeline.html
└── pipeline_trace.txt
```


* **Top-level Nextflow reports**

  * `pipeline_report.html` → runtime summary (tasks, resources).
  * `pipeline_timeline.html` → Gantt chart of process execution.
  * `pipeline_trace.txt` → per-process accounting (CPUs, RAM, time). Useful for performance tuning.

### Quick answers

* **Where are the miRNA counts (per gene/miRNA)?**
  → `mirna_quant/mirtop/mirna.tsv` (rows = miRBase IDs, columns = samples).

* **Where are isomiR-resolved counts and annotations?**
  → `mirna_quant/mirtop/joined_samples_mirtop.tsv`.

* **Where’s the all-in-one QC?**
  → `multiqc/multiqc_report.html` (open in a browser).





## Citations

* **Pipeline:** nf-core/smrnaseq 2.4.0 — [https://nf-co.re/smrnaseq/2.4.0/](https://nf-co.re/smrnaseq/2.4.0/)
* **nf-core framework:** doi:10.1038/s41587-020-0439-x

