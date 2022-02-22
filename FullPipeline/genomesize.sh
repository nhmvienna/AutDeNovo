### estimate genome size

out=$1
name=$2
data=$3
pwd=$4

echo "sh FullPipeline/genomesize.sh $1 $2 $3 $4"

#############################

mkdir ${out}/results/GenomeSize

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

  ## Select a maximum of 100 cores and 200gb of RAM
  #PBS -l select=1:ncpus=100:mem=500gb

  ## load all necessary software into environment
  module load Assembly/Jellyfish-2.3.0
  module load Assembly/genomescope-2.0

  ## Go to pwd
  cd ${pwd}

  if [[ ( $data == 'ILL' ) || ( $data == 'ILL_ONT' ) || ( $data == 'ILL_PB' ) || ( $data == 'ILL_ONT_PB' ) ]]
  then

    ## unzip files

    gunzip -c ${out}/data/Illumina/kraken_illumina_${name}_1.fq.gz > ${out}/data/Illumina/kraken_illumina_${name}_1.fq &
    gunzip -c ${out}/data/Illumina/kraken_illumina_${name}_2.fq.gz > ${out}/data/Illumina/kraken_illumina_${name}_2.fq

    wait

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish-linux count \
      -C \
      -m 31 \
      -s 200000000000 \
      -t 100 \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/Illumina/kraken_illumina_${name}_1.fq \
      ${out}/data/Illumina/kraken_illumina_${name}_2.fq

    rm -f ${out}/data/Illumina/kraken_illumina_${name}_*.fq

  fi

  if [[ ( $data == 'ONT' ) || ( $data == 'ONT_PB' ) ]]
  then

    ## unzip ONT file

    gunzip -c ${out}/data/ONT/kraken_ont_${name}.fq.gz > ${out}/data/ONT/kraken_ont_${name}.fq

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish-linux count \
      -C \
      -m 31 \
      -s 200000000000 \
      -t 100 \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/ONT/kraken_ont_${name}.fq

    rm -f  ${out}/data/ONT/kraken_ont_${name}.fq

  fi

  if [[ ( $data == 'PB' ) ]]
  then

    ## unzip file

    gunzip -c ${out}/data/PB/kraken_pb_${name}.fq.gz > ${out}/data/PB/kraken_pb_${name}.fq

    ## run Jellyfish

    ## parameters
    # -C canononical; count both strands
    # -m 31 Length of mers
    # -s initial hash size
    jellyfish-linux count \
      -C \
      -m 31 \
      -s 200000000000 \
      -t 100 \
      -F 2 \
      -o ${out}/results/GenomeSize/${name}_reads.jf \
      ${out}/data/PB/kraken_pb_${name}.fq

    rm -f  ${out}/data/PB/kraken_pb_${name}.fq

  fi

  jellyfish-linux histo \
    -t 100 \
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

  ## Select a maximum of 100 cores and 200gb of RAM
  #PBS -l select=1:ncpus=1:mem=500gb

  ## run SmudgePlot

  source /opt/anaconda3/etc/profile.d/conda.sh
  conda activate smudgeplot-0.2.4

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

qsub  ${out}/shell/qsub_smudgeplot_${name}.sh
