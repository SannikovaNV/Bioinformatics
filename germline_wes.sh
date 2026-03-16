#!/bin/bash

#SBATCH -p hospital
#SBATCH -c 50
#SBATCH --mem=32gb
#SBATCH --time=240:00:00
#SBATCH --output=sarek_%j.out
#SBATCH --error=sarek_%j.err
#SBATCH --mail-type=END,FAIL


unset XDG_RUNTIME_DIR
export NXF_EXECUTOR=slurm
# Parameters
date="08012025"

analysis_dir="/home/USER/nfcore/sarek/"$date
storage_dir="/home/USER/nfcore/sarek/"$date
scratch_dir="/scratch/HOSPITAL/hospital_"$SLURM_JOB_ID

echo "Use Java AMZN 17"
export JAVA_HOME="/home/USER/.sdkman/candidates/java/17.0.6-amzn"

echo "Automatic downloads and updates are disabled."
export NXF_OFFLINE=false

echo "Use NEXTFLOW version 23.04.4"
export NXF_VER=23.04.4

echo "Define workdir in /scratch:"
echo ${scratch_dir}
mkdir -p ${scratch_dir}
export NXF_WORK=${scratch_dir}

echo "SAREK EXEC:"
srun /home/$(whoami)/bin/nextflow run /genomics/HOSPITAL/nf-core-sarek_3.3.2/3_3_2/\
     --step             mapping \
     --input            /home/$(whoami)/nfcore/sarek/${date}/samplesheet.csv \
     --outdir           /home/$(whoami)/nfcore/sarek/${date}/output \
     --seq_platform     ILLUMINA \
     --igenomes_ignore    \
     --fasta            /home/$(whoami)/nfcore/sarek/${date}/WholeGenomeFasta/genome.fa \
     --fasta_fai        /home/$(whoami)/nfcore/sarek/${date}/WholeGenomeFasta/genome.fa.fai \
     --intervals        /home/$(whoami)/nfcore/sarek/${date}/SureSelect_v6.bed \
     --aligner          bwa-mem2 \
     --save_mapped		\
     --tools            haplotypecaller \
     --skip_tools       baserecalibrator \
     --wes              true \
     -profile           singularity \
     -c                 /home/$(whoami)/configs/nextflow.config \
     
sleep 30m

rm -rf ${scratch_dir}
