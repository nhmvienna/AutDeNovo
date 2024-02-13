### estimate genome size

out=$1
name=$2
data=$3
decont=$4
pwd=$5
threads=$6
RAM=$7
RAMAssembly=$8
openpbs=$9
Conda=$10
PrintOnly=$11

printf "sh FullPipeline_exp/genomesize.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11}\n# "

#############################

mkdir ${out}/results/GenomeSize

if [[ $data == *'ILL'* ]]; then
  if [[ $decont == 'no' ]]; then
    IllInp1=${name}_1_val_1
    IllInp2=${name}_2_val_2
  else
    IllInp1=kraken_illumina_${name}_1
    IllInp2=kraken_illumina_${name}_2
  fi
fi

if [[ $data == *'ONT'* ]]; then
  if [[ $decont == 'no' ]]; then
    OntInp=${name}_ont
  else
    OntInp=raken_ont_${name}
  fi
fi

if [[ $data == *'PB'* ]]; then
  if [[ $decont == 'no' ]]; then
    PbInp=${name}_pb
  else
    PbInp=raken_${name}_pb
  fi
fi

### run JellyFish to obtain k-mer histograms

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N jellyfish_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/GenomeSize_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum walltime of 2h
  #PBS -l walltime=48:00:00

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAMAssembly}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  source ${Conda}/etc/profile.d/conda.sh
  conda activate envs/jellyfish

  if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
  then

    ## unzip files

    gunzip -c ${out}/data/Illumina/${IllInp1}.fq.gz > ${out}/data/Illumina/${IllInp1}.fq &
    gunzip -c ${out}/data/Illumina/${IllInp2}.fq.gz > ${out}/data/Illumina/${IllInp2}.fq

    wait

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish count \
      -C \
      -m 31 \
      -s 100M \
      -t ${threads} \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/Illumina/${IllInp1}.fq \
      ${out}/data/Illumina/${IllInp2}.fq

    rm -f ${out}/data/Illumina/${IllInp1}.fq ${out}/data/Illumina/${IllInp2}.fq

  fi

  if [[ ( $data == 'ONT' ) || ( $data == 'ONT_PB' ) ]]
  then

    ## unzip ONT file

    gunzip -c ${out}/data/ONT/${OntInp}.fq.gz > ${out}/data/ONT/${OntInp}.fq

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish count \
      -C \
      -m 31 \
      -s 100M \
      -t ${threads} \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/ONT/${OntInp}.fq

    rm -f  ${out}/data/ONT/${OntInp}.fq

  fi

  if [[ ( $data == 'PB' ) ]]
  then

    ## unzip file

    gunzip -c ${out}/data/PB/${PbInp}.fq.gz > ${out}/data/PB/${PbInp}.fq

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish count \
      -C \
      -m 31 \
      -s 100M \
      -t ${threads} \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/PB/${PbInp}.fq

    rm -f  ${out}/data/PB/${PbInp}.fq

  fi

  jellyfish histo \
    -t ${threads} \
    ${out}/results/GenomeSize/${name}_reads.jf \
    > ${out}/results/GenomeSize/${name}_reads.histo

  ## run GenomeScope
  conda deactivate
  conda activate envs/genomescope

  genomescope2 \
  -i ${out}/results/GenomeSize/${name}_reads.histo \
  -k 31 \
  -p 2 \
  -o ${out}/results/GenomeSize/${name}
""" >${out}/shell/qsub_genomesize_${name}.sh

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_genomesize_${name}.sh
  else
    sh ${out}/shell/qsub_genomesize_${name}.sh &>${out}/log/GenomeSize_${name}_log.txt
  fi
fi
