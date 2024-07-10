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
#PBS -N trim_atria_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/trim_atria_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select ${threads} cores and ${RAM}gb of RAM
#PBS -l select=1:ncpus=${threads}:mem=${RAM}g

######## load dependencies #######

module load Tools/atria-3.1.2

## Go to pwd
cd ${pwd}

## Go to output folder
cd ${out}/data/Illumina

pwd | echo

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp

atria \
  --no-adapter-trim \
  --quality-score ${BaseQuality} \
  --threads ${threads} \
  --length-range ${MinReadLen}:500 \
  --read1 ${name}_1.fq.gz \
  --read2 ${name}_2.fq.gz

mv ${name}_1.atria.fq.gz ${name}_1_val_1.fq.gz
mv ${name}_2.atria.fq.gz ${name}_2_val_2.fq.gz

""" >${out}/shell/qsub_trim_${name}.sh

qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
