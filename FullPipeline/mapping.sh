## Mapping reads against the de-novo assembled reference

out=$1
name=$2
pwd=$3

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
  module load Tools/samtools-1.12

  ######## run analyses #######

  ## Go to pwd
  cd ${pwd}

  bwa index ${out}/results/assembly/${name}/scaffolds.fasta

  bwa mem \
    -t 200 \
    ${out}/results/assembly/${name}/scaffolds.fasta \
    ${out}/data/kraken_${name}_1.fq.gz \
    ${out}/data/kraken_${name}_2.fq.gz \
    | samtools view -bh | samtools sort \
    > ${out}/results/mapping/${name}.bam

""" > ${out}/shell/qsub_bwa_${name}.sh

qsub -W block=true ${out}/shell/qsub_bwa_${name}.sh
