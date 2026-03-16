#!/bin/bash

#SBATCH -p hospital
#SBATCH -c 4
#SBATCH --mem=8gb
#SBATCH --time=240:00:00
#SBATCH --output=sarek_%j.out
#SBATCH --error=sarek_%j.err
#SBATCH --mail-type=END,FAIL


unset XDG_RUNTIME_DIR

# Parameters
date="230414"
scratch_dir="/scratch/HOSPITAL/hospital_"$SLURM_JOB_ID

echo "Use Java AMZN 17"
export JAVA_HOME="/home/USER/.sdkman/candidates/java/17.0.6-amzn"

echo "Automatic downloads and updates are disabled."
export NXF_OFFLINE=true

echo "Use NEXTFLOW version 23.04.4"
export NXF_VER=23.04.4

echo "Define workdir in /scratch:"
echo ${scratch_dir}
mkdir -p ${scratch_dir}
export NXF_WORK=${scratch_dir}

echo "SAREK EXEC:"
srun /home/$(whoami)/bin/nextflow run /genomics/HOSPITAL/singularity/pipelines/nf-core-sarek_3.3.2/3_3_2/\
     --step             mapping\
     --input            /home/$(whoami)/nfcore/sarek/${date}/samplesheet.csv\
     --outdir           /home/$(whoami)/nfcore/sarek/${date}/output\
     --intervals        /home/$(whoami)/nfcore/sarek/${date}/vascular_hg38.bed\
     --igenomes_base    /genomics/HOSPITAL/data/igenomes/\
     --snpeff_cache     /genomics/HOSPITAL/data/cache/snpeff_cache/\
     --vep_cache        /genomics/HOSPITAL/data/cache/vep_cache/\
     --seq_platform     ILLUMINA\
     --genome           GATK.GRCh38\
     --aligner          bwa-mem2\
     --tools            freebayes,mpileup,mutect2,strelka,merge\
     --wes              false\
     -profile           singularity\
     -c			/home/$(whoami)/nfcore/sarek/${date}/nextflow.config\
     -resume            true\

sleep 30m

rm -rf ${scratch_dir}
