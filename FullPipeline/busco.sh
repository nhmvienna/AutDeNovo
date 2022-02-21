## BUSCO analysis

out=$1
name=$2
busco=$3
data=$4
pwd=$5

#############################

mkdir -p ${out}/results/AssemblyQC/Busco

echo """

  #!/bin/sh

  ## name of Job
  #PBS -N BUSCO_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/Busco_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 200 cores and 1000gb of RAM
  #PBS -l select=1:ncpus=200:mem=500g

  ######## load dependencies #######

  source /opt/anaconda3/etc/profile.d/conda.sh
  conda activate busco_5.2.2

  ######## run analyses #######

  ## Go to pwd
  cd ${pwd}

  cd ${out}/results/AssemblyQC/Busco

  busco -i ../../../output/${name}_${data}.fa \
    -o ${name} \
    -m genome \
    -c 200 \
    -f \
    -l ${busco}

""" > ${out}/shell/qsub_busco_${name}.sh

qsub -W block=true ${out}/shell/qsub_busco_${name}.sh
