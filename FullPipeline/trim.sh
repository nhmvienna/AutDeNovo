##  trim and QC of raw reads

out=$1
name=$2

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N trim_galore_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/trim_galore_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select a maximum of 200 cores and 1000gb of RAM
#PBS -l select=1:ncpus=200:mem=100g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate trim-galore-0.6.2

## Go to output folder
cd ${out}/data

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp and automatically detect & remove adapters

trim_galore \
  --paired \
  --quality 20 \
  --length 85  \
  --cores 200 \
  --fastqc \
  --gzip \
  ${name}_1.fq.gz \
  ${name}_2.fq.gz

""" > ${out}/shell/qsub_trim_${name}.sh

qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
