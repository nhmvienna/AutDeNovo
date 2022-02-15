## screen and filter reads for bacterial and human DNA contamination

out=$1
name=$2
pwd=$3

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

  ## Select a maximum of 100 cores and 200gb of RAM
  #PBS -l select=1:ncpus=200:mem=400gb

  ## load all necessary software into environment
  module load Assembly/kraken-2.1.2

  ## Go to pwd
  cd ${pwd}

  kraken2 \
  --threads 200 \
  --output - \
  --report ${out}/results/kraken_reads/${name}.report \
  --use-names \
  --gzip-compressed \
  --unclassified-out ${out}/data/kraken_${name}#.fq ${name}_1.fq ${name}_2.fq \
  --paired \
  --db /media/scratch/kraken-2.1.2/db/standard_20210517 \
  ${out}/data/${name}_1_val_1.fq.gz \
  ${out}/data/${name}_2_val_2.fq.gz

  awk '\$1> 0.0' ${out}/results/kraken_reads/${name}.report \
  > ${out}/results/kraken_reads/${name}_filtered.report

  pigz -p200 ${out}/data/kraken*.fq

  rm -f ${out}/data/kraken*.fq

""" > ${out}/shell/qsub_kraken_reads_${name}.sh

qsub -W block=true ${out}/shell/qsub_kraken_reads_${name}.sh
