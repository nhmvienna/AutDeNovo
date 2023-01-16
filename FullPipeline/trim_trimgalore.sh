##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
threads=$4
RAM=$5
BaseQuality=$6
MinReadLen=$7

printf "sh FullPipeline/trim_atria.sh $1 $2 $3 $4 $5 $6 $7\n# "

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N trim_galore_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/trim_galore_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select ${threads} cores and ${RAM}gb of RAM
#PBS -l select=1:ncpus=${threads}:mem=${RAM}g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate trim-galore-0.6.2

## Go to pwd
cd ${pwd}

## Go to output folder
cd ${out}/data/Illumina

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp and automatically detect & remove adapters

trim_galore \
  --paired \
  --quality ${BaseQuality} \
  --length ${MinReadLen}  \
  --cores ${threads} \
  --fastqc \
  --gzip \
  ${name}_1.fq.gz \
  ${name}_2.fq.gz

""" >${out}/shell/qsub_trim_${name}.sh

qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
