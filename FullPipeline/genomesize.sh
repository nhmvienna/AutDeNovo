### estimate genome size

out=$1
name=$2

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

  ## in a QSUB bash script add the following lines to activate
  source /opt/anaconda3/etc/profile.d/conda.sh
  conda activate smudgeplot-0.2.4

  ## unzip files

  gunzip -c ${out}/data/kraken_${name}_1.fq.gz > ${out}/data/kraken_${name}_1.fq &
  gunzip -c ${out}/data/kraken_${name}_2.fq.gz > ${out}/data/kraken_${name}_2.fq

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
    ${out}/data/kraken_${name}_1.fq \
    ${out}/data/kraken_${name}_2.fq


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

  ## run SmudgePlot

  L=$(smudgeplot.py cutoff ${out}/results/GenomeSize/${name}_reads.histo L)
  U=$(smudgeplot.py cutoff ${out}/results/GenomeSize/${name}_reads.histo U)

  #echo $L $U

  jellyfish-linux dump \
  -c \
  -L $L \
  -U $U \
  ${out}/results/GenomeSize/${name}_reads.jf \
  | smudgeplot.py hetkmers \
  -o ${out}/results/GenomeSize/${name}_kmer_pairs

  smudgeplot.py plot ${out}/results/GenomeSize/${name}_kmer_pairs_coverages.tsv \
  -o ${out}/results/GenomeSize/${name} -k 31

  rm -f ${out}/data/kraken_${name}_*.fq

""" > ${out}/shell/qsub_genomesize_${name}.sh

qsub  -W block=true  ${out}/shell/qsub_genomesize_${name}.sh
