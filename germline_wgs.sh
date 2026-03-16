#!/bin/bash

#SBATCH -p hospital
#SBATCH -c 4
#SBATCH --mem=8gb
#SBATCH --time=240:00:00
#SBATCH --output=sarek_%j.out
#SBATCH --error=sarek_%j.err
#SBATCH --mail-type=END,FAIL


unset XDG_RUNTIME_DIR
export NXF_EXECUTOR=slurm

# Parameters
date="230414"
scratch_dir="/scratch/HOSPITAL/hospital_"$SLURM_JOB_ID
analysis_dir="/home/USER/nfcore/sarek/"$date
storage_dir="/home/USER/nfcore/sarek/outputs/"$date

echo "Use Java downloaded by SDKMAN"
export JAVA_HOME="/home/USER/.sdkman/candidates/java/17.0.6-amzn"

echo "Automatic downloads and updates are enabled."
export NXF_OFFLINE=false

echo "Use NEXTFLOW version 23.10.1"
export NXF_VER=23.10.1

echo "Define workdir in /scratch:"
echo ${scratch_dir}
mkdir -p ${scratch_dir}
export NXF_WORK=${scratch_dir}

echo "SAREK EXEC:"
srun /genomics/USER/bin/nextflow run /home/USER/resources/nf-core-sarek_3.4.2/3_4_2 \
     --step             mapping \
     --input            /home/$(whoami)/nfcore/sarek/${date}/samplesheet.csv \
     --outdir           /home/$(whoami)/nfcore/sarek/${date}/output \
     --igenomes_base    /genomics/HOSPITAL/data/igenomes/ \
     --seq_platform     ILLUMINA \
     --genome           GATK.GRCh38 \
     --aligner          bwa-mem2 \
     --tools            haplotypecaller,cnvkit,vep \
     --vep_version	110 \
     --vep_cache        /genomics/HOSPITAL/data/cache/vep_cache \
     --vep_dbnsfp	true \
     --dbnsfp		/genomics/HOSPITAL/data/dbsnfp/dbNSFP_grch38.gz \
     --dbnsfp_tbi	/genomics/HOSPITAL/data/dbsnfp/dbNSFP_grch38.gz.tbi \
     --intervals	/home/$(whoami)/nfcore/sarek/${date}/hg38.bed \
     --wes              false \
     -profile           singularity \
     -c                 /home/$(whoami)/configs/nextflow.config \

sleep 30m

rm -rf ${scratch_dir}

echo "Send the results to the storage cabin"
mkdir -p ${storage_dir}
cp -r ${analysis_dir}"/output"           ${storage_dir}"/output"
cp    ${analysis_dir}"/samplesheet.csv"  ${storage_dir}"/samplesheet.csv"
cp    ${analysis_dir}"/germinal.sh" ${storage_dir}"/germinal.sh"

