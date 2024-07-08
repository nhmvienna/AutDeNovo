## BUSCO analysis

out=$1
name=$2
busco=$3
data=$4
pwd=$5
threads=$6
RAM=$7
openpbs=$8
PrintOnly=$9

printf "bash FullPipeline_exp/busco.sh $1 $2 $3 $4 $5 $6 $7 $8 $9\n# "

#############################

mkdir -p ${out}/results/AssemblyQC/Busco

echo """

  #!/usr/bin/env bash

  ## name of Job
  #PBS -N BUSCO_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/Busco_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  eval \"\$(conda shell.bash hook)\"
  conda activate envs/busco

  ######## run analyses #######

  cd ${out}/results/AssemblyQC/Busco

  busco -i ../../../output/${name}_${data}.fa \
    -o ${name} \
    -m genome \
    -c ${threads} \
    -f \
    -l ${busco}

""" >${out}/shell/qsub_busco_${name}.sh

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_busco_${name}.sh
  else
    bash ${out}/shell/qsub_busco_${name}.sh &>${out}/log/Busco_${name}_log.txt
  fi
fi
