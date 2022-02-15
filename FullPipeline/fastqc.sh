##  trim and QC of raw reads

out=$1
name=$2

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N fastqc_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/raw_fastqc_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select a maximum of 200 cores and 1000gb of RAM
#PBS -l select=1:ncpus=200:mem=100g

######## load dependencies #######

module load Tools/FastQC-0.11.9

## Go to output folder
cd ${out}/data

mkdir -p ${out}/results/rawQC

## loop through all raw FASTQ and test quality

fastqc \
  --outdir ${out}/results/rawQC \
  --threads 200 \
  ${name}_1.fq.gz \
  ${name}_2.fq.gz

""" > ${out}/shell/qsub_fastqc_${name}.sh

qsub -W block=true ${out}/shell/qsub_fastqc_${name}.sh
