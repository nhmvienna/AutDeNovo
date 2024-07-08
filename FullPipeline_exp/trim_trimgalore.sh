##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
threads=$4
RAM=$5
BaseQuality=$6
MinReadLen=$7
openpbs=$8
PrintOnly=$9

printf "bash FullPipeline_exp/trim_trimgalore.sh $1 $2 $3 $4 $5 $6 $7 $8 $9\n# "

#############################

echo """
  #!/usr/bin/env bash

  ## name of Job
  #PBS -N trim_galore_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/trim_galore_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  eval \"\$(conda shell.bash hook)\"
  conda activate envs/trimgalore

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

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
  else
    bash ${out}/shell/qsub_trim_${name}.sh &>${out}/log/trim_galore_${name}_log.txt
  fi
fi
