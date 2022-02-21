## Mapping reads against the de-novo assembled reference

out=$1
name=$2
data=$3
pwd=$4

#############################

mkdir ${out}/results/mapping

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N mapping_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/mapping_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 20 cores and 200gb of RAM
  #PBS -l select=1:ncpus=200:mem=200gb

  ######## load dependencies #######

  module load NGSmapper/bwa-0.7.13
  module load NGSmapper/minimap2-2.17
  module load Tools/samtools-1.12

  ######## run analyses #######

  ## Go to pwd
  cd ${pwd}

  if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
  then

    ## index reference
    bwa index ${out}/results/output/${name}_${data}.fa

    bwa mem \
      -t 200 \
      ${out}/results/output/${name}_${data}.fa \
      ${out}/data/kraken_${name}_1.fq.gz \
      ${out}/data/kraken_${name}_2.fq.gz \
      | samtools view -bh | samtools sort \
      > ${out}/results/mapping/${name}.bam

  elif [[ ( $data == 'ONT' ) || ( $data == 'ONT_PB' ) ]]
  then

    ## index reference
    minimap2 -d ${out}/results/assembly/${name}/${name}_${data}.mmi \
      ${out}/results/output/${name}_${data}.fa

    minimap2 -ax map-ont \
    -t 100 \
    ${out}/results/output/${name}_${data}.fa \
    ${out}/data/ONT/kraken_ont_${name}.fq.gz \
    | samtools view -bh | samtools sort \
    > ${out}/results/mapping/${name}.bam

  else

    ## index reference
    minimap2 -d ${out}/results/assembly/${name}/${name}_${data}.mmi \
      ${out}/results/output/${name}_${data}.fa

    minimap2 -ax map-pb \
    -t 100 \
    ${out}/results/output/${name}_${data}.fa \
    ${out}/data/PB/kraken_pb_${name}.fq.gz \
    | samtools view -bh | samtools sort \
    > ${out}/results/mapping/${name}.bam
  fi

""" > ${out}/shell/qsub_bwa_${name}.sh

qsub -W block=true ${out}/shell/qsub_bwa_${name}.sh
