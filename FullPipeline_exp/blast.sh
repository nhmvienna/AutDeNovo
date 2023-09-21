### and Blast

out=$1
name=$2
data=$3
pwd=$4
threads=$5
RAM=$6
BLASTdb=$7
openpbs=$8
Conda=$9

printf "sh FullPipeline/blast.sh $1 $2 $3 $4 $5 $6 $7\n# "

#############################

mkdir ${out}/results/BLAST

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N BLASTN_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/BLAST_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
  conda activate envs/blast

  ######## run analyses #######

  blastn \
    -num_threads ${threads} \
    -outfmt \"6 qseqid staxids bitscore std\" \
    -max_target_seqs 10 \
    -max_hsps 1 \
    -evalue 1e-25 \
    -db ${BLASTdb} \
    -query ${out}/output/${name}_${data}.fa \
    > ${out}/results/BLAST/blastn_${name}.txt

""" >${out}/shell/qsub_blastn_${name}.sh

if [[ $openpbs != "no" ]]; then
  qsub -W block=true ${out}/shell/qsub_blastn_${name}.sh
else
  sh ${out}/shell/qsub_blastn_${name}.sh &>${out}/log/BLAST_${name}_log.txt
fi
