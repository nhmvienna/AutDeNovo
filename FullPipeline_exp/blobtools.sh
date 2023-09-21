## Summarize with blobtools

out=$1
name=$2
busco=$3
data=$4
pwd=$5
threads=$6
RAM=$7
openpbs=$8
Conda=$9

printf "sh FullPipeline/blobtools.sh $1 $2 $3 $4 $5 $6 $7\n# "

##########################

### and BlobTools
### and BlobTools
mkdir ${out}/results/AssemblyQC/blobtools
echo """
  #!/bin/sh

  ## name of Job
  #PBS -N blobtools_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/blobtools_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
  conda activate envs/blobtools

  mkdir ${out}/results/AssemblyQC/blobtools

  ## create a genome BlobDir
  blobtools add \
      --fasta ${out}/output/${name}_${data}.fa  \
      ${out}/results/AssemblyQC/blobtools

  ## add BLAST results
  blobtools add \
      --hits ${out}/results/BLAST/blastn_${name}.txt \
      --taxdump /media/scratch/NCBI_taxdump/ \
      --threads ${threads} \
      ${out}/results/AssemblyQC/blobtools

  ## add BUSCO results
  blobtools add \
      --busco ${out}/results/AssemblyQC/Busco/${name}/run_${busco}/full_table.tsv  \
      --threads ${threads} \
      ${out}/results/AssemblyQC/blobtools

  ## add coverage data
  blobtools add \
      --cov ${out}/results/mapping/${name}.bam \
      --threads ${threads} \
      ${out}/results/AssemblyQC/blobtools

""" >${out}/shell/qsub_blobtools_${name}.sh

if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_blobtools_${name}.sh
else
    sh ${out}/shell/qsub_blobtools_${name}.sh &>${out}/log/blobtools_${name}_log.txt
fi
