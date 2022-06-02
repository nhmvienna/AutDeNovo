## screen and filter reads for bacterial and human DNA contamination

out=$1
name=$2
data=$3
pwd=$4
threads=$5
RAM=$6

printf "sh FullPipeline/kraken.sh $1 $2 $3 $4 $5 $6\n# "

#############################

mkdir ${out}/results/kraken_reads

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N kraken_reads_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/kraken_reads_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum walltime of 2h
  #PBS -l walltime=48:00:00

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## load all necessary software into environment
  module load Assembly/kraken-2.1.2

  ## Go to pwd
  cd ${pwd}

  if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
  then

    kraken2 \
    --threads 200 \
    --output - \
    --report ${out}/results/kraken_reads/${name}_Illumina.report \
    --use-names \
    --gzip-compressed \
    --unclassified-out ${out}/data/Illumina/kraken_illumina_${name}#.fq ${name}_1.fq ${name}_2.fq \
    --paired \
    --db /media/scratch/kraken-2.1.2/db/standard_20210517 \
    ${out}/data/Illumina/${name}_1_val_1.fq.gz \
    ${out}/data/Illumina/${name}_2_val_2.fq.gz

    awk '\$1> 0.0' ${out}/results/kraken_reads/${name}_Illumina.report \
    > ${out}/results/kraken_reads/${name}_Illumina_filtered.report

    pigz -p200 ${out}/data/Illumina/kraken*.fq

    rm -f ${out}/data/Illumina/kraken*.fq
  fi

  if [[ ( $data == 'ONT' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_ONT_PB' ) || ( $data == 'ONT_PB' ) ]]
  then

    kraken2 \
    --threads 200 \
    --output - \
    --report ${out}/results/kraken_reads/${name}_ONT.report \
    --use-names \
    --gzip-compressed \
    --unclassified-out ${out}/data/ONT/kraken_ont_${name}.fq \
    --db /media/scratch/kraken-2.1.2/db/standard_20210517 \
    ${out}/data/ONT/${name}_ont.fq.gz \

    awk '\$1> 0.0' ${out}/results/kraken_reads/${name}_ONT.report \
    > ${out}/results/kraken_reads/${name}_ONT_filtered.report

    pigz -p200 ${out}/data/ONT/kraken_ont_${name}.fq

    rm -f ${out}/data/ONT/kraken_ont_${name}.fq

  fi

  if [[ ( $data == 'PB' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) || ( $data == 'ONT_PB' ) ]]
    then

      kraken2 \
      --threads 200 \
      --output - \
      --report ${out}/results/kraken_reads/${name}_PB.report \
      --use-names \
      --gzip-compressed \
      --unclassified-out ${out}/data/PB/kraken_pb_${name}.fq \
      --db /media/scratch/kraken-2.1.2/db/standard_20210517 \
      ${out}/data/PB/${name}_pb.fq.gz \

      awk '\$1> 0.0' ${out}/results/kraken_reads/${name}_PB.report \
      > ${out}/results/kraken_reads/${name}_PB_filtered.report

      pigz -p200 ${out}/data/PB/kraken_pb_${name}.fq

      rm -f ${out}/data/PB/kraken_pb_${name}.fq
    fi

""" > ${out}/shell/qsub_kraken_reads_${name}.sh

qsub -W block=true ${out}/shell/qsub_kraken_reads_${name}.sh
