##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
threads=$4
RAM=$5

printf "sh FullPipeline/fastqc.sh $1 $2 $3 2 $5\n# "

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N fastqc_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/raw_fastqc_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select ${threads} cores and ${RAM}gb of RAM
#PBS -l select=1:ncpus=2:mem=${RAM}g

######## load dependencies #######

module load Tools/FastQC-0.11.9

## Go to pwd
cd ${pwd}

mkdir -p ${out}/results/rawQC/${name}_Illumina_fastqc

## Go to output folder
cd ${out}/data

## loop through all raw FASTQ and test quality

fastqc \
  --outdir ../results/rawQC/${name}_Illumina_fastqc \
  --threads 2 \
  Illumina/${name}_1.fq.gz \
  Illumina/${name}_2.fq.gz

""" > ${out}/shell/qsub_fastqc_${name}.sh

qsub ${out}/shell/qsub_fastqc_${name}.sh
