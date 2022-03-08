## make denovo assembly with Spades

out=$1
name=$2
data=$3
pwd=$4

printf "sh FullPipeline/denovo.sh $1 $2 $3 $4\n"

#############################

mkdir ${out}/results/assembly

if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
then

  printf "# Assembly of $data with Spades\n# "
  date

else

  printf "# Assembly of $data with Flye\n# "
  date

fi

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

  if [[ ( $data == 'ILL' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/kraken_illumina_${name}_1.fq.gz \
      -2 ${out}/data/Illumina/kraken_illumina_${name}_2.fq.gz \
      -t 199 \
      -m 1200 \
      -o ${out}/results/assembly/${name}

    mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ILL_PB' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/kraken_illumina_${name}_1.fq.gz \
      -2 ${out}/data/Illumina/kraken_illumina_${name}_2.fq.gz \
      --nanopore ${out}/data/ONT/kraken_ont_${name}.fq.gz \
      -t 199 \
      -m 1200 \
      -o ${out}/results/assembly/${name}

    mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ILL_ONT' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/kraken_illumina_${name}_1.fq.gz \
      -2 ${out}/data/Illumina/kraken_illumina_${name}_2.fq.gz \
      --pacbio ${out}/data/PB/kraken_pb_${name}.fq.gz \
      -t 199 \
      -m 1200 \
      -o ${out}/results/assembly/${name}

    mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ILL_ONT_PB' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/kraken_illumina_${name}_1.fq.gz \
      -2 ${out}/data/Illumina/kraken_illumina_${name}_2.fq.gz \
      --pacbio ${out}/data/PB/kraken_pb_${name}.fq.gz \
      --nanopore ${out}/data/ONT/kraken_ont_${name}.fq.gz \
      -t 199 \
      -m 1200 \
      -o ${out}/results/assembly/${name}

    mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ONT' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    flye \
    --nano-raw ${out}/data/ONT/kraken_ont_${name}.fq.gz \
    --out-dir ${out}/results/assembly/${name} \
    --threads 200 \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'PB' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    flye \
    --pacbio-raw ${out}/data/PB/kraken_pb_${name}.fq.gz \
    --out-dir ${out}/results/assembly/${name} \
    --threads 128 \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ONT_PB' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    ## see here: https://github.com/fenderglass/Flye/blob/flye/docs/FAQ.md#can-i-use-both-pacbio-and-ont-reads-for-assembly

    flye \
    --pacbio-raw ${out}/data/ONT/kraken_ont_${name}.fq.gz \
    ${out}/data/PB/kraken_pb_${name}.fq.gz \
    --iterations 0 \
    --out-dir ${out}/results/assembly/${name} \
    --threads 128

    flye \
    --nano-raw ${out}/data/ONT/kraken_ont_${name}.fq.gz \
     --resume-from polishing \
    --out-dir ${out}/results/assembly/${name} \
    --threads 128 \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa
  fi
""" > ${out}/shell/qsub_assembly_${name}.sh

printf "# "
qsub -W block=true ${out}/shell/qsub_assembly_${name}.sh
