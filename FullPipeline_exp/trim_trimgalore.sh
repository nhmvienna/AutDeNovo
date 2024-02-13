##  trim and QC of raw reads

out=$1
name=$2
pwd=$3
threads=$4
RAM=$5
BaseQuality=$6
MinReadLen=$7
openpbs=$8
Conda=$9
PrintOnly=$10

printf "sh FullPipeline_exp/trim_atria.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}\n# "

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

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
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

if [[ $PrintOnly == "yes" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_trim_${name}.sh
  else
    sh ${out}/shell/qsub_trim_${name}.sh &>${out}/log/trim_galore_${name}_log.txt
  fi
fi
