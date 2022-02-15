## make denovo assembly with Spades

out=$1
name=$2
pwd=$3

#############################

mkdir ${out}/results/assembly

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N denovo_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/assembly_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum walltime of 2h
  #PBS -l walltime=100:00:00

  ## Select a maximum of 20 cores and 500gb of RAM
  #PBS -l select=1:ncpus=200:mem=1200gb

  ## load all necessary software into environment
  module load Assembly/SPAdes_3.15.3

  ## Go to pwd
  cd ${pwd}

  ## execute first command, i.e. indexing a reference genome for mapping
  spades.py \
    -1 ${out}/data/kraken_${name}_1.fq.gz \
    -2 ${out}/data/kraken_${name}_2.fq.gz \
    -t 200 \
    -m 1200 \
    -o ${out}/results/assembly/${name}

""" > ${out}/shell/qsub_assembly_${name}.sh

qsub -W block=true ${out}/shell/qsub_assembly_${name}.sh
