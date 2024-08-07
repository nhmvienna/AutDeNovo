## Mapping reads against the de-novo assembled reference

out=$1
name=$2
data=$3
decont=$4
pwd=$5
threads=$6
RAM=$7
openpbs=$8
PrintOnly=$9

printf "bash FullPipeline_exp/mapping.sh $1 $2 $3 $4 $5 $6 $7 $8 $9\n# "

#############################

mkdir ${out}/results/mapping

if [[ $data == *'ILL'* ]]; then
  if [[ $decont == 'no' ]]; then
    IllInp1=${name}_1_val_1
    IllInp2=${name}_2_val_2
  else
    IllInp1=kraken_illumina_${name}_1
    IllInp2=kraken_illumina_${name}_2
  fi
fi

if [[ $data == *'ONT'* ]]; then
  if [[ $decont == 'no' ]]; then
    OntInp=${name}_ont
  else
    OntInp=raken_ont_${name}
  fi
fi

if [[ $data == *'PB'* ]]; then
  if [[ $decont == 'no' ]]; then
    PbInp=${name}_pb
  else
    PbInp=raken_${name}_pb
  fi
fi

echo """
  #!/usr/bin/env bash

  ## name of Job
  #PBS -N mapping_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/mapping_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  eval \"\$(conda shell.bash hook)\"

  ######## run analyses #######

  if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
  then

    conda activate envs/bwa

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

    conda activate envs/minimap

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

    conda activate envs/minimap

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

""" >${out}/shell/qsub_bwa_${name}.sh

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_bwa_${name}.sh
  else
    bash ${out}/shell/qsub_bwa_${name}.sh &>${out}/log/mapping_${name}_log.txt
  fi
fi
