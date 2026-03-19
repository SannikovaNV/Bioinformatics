# nf-core/Sarek — Usage Guidelines

nf-core/Sarek is an open-source Nextflow pipeline for whole genome and whole exome sequencing analysis. It supports both germline and somatic variant calling, covering alignment, variant detection, copy number analysis, and functional annotation following GATK Best Practices.

This repository contains SLURM submission scripts for running Sarek in a hospital HPC environment, covering three use cases: WGS germline, WES germline, and WGS somatic. All scripts handle environment setup, pipeline execution, and result archiving in a single batch job.

---

## Table of contents

- [WGS germline](#wgs-germline)
- [WES germline](#wes-germline)
- [WGS somatic](#wgs-somatic)
- [Requirements](#requirements)

---

## WGS germline

`germline_wgs.sh` submits a germline variant calling job for whole genome sequencing samples aligned to GRCh38.

### Use case

Starting from paired-end FASTQ reads, it produces germline SNP and indel calls, copy number variants, and functional variant annotations aligned to the GRCh38 reference genome. The starting step can be changed — for example, starting from `variant_calling` if mapped BAMs already exist, or from `annotate` if a VCF file is provided as input.

### What the script does

It configures the runtime environment by setting the Java version via SDKMAN, pinning Nextflow to version 23.10.1, and redirecting the working directory to a temporary scratch space on the cluster. This avoids filling up home directories with intermediate files during execution.

It then runs nf-core/Sarek 3.4.2 starting from the mapping step, taking as input a samplesheet CSV that defines the samples to process. Alignment is performed with BWA-MEM2 against the GATK.GRCh38 reference genome using Illumina platform settings. A BED file defining target intervals is provided to restrict the analysis to regions of interest.

The pipeline runs three tools in parallel: HaplotypeCaller for germline SNP and indel calling, CNVkit for copy number variant detection, and VEP 110 for functional annotation. VEP is run with the dbNSFP plugin enabled, which adds functional predictions and conservation scores to each variant. All tools run inside Singularity images for reproducibility.

Once the pipeline finishes, the script waits 30 minutes to allow any pending writes to complete, then deletes the scratch working directory to free up space. Finally, it copies the output directory, the samplesheet, and the script itself to a permanent storage location for archiving.

### Key parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--genome` | GATK.GRCh38 | Reference genome loaded from shared iGenomes |
| `--aligner` | bwa-mem2 | Alignment tool |
| `--tools` | haplotypecaller, cnvkit, vep | Variant calling and annotation tools |
| `--vep_version` | 110 | VEP version |
| `--wes` | false | WGS mode |
| `--vep_dbnsfp` | true | Enable dbNSFP plugin for VEP |

### Requirements

SLURM cluster with Singularity, Nextflow 23.10.1, nf-core/Sarek 3.4.2, Java 17 via SDKMAN, and shared access to iGenomes, VEP cache, and dbNSFP databases.

---

## WES germline

`germline_wes.sh` submits a germline variant calling job for whole exome sequencing samples using a locally provided reference genome instead of iGenomes.

### Use case

Germline WES analysis for cases where the standard iGenomes bundle is not available or a custom genome build is required. Target regions are defined by a SureSelect v6 BED file, restricting variant calling to captured exonic regions.

### What the script does

The environment is configured with Java 17 via SDKMAN and Nextflow 23.04.4. The working directory is set to a temporary scratch space on the cluster.

Sarek 3.3.2 runs from the mapping step using BWA-MEM2. The reference genome is provided directly via `--fasta` and `--fasta_fai`, bypassing iGenomes with `--igenomes_ignore`. Mapped BAM files are saved with `--save_mapped`, which is useful for downstream reuse or manual inspection. Base quality score recalibration (BQSR) is skipped with `--skip_tools baserecalibrator` — a common choice for WES when the capture kit does not provide a sufficient number of variants for recalibration. Variant calling is performed with HaplotypeCaller only. All tools run inside Singularity images.

After execution the script waits 30 minutes before deleting the scratch directory.

### Key parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--igenomes_ignore` | — | Bypass iGenomes, use local reference |
| `--fasta` | custom path | Local reference genome FASTA |
| `--intervals` | SureSelect_v6.bed | Exome capture kit BED file |
| `--aligner` | bwa-mem2 | Alignment tool |
| `--tools` | haplotypecaller | Germline variant calling only |
| `--skip_tools` | baserecalibrator | Skip BQSR |
| `--save_mapped` | — | Save aligned BAM files |
| `--wes` | true | WES mode |

### Key differences from WGS germline

Uses a custom local reference genome instead of iGenomes. Runs in WES mode with a SureSelect v6 intervals file. Skips BQSR. Saves mapped BAMs for reuse. Uses Sarek 3.3.2. Allocates more CPUs (50 vs 4) reflecting the heavier per-sample processing required.

### Requirements

SLURM cluster with Singularity, Nextflow 23.04.4, nf-core/Sarek 3.3.2, Java 17 via SDKMAN, and local copies of the reference genome FASTA and SureSelect v6 BED file.

---

## WGS somatic

`somatic_wgs.sh` submits a somatic variant calling job for tumor-normal paired WGS samples aligned to GRCh38.

### Use case

Somatic variant calling from tumor-normal paired WGS samples. Designed for clinical or research settings where orthogonal somatic callers are run simultaneously and their results merged, increasing sensitivity and specificity for somatic SNVs and indels.

### What the script does

The environment is configured with Java 17 via SDKMAN and Nextflow 23.04.4. Offline mode is enabled with `NXF_OFFLINE=true`, meaning no automatic pipeline or container updates occur during execution — useful in restricted hospital network environments. The working directory is redirected to a scratch space on the cluster.

Sarek 3.3.2 runs from the mapping step using BWA-MEM2 against GATK.GRCh38 from the shared iGenomes base. Target intervals are provided via a custom vascular panel BED file in hg38 coordinates, restricting the analysis to regions of interest. The `-resume` flag is enabled, allowing the job to restart from the last successful step if it fails or is interrupted — particularly useful for long-running hospital jobs.

Four somatic tools run in parallel: Freebayes and Mpileup as lightweight somatic callers, Mutect2 as the GATK somatic standard, and Strelka for fast somatic SNV and indel calling. The `merge` tool combines the outputs of all callers into a single unified VCF. Both VEP and snpEff caches are provided for downstream annotation, loaded from shared cluster paths. All tools run inside Singularity images.

After execution the script waits 30 minutes before deleting the scratch directory.

### Key parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--genome` | GATK.GRCh38 | Reference genome from shared iGenomes |
| `--aligner` | bwa-mem2 | Alignment tool |
| `--tools` | freebayes, mpileup, mutect2, strelka, merge | Somatic callers + merge |
| `--wes` | false | WGS mode |
| `-resume` | true | Restart from last successful step |

### Key differences from germline scripts

The samplesheet defines tumor-normal pairs instead of individual samples. Four somatic callers run in parallel and their results are merged into a single VCF. Both VEP and snpEff annotation caches are configured. Offline mode is enabled. A custom vascular panel BED file is used. The `-resume` flag is active.

### Requirements

SLURM cluster with Singularity, Nextflow 23.04.4, nf-core/Sarek 3.3.2, Java 17 via SDKMAN, and shared access to iGenomes, VEP cache, and snpEff cache.

---

## Requirements

All scripts share the following common requirements:

- SLURM workload manager
- Singularity
- Java 17 (Amazon Corretto) via SDKMAN
- Nextflow (version pinned per script)
- nf-core/Sarek (version pinned per script)
- Shared cluster paths for iGenomes, VEP cache, snpEff cache, and dbNSFP (where applicable)
- A correctly formatted samplesheet CSV — see the [nf-core/Sarek samplesheet documentation](https://nf-co.re/sarek/latest/docs/usage#input-sample-sheet-configurations)
