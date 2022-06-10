## make denovo assembly with Spades

out=$1
name=$2
data=$3
decont=$4
pwd=$5
threads=$6
RAM=$7

printf "sh FullPipeline/denovo.sh $1 $2 $3 $4 $5 $6 $7\n"

#############################

mkdir ${out}/results/assembly


if [[ $data == *'ILL'* ]]
then
  if [[ $decont == 'no' ]]
  then
    IllInp1=${name}_1_val_1
    IllInp2=${name}_2_val_2
  else
    IllInp1=kraken_illumina_${name}_1
    IllInp2=kraken_illumina_${name}_2
  fi
fi

if [[ $data == *'ONT'* ]]
then
  if [[ $decont == 'no' ]]
  then
    OntInp=${name}_ont
  else
    OntInp=raken_ont_${name}
  fi
fi

if [[ $data == *'PB'* ]]
then
  if [[ $decont == 'no' ]]
  then
    PbInp=${name}_pb
  else
    PbInp=raken_${name}_pb
  fi
fi


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

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## load all necessary software into environment
  module load Assembly/SPAdes_3.15.3

  ## Go to pwd
  cd ${pwd}

  if [[ ( $data == 'ILL' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/${IllInp1}.fq.gz \
      -2 ${out}/data/Illumina/${IllInp2}.fq.gz \
      -t ${threads} \
      -m ${RAM} \
      -o ${out}/results/assembly/${name}

    if [[ -f ${out}/results/assembly/${name}/scaffolds.fasta ]]
    then
      mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa
    else
      mv ${out}/results/assembly/${name}/contigs.fasta ${out}/output/${name}_${data}.fa
    fi

  elif [[ ( $data == 'ILL_ONT' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/${IllInp1}.fq.gz \
      -2 ${out}/data/Illumina/${IllInp2}.fq.gz \
      --nanopore ${out}/data/ONT/${OntInp}.fq.gz \
      -t ${threads} \
      -m ${RAM} \
      -o ${out}/results/assembly/${name}

    if [[ -f ${out}/results/assembly/${name}/scaffolds.fasta ]]
    then
      mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa
    else
      mv ${out}/results/assembly/${name}/contigs.fasta ${out}/output/${name}_${data}.fa
    fi

  elif [[ ( $data == 'ILL_PB' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/${IllInp1}.fq.gz \
      -2 ${out}/data/Illumina/${IllInp2}.fq.gz \
      --pacbio ${out}/data/PB/${PbInp}.fq.gz \
      -t ${threads} \
      -m ${RAM} \
      -o ${out}/results/assembly/${name}

    if [[ -f ${out}/results/assembly/${name}/scaffolds.fasta ]]
    then
      mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa
    else
      mv ${out}/results/assembly/${name}/contigs.fasta ${out}/output/${name}_${data}.fa
    fi

  elif [[ ( $data == 'ILL_ONT_PB' ) ]]
  then

    spades.py \
      -1 ${out}/data/Illumina/${IllInp1}.fq.gz \
      -2 ${out}/data/Illumina/${IllInp2}.fq.gz \
      --pacbio ${out}/data/PB/${PbInp}.fq.gz \
      --nanopore ${out}/data/ONT/${OntInp}.fq.gz \
      -t ${threads} \
      -m ${RAM} \
      -o ${out}/results/assembly/${name}

    if [[ -f ${out}/results/assembly/${name}/scaffolds.fasta ]]
    then
      mv ${out}/results/assembly/${name}/scaffolds.fasta ${out}/output/${name}_${data}.fa
    else
      mv ${out}/results/assembly/${name}/contigs.fasta ${out}/output/${name}_${data}.fa
    fi

  elif [[ ( $data == 'ONT' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    ## Flye only accepts 128 threads max
    if [[ $threads -gt 128 ]]
    then
      threads=128
    fi

    flye \
    --nano-raw ${out}/data/ONT/${OntInp}.fq.gz \
    --out-dir ${out}/results/assembly/${name} \
    --threads ${threads} \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'PB' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    ## Flye only accepts 128 threads max
    if [[ $threads -gt 128 ]]
    then
      threads=128
    fi

    flye \
    --pacbio-raw ${out}/data/PB/${PbInp}.fq.gz \
    --out-dir ${out}/results/assembly/${name} \
    --threads ${threads} \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa

  elif [[ ( $data == 'ONT_PB' ) ]]
  then

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate flye-2.9

    ## see here: https://github.com/fenderglass/Flye/blob/flye/docs/FAQ.md#can-i-use-both-pacbio-and-ont-reads-for-assembly

    ## Flye only accepts 128 threads max
    if [[ $threads -gt 128 ]]
    then
      threads=128
    fi

    flye \
    --pacbio-raw ${out}/data/ONT/${OntInp}.fq.gz \
    ${out}/data/PB/${PbInp}.fq.gz \
    --iterations 0 \
    --out-dir ${out}/results/assembly/${name} \
    --threads ${threads}

    flye \
    --nano-raw ${out}/data/ONT/${OntInp}.fq.gz \
     --resume-from polishing \
    --out-dir ${out}/results/assembly/${name} \
    --threads ${threads} \
    --scaffold

    mv ${out}/results/assembly/${name}/assembly.fasta ${out}/output/${name}_${data}.fa
  fi
""" > ${out}/shell/qsub_assembly_${name}.sh

printf "# "
qsub -W block=true ${out}/shell/qsub_assembly_${name}.sh
