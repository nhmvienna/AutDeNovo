## Summarize assembly with QUAST

out=$1
name=$2
pwd=$3

#############################

mkdir -p ${out}/results/AssemblyQC/Quast

echo """

  #!/bin/sh

  ## name of Job
  #PBS -N QUAST_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/Quast_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 200 cores and 1000gb of RAM
  #PBS -l select=1:ncpus=64:mem=500g

  ######## load dependencies #######

  module load Assembly/Quast-5.1.0rc1

  ######## run analyses #######

  ## Go to pwd
  cd ${pwd}

  ### NOTE THAT QUAST ONLY ALLOWS 64 CORES MAX

  quast.py \
  --output-dir ${out}/results/AssemblyQC/Quast \
  --threads 64 \
  --eukaryote \
  -f \
  ${out}/results/assembly/${name}/scaffolds.fasta

""" > ${out}/shell/qsub_quast_${name}.sh

qsub ${out}/shell/qsub_quast_${name}.sh
