### and Blast

out=$1
name=$2

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

  ## Select a maximum of 20 cores and 200gb of RAM
  #PBS -l select=1:ncpus=200:mem=200gb

  ######## load dependencies #######

  module load Alignment/ncbi-BLAST-2.12.0

  ######## run analyses #######

  blastn \
    -num_threads 200 \
    -outfmt \"6 qseqid staxids bitscore std\" \
    -max_target_seqs 10 \
    -max_hsps 1 \
    -evalue 1e-25 \
    -db /media/scratch/NCBI_nt_DB_210714/nt \
    -query ${out}/results/assembly/${name}/scaffolds.fasta  \
    > ${out}/results/BLAST/blastn_${name}.txt

""" > ${out}/shell/qsub_blastn_${name}.sh

qsub -W block=true ${out}/shell/qsub_blastn_${name}.sh
