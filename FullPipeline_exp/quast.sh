## Summarize assembly with QUAST

out=$1
name=$2
data=$3
pwd=$4
threads=$5
RAM=$6
openpbs=$7
Conda=$8

if [ $RAM -gt 64 ]; then
  RAM=64
fi

printf "sh FullPipeline/quast.sh $1 $2 $3 $4 $5 $6\n# "

#############################

mkdir -p ${out}/results/AssemblyQC/Quast

### NOTE THAT QUAST ONLY ALLOWS 64 CORES MAX

if [[ $threads -gt 64 ]]; then
  threads=64
fi

echo """

  #!/bin/sh

  ## name of Job
  #PBS -N QUAST_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/Quast_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
  conda activate envs/quast

  ######## run analyses #######

  quast.py \
  --output-dir ${out}/results/AssemblyQC/Quast \
  --threads ${threads} \
  --eukaryote \
  -f \
  ${out}/output/${name}_${data}.fa

""" >${out}/shell/qsub_quast_${name}.sh

if [[ $openpbs != "no" ]]; then
  qsub ${out}/shell/qsub_quast_${name}.sh
else
  sh ${out}/shell/qsub_quast_${name}.sh &>${out}/log/Quast_${name}_log.txt
fi
