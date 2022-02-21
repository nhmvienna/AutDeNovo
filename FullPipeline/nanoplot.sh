##  trim and QC of raw reads

out=$1
name=$2
pwd=$3

#############################

echo """
#!/bin/sh

## name of Job
#PBS -N nanoplot_${name}

## Redirect output stream to this file.
#PBS -o ${out}/log/raw_nanoplot_${name}_log.txt

## Stream Standard Output AND Standard Error to outputfile (see above)
#PBS -j oe

## Select a maximum of 200 cores and 1000gb of RAM
#PBS -l select=1:ncpus=200:mem=100g

######## load dependencies #######

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate nanoplot_1.32.1

######## run analyses #######

## Go to pwd
cd ${pwd}

mkdir -p ${out}/results/rawQC

## loop through all raw FASTQ and test quality

NanoPlot \
  -t 200 \
  --summary ${out}/data/ONT/${name}_sequencing_summary.txt \
  --plots dot \
  -o ${out}/results/rawQC/${name}_ONT_nanoplot


## convert HTML Report to PDF

source /opt/anaconda3/etc/profile.d/conda.sh
conda activate base

pandoc -f html \
-t pdf \
-o ${out}/results/rawQC/${name}_ONT_nanoplot/${name}_ONT_nanoplot-report.pdf \
${out}/results/rawQC/${name}_ONT_nanoplot/NanoPlot-report.html

""" > ${out}/shell/qsub_nanoplot_${name}.sh

qsub -W block=true ${out}/shell/qsub_nanoplot_${name}.sh
