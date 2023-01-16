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
#PBS -N trim_urqt_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/trim_urqt_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select ${threads} cores and ${RAM}gb of RAM
#PBS -l select=1:ncpus=${threads}:mem=${RAM}g

######## load dependencies #######

module load Tools/UrQt-1.0.17

## Go to pwd
cd ${pwd}

## Go to output folder
cd ${out}/data/Illumina

## loop through all FASTQ pairs and trim by quality PHRED 20, min length 85bp

UrQt \
--t ${BaseQuality} \
--m ${threads} \
--min_read_size ${MinReadLen} \
--in ${name}_1.fq.gz \
--inpair ${name}_2.fq.gz \
--out ${name}_1_val_1.fq \
--outpair ${name}_2_val_2.fq

pigz ${name}_*_val_*.fq

""" >${out}/shell/qsub_trim_${name}.sh

qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
