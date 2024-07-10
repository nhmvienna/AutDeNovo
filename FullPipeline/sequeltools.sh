##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
pb=$4

printf "sh FullPipeline/sequeltools.sh $1 $2 $3 $4\n# "

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N sequeltools_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/raw_sequeltools_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select a maximum of 200 cores and 1000gb of RAM
#PBS -l select=1:ncpus=200:mem=100g

######## load dependencies #######

module load Tools/SequelTools

######## run analyses #######

## Go to pwd
cd ${pwd}

mkdir -p ${out}/results/rawQC

echo ${pb}/*subreads.bam > ${out}/results/rawQC/${name}_PB_subFiles.txt
echo ${pb}/*scraps.bam > ${out}/results/rawQC/${name}_PB_scrFiles.txt

SequelTools.sh \
-t Q \
-n 200 \
-u ${out}/results/rawQC/${name}_PB_subFiles.txt \
-c ${out}/results/rawQC/${name}_PB_scrFiles.txt \
-o ${out}/results/rawQC/${name}_PB_sequeltools

mv ${out}/results/rawQC/${name}_PB_*.txt ${out}/results/rawQC/${name}_PB_sequeltools

""" > ${out}/shell/qsub_sequeltools_${name}.sh

qsub -W block=true ${out}/shell/qsub_sequeltools_${name}.sh
