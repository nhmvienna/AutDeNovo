## Mapping reads against the de-novo assembled reference

out=$1
name=$2
data=$3
decont=$4
pwd=$5
threads=$6
RAM=$7

printf "sh FullPipeline/mapping.sh $1 $2 $3 $4 $5 $6 $7\n# "

#############################

mkdir ${out}/results/mapping

if [[ $data == *'ILL'* ]]
then
  if [[ $decont == 'no' ]]
  then
    IllInp1=${name}_1_val_1
    IllInp2=${name}_2_val_2
  else
    IllInp1=kraken_illumina_${name}_1
    IllInp2=kraken_illumina_${name}_2
  fi
fi

if [[ $data == *'ONT'* ]]
then
  if [[ $decont == 'no' ]]
  then
    OntInp=${name}_ont
  else
    OntInp=raken_ont_${name}
  fi
fi

if [[ $data == *'PB'* ]]
then
  if [[ $decont == 'no' ]]
  then
    PbInp=${name}_pb
  else
    PbInp=raken_${name}_pb
  fi
fi


echo """
  #!/bin/sh

  ## name of Job
  #PBS -N mapping_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/mapping_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

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
    bwa index ${out}/output/${name}_${data}.fa

    bwa mem \
      -t ${threads} \
      ${out}/output/${name}_${data}.fa \
      ${out}/data/Illumina/${IllInp1}.fq.gz \
      ${out}/data/Illumina/${IllInp2}.fq.gz \
      | samtools view -bh | samtools sort \
      > ${out}/results/mapping/${name}.bam

  elif [[ ( $data == 'ONT' ) || ( $data == 'ONT_PB' ) ]]
  then

    ## index reference
    minimap2 -d ${out}/output/${name}_${data}.mmi \
      ${out}/output/${name}_${data}.fa

    minimap2 -ax map-ont \
    -t ${threads} \
    ${out}/output/${name}_${data}.fa \
    ${out}/data/ONT/${OntInp}.fq.gz \
    | samtools view -bh | samtools sort \
    > ${out}/results/mapping/${name}.bam

  else

    ## index reference
    minimap2 -d ${out}/output/${name}_${data}.mmi \
      ${out}/output/${name}_${data}.fa

    minimap2 -ax map-pb \
    -t ${threads} \
    ${out}/output/${name}_${data}.fa \
    ${out}/data/PB/${PbInp}.fq.gz \
    | samtools view -bh | samtools sort \
    > ${out}/results/mapping/${name}.bam
  fi

""" > ${out}/shell/qsub_bwa_${name}.sh

qsub -W block=true ${out}/shell/qsub_bwa_${name}.sh
