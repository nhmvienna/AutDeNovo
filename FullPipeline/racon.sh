## Polish contigs with Racon

out=$1
name=$2
data=$3
pwd=$4
threads=$5
RAM=$6
racon=$7
decont=$8

printf "sh FullPipeline/racon.sh $1 $2 $3 $4 $5 $6 $7 $8\n# "

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

  ######## load dependencies #######

  source /opt/anaconda3/etc/profile.d/conda.sh
  module load NGSmapper/minimap2-2.17
  conda activate racon_1.5.0
  conda activate medaka-1.4.4

  ######## run analyses #######

  ## Go to pwd
  cd ${pwd}

  ## concatenate Illumina data (if needed)

  if [[ $data == 'ILL' ]]
  then
    gunzip -c ${out}/data/Illumina/${IllInp1}.fq.gz \
      | sed 's/ 1:.*/\/1/g' \
      | gzip > ${out}/results/Racon/Ill.fq.gz

    gunzip -c ${out}/data/Illumina/${IllInp2}.fq.gz \
      | sed 's/ 2:.*/\/2/g' \
      | gzip >> ${out}/results/Racon/Ill.fq.gz
  fi

  ## make copy of unpolished contigs

  cp ${out}/output/${name}_${data}.fa ${out}/output/${name}_${data}_unpolished.fa
  pigz ${out}/output/${name}_${data}_unpolished.fa

  ## do Racon polishing
  for (( i=1; i<=${racon}; i++ ))

  do

    if [[ $data == 'ILL' ]]
    then

      minimap2 \
        -x sr \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/results/Racon/Ill.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

      racon \
        -t ${threads} \
        ${out}/results/Racon/Ill.fq.gz \
        ${out}/results/Racon/temp_reads_to_draft.paf \
        ${out}/output/${name}_${data}.fa \
        > ${out}/results/Racon/temp_draft_new.fa

    elif [[ $data == *'ONT'* ]]
    then

      minimap2 \
        -x map-ont \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/data/ONT/${OntInp}.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

      racon \
        -t ${threads} \
        ${out}/data/ONT/${OntInp}.fq.gz \
        ${out}/results/Racon/temp_reads_to_draft.paf \
        ${out}/output/${name}_${data}.fa \
        > ${out}/results/Racon/temp_draft_new.fa

    else

      minimap2 \
        -x map-pb \
        -t ${threads} \
        ${out}/output/${name}_${data}.fa \
        ${out}/data/PB/${PbInp}.fq.gz \
        > ${out}/results/Racon/temp_reads_to_draft.paf

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

""" > ${out}/shell/qsub_racon_${name}.sh

qsub -W block=true ${out}/shell/qsub_racon_${name}.sh
