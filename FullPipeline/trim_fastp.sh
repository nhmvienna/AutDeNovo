##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
threads=$4
RAM=$5

printf "sh FullPipeline/trim_fastp.sh $1 $2 $3 $4 $5\n# "

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N trim_fastp_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/trim_fastp_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select ${threads} cores and ${RAM}gb of RAM
#PBS -l select=1:ncpus=${threads}:mem=${RAM}g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate fastp

## Go to pwd
cd ${pwd}

## Go to output folder
cd ${out}/data/Illumina

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp and automatically detect & remove adapters

fastp \
  --qualified_quality_phred 20 \
  --thread ${threads} \
  --length_required 85 \
  -i ${name}_1.fq.gz \
  -I ${name}_2.fq.gz \
  -o ${name}_1_val_1.fq.gz \
  -O ${name}_2_val_2.fq.gz

""" > ${out}/shell/qsub_trim_${name}.sh

qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
