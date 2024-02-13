## Polish contigs with Racon

out=$1
name=$2
data=$3
pwd=$4
threads=$5
RAM=$6
racon=$7
decont=$8
openpbs=$9
Conda=$10
PrintOnly=$11

printf "sh FullPipeline_exp/racon.sh $1 $2 $3 $4 $5 $6 $7 $8 $8 ${10} ${11}\n# "

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

#############################

mkdir -p ${out}/results/Racon

echo """

  #!/bin/sh

  ## name of Job
  #PBS -N Racon_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/Racon_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
  conda activate envs/pigz

  ## concatenate Illumina data (if needed)

  if [[ $data == *'ILL' ]]
  then
    pigz -p ${threads} -dc ${out}/data/Illumina/${IllInp1}.fq.gz \
      | sed 's/ 1:.*/\/1/g' \
      | pigz -p ${threads} > ${out}/results/Racon/Ill.fq.gz

    pigz -p ${threads} -dc ${out}/data/Illumina/${IllInp2}.fq.gz \
      | sed 's/ 2:.*/\/2/g' \
      | pigz -p ${threads} >> ${out}/results/Racon/Ill.fq.gz
  fi

  ## make copy of unpolished contigs

  cp ${out}/output/${name}_${data}.fa ${out}/output/${name}_${data}_unpolished.fa
  pigz -p ${threads} ${out}/output/${name}_${data}_unpolished.fa

  ## do Racon polishing
  for (( i=1; i<=${racon}; i++ ))

  do

    if [[ $data == 'ILL' ]]
    then

      conda deactivate
      conda activate envs/minimap

      minimap2 \
        -x sr \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/results/Racon/Ill.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

      conda deactivate
      conda activate envs/racon

      racon \
        -t ${threads} \
        ${out}/results/Racon/Ill.fq.gz \
        ${out}/results/Racon/temp_reads_to_draft.paf \
        ${out}/output/${name}_${data}.fa \
        > ${out}/results/Racon/temp_draft_new.fa

    elif [[ $data == *'ONT'* ]]
    then

      conda deactivate
      conda activate envs/minimap
      
      minimap2 \
        -x map-ont \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/data/ONT/${OntInp}.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

      conda deactivate
      conda activate envs/racon
      
      racon \
        -t ${threads} \
        ${out}/data/ONT/${OntInp}.fq.gz \
        ${out}/results/Racon/temp_reads_to_draft.paf \
        ${out}/output/${name}_${data}.fa \
        > ${out}/results/Racon/temp_draft_new.fa

    else

      conda deactivate
      conda activate envs/minimap
      
      minimap2 \
        -x map-pb \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/data/PB/${PbInp}.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

      conda deactivate
      conda activate envs/racon
      
      racon \
        -t ${threads} \
        ${out}/data/PB/${PbInp}.fq.gz \
        ${out}/results/Racon/temp_reads_to_draft.paf \
        ${out}/output/${name}_${data}.fa \
        > ${out}/results/Racon/temp_draft_new.fa

    fi

    mv ${out}/results/Racon/temp_draft_new.fa ${out}/output/${name}_${data}.fa

  done

  if [[ $data == 'ILL' ]]
  then
    rm -f ${out}/results/Racon/Ill.fq.gz
  fi

  rm -rf ${out}/results/Racon/temp_reads_to_draft.paf

""" >${out}/shell/qsub_racon_${name}.sh

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_racon_${name}.sh
  else
    sh ${out}/shell/qsub_racon_${name}.sh &>${out}/log/Racon_${name}_log.txt
  fi
fi
