### estimate genome size

out=$1
name=$2
data=$3
decont=$4
pwd=$5
threads=$6
RAM=$7
RAMAssembly=$8
SmudgePlot=$9

printf "sh FullPipeline/genomesize.sh $1 $2 $3 $4 $5 $6 $7 $8 $9\n# "

#############################

mkdir ${out}/results/GenomeSize


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

  ## load all necessary software into environment
  module load Assembly/Jellyfish-2.3.0
  module load Assembly/genomescope-2.0

  ## Go to pwd
  cd ${pwd}

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
    jellyfish-linux count \
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
    jellyfish-linux count \
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
    jellyfish-linux count \
      -C \
      -m 31 \
      -s 100M \
      -t ${threads} \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/PB/${PbInp}.fq

    rm -f  ${out}/data/PB/${PbInp}.fq

  fi

  jellyfish-linux histo \
    -t ${threads} \
    ${out}/results/GenomeSize/${name}_reads.jf \
    > ${out}/results/GenomeSize/${name}_reads.histo

  ## run GenomeScope

  genomescope.R \
  -i ${out}/results/GenomeSize/${name}_reads.histo \
  -k 31 \
  -p 2 \
  -o ${out}/results/GenomeSize/${name}
""" > ${out}/shell/qsub_genomesize_${name}.sh

qsub  -W block=true  ${out}/shell/qsub_genomesize_${name}.sh

if [[ $SmudgePlot != "no" ]]
then
  echo """
    #!/bin/sh

    ## name of Job
    #PBS -N smudgeplot_${name}

    ## Redirect output stream to this file.
    #PBS -o ${out}/log/Smudgeplot_${name}_log.txt

    ## Stream Standard Output AND Standard Error to outputfile (see above)
    #PBS -j oe

    ## Select a maximum walltime of 2h
    #PBS -l walltime=48:00:00

    ## Select ${threads} cores and ${RAM}gb of RAM
    #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

    ## load all necessary software into environment
    module load Assembly/Jellyfish-2.3.0
    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate smudgeplot-0.2.4

    ## run SmudgePlot

    ## Go to pwd
    cd ${pwd}

    L=\$(smudgeplot.py cutoff ${out}/results/GenomeSize/${name}_reads.histo L)
    U=\$(smudgeplot.py cutoff ${out}/results/GenomeSize/${name}_reads.histo U)

    ## cheat if limits are COMPLETELY off
    if [ $((U-L)) -lt 100 ]
      then
        L=1
        U=100
    fi
    #echo $L $U

    jellyfish-linux dump \
    -c \
    -L \$L \
    -U \$U \
    ${out}/results/GenomeSize/${name}_reads.jf \
    | smudgeplot.py hetkmers \
    -o ${out}/results/GenomeSize/${name}_kmer_pairs

    smudgeplot.py plot ${out}/results/GenomeSize/${name}_kmer_pairs_coverages.tsv \
    -o ${out}/results/GenomeSize/${name} -k 31

    rm -f ${out}/data/kraken_${name}_*.fq

  """ > ${out}/shell/qsub_smudgeplot_${name}.sh

  printf "# "
  qsub  ${out}/shell/qsub_smudgeplot_${name}.sh
fi
