#!/usr/bin/env bash

## AutDeNovo -v 0.2.0 - 30/05/2022

## Author: Martin Kapun, based on the pipeline of TBG Loewe@Senkenberg/Frankfurt from Tilman Schell

###############################################
######### READ COMMANDLINE ARGUMENTS ##########
###############################################

for i in "$@"; do
  case $i in
  OutputFolder=*)
    out="${i#*=}"
    ;;
  Name=*)
    name="${i#*=}"
    ;;
  Fwd=*)
    fwd="${i#*=}"
    ;;
  Rev=*)
    rev="${i#*=}"
    ;;
  ONT=*)
    ont="${i#*=}"
    ;;
  PB=*)
    pb="${i#*=}"
    ;;
  BuscoDB=*)
    busco="${i#*=}"
    ;;
  Decont=*)
    decont="${i#*=}"
    ;;
  threads=*)
    threads="${i#*=}"
    ;;
  threadsAssembly=*)
    threadsAssembly="${i#*=}"
    ;;
  MinReadLen=*)
    MinReadLen="${i#*=}"
    ;;
  BaseQuality=*)
    BaseQuality="${i#*=}"
    ;;
  RAMAssembly=*)
    RAMAssembly="${i#*=}"
    ;;
  RAM=*)
    RAM="${i#*=}"
    ;;
  SmudgePlot=*)
    SmudgePlot="${i#*=}"
    ;;
  Trimmer=*)
    Trimmer="${i#*=}"
    ;;
  Racon=*)
    racon="${i#*=}"
    ;;
  OpenPBS=*)
    openpbs="${i#*=}"
    ;;
  BLASTdb=*)
    BLASTdb="${i#*=}"
    ;;
  Taxdump=*)
    taxdump="${i#*=}"
    ;;
  PrintOnly=*)
    PrintOnly="${i#*=}"
    ;;
  *)
    # unknown option
    ;;
  esac
done

###############################################
######## TEST IF ALL PARAMETERS ARE SET #######
###############################################

help='''
********************************
************ HELP **************
********************************


AutDeNovo v. 0.02 - 23/02/2022

A typcial command line looks like this:

~/AutDeNovo.sh \                                  ## The path to the shell script
Name=SomeName \                                   ## The sample name
OutputFolder=/media/output \                      ## The full path to the output folder
Fwd=/media/seq/fwd.fq.gz \                        ## The full path to the raw read forward FASTQ file
Rev=/media/seq/rev.fq.gz \                        ## The full path to the raw read reverse FASTQ file
ONT=Test/subset/ONT \                             ## The full path to a folder containing reads generated with ONT
PB=Test/subset/PacBio \                           ## The full path to a folder containing reads generated with PacBio
threads=10 \                                      ## The total number of cores used [optional; default=10]
threadsAssembly=10 \                              ## The total number of cores used for denovo assembly [optional; default=8]
RAM=20 \                                          ## The total amount of RAM [in GB] reserved for all analyses except the denovo assembly [optional; default=20]
RAMAssembly=20 \                                  ## The total amount of RAM [in GB] reserved for the denovo assembly [optional; default=20]
Trimmer=trimgalore \                              ## The Software used for trimming Illumina data; choose one option from (atria, fastp and trimgalore) [optional; default=trimgalore]
MinReadLen=85 \                                   ## The minimmum read length accepted after trimming, otherwise the read pair gets discarded [optional; default=85]
BaseQuality=20 \                                  ## The minimmum PHRED-scaled base quality for trimming [optional; default=20]
decont=no \                                       ## optional decontamination with KRAKEN [optional; default=no]
Racon=4 \                                         ## optional rounds of polishing with Racon [optional; default=no]
BuscoDB=vertebrata_odb10 \                        ## The BUSCO database to be used; by default it is set to "vertebrata_odb10"; see here to pick the right one: https://busco.ezlab.org/busco_v4_data.html and here: https://busco.ezlab.org/list_of_lineages.html
BLASTdb=/media/scratch/NCBI_nt_DB_210714/nt \     ## The full path to the BLAST nt database, see here: https://blast.ncbi.nlm.nih.gov/doc/blast-help/downloadblastdata.html#id6
Taxdump=/media/scratch/NCBI_taxdump/ \            ## The full path to the Taxdump database, see here: https://blast.ncbi.nlm.nih.gov/doc/blast-help/downloadblastdata.html#id6
OpenPBS=yes \                                     ## Whether to use the OpenPBS job managment software (needs to be preinstalled) or not [optional; default=no]

Please see below, which parameter is missing:
*******************************
'''
### print error message if an obligatory parameter is not set

array=("atria" "trimgalore" "fastp")

if [ -z "$name" ]; then
  echo "## ${help}'Name' is missing: The name of the sample needs to be specified"
  exit 1
fi
if [ -z "$out" ]; then
  echo "## ${help}'OutputFolder' is missing: The full path to the output folder needs to be defined"
  exit 2
fi
if [[ -z "$fwd" && !(-z "$rev" ) ]]; then
  echo "## ${help}Fwd read is missing: The full path to the Illumina raw read forward FASTQ file needs to be defined"
  exit 3
fi
if [[ -z "$rev" && !(-z "$fwd" ) ]]; then
  echo "## ${help}Rev read: The full path to the Illumina raw read revese FASTQ file needs to be defined"
  exit 4
fi
if [[ -z "$rev" && -z "$fwd" && -z "$ont" && -z "$pb" ]]; then
  echo "## ${help}No input defined"
  exit 4
fi
if [[ -z "$rev" && -z "$fwd" && -z "$ont" && -z "$pb" ]]; then
  echo "## ${help}No input defined"
  exit 4
fi
if [ -z "$Trimmer" ]; then Trimmer="trimgalore"; fi
if [[ ! " ${array[*]} " =~ " ${Trimmer} " ]]; then
  echo "## ${help}No correct Trimmer for Illumina data assigned; choose from: Atria, FastP, UrQt or Trimgalore "
  exit 4
fi
if [ -z "$BLASTdb" ]; then
  echo "## ${help}'BLASTdb' is missing: The full path to the BLAST nt database needs to be provided"
  exit 2
fi

## set default parameters if necessary
if [ -z "$busco" ]; then busco="vertebrata_odb10"; fi
if [ -z "$decont" ]; then decont="no"; fi
if [ -z "$threads" ]; then threads="10"; fi
if [ -z "$threadsAssembly" ]; then threadsAssembly="8"; fi
if [ -z "$RAM" ]; then RAM="20"; fi
if [ -z "$RAMAssembly" ]; then RAMAssembly="20"; fi
if [ -z "$SmudgePlot" ]; then SmudgePlot="no"; fi
if [ -z "$openpbs" ]; then openpbs="no"; fi
if [ -z "$PrintOnly" ]; then PrintOnly="no"; fi
if [ -z "$MinReadLen" ]; then MinReadLen=85; fi
if [ -z "$BaseQuality" ]; then BaseQuality=20; fi

## Test which data are available
if [[ !(-z "$fwd") && -z "$ont" && -z "$pb" ]]; then
  data="ILL"
elif [[ !(-z "$fwd") && !(-z "$ont") && -z "$pb" ]]; then
  data="ILL_ONT"
elif [[ !(-z "$fwd") && !(-z "$pb") && -z "$ont" ]]; then
  data="ILL_PB"
elif [[ !(-z "$fwd") && !(-z "$pb") && !(-z "$ont") ]]; then
  data="ILL_ONT_PB"
elif [[ -z "$fwd" && !(-z "$pb") && !(-z "$ont") ]]; then
  data="ONT_PB"
elif [[ -z "$fwd" && -z "$pb" && !(-z "$ont") ]]; then
  data="ONT"
elif [[ -z "$fwd" && -z "$ont" && !(-z "$pb") ]]; then data="PB"; fi

echo "## Dataset consists of "$data

###############################################
######## RUN ALL STEPS IN THE PIPELINE ########
###############################################

## change to home directory of scripts
BASEDIR=$(realpath $(dirname $0))
cd $BASEDIR

## (0) Set working directory
mkdir -p ${out}/shell
printf "# Change to working directory\ncd ${BASEDIR}\n\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

## get path to folder where conda is installed
Conda=$CONDA_PREFIX

eval "$(conda shell.bash hook)"

## (1) make folder structure

mkdir ${out}/data
mkdir ${out}/results
mkdir ${out}/log
mkdir ${out}/output

## (1) make copy of original reads
printf "# Copying data\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

## for Illumina data
if [[ !(-z $fwd) ]]; then
  if [[ $PrintOnly == "no" ]]; then
    mkdir -p ${out}/data/Illumina
    cp ${fwd} ${out}/data/Illumina/${name}_1.fq.gz &
    cp ${rev} ${out}/data/Illumina/${name}_2.fq.gz
  fi

  printf "## Illumina data copied\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh
fi

## for ONT data
if [[ !(-z $ont) ]]; then
  if [[ $PrintOnly == "no" ]]; then
    mkdir -p ${out}/data/ONT

    if [[ ${ont} != *q.gz ]]; then
      cat ${ont}/*q.gz >${out}/data/ONT/${name}_ont.fq.gz &
      cp ${ont}/sequencing_summary.txt ${out}/data/ONT/${name}_sequencing_summary.txt
    else
      cat ${ont} >${out}/data/ONT/${name}_ont.fq.gz
    fi
  fi

  printf "## ONT data copied\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh
fi

## for PacBio
if [[ !(-z $pb) ]]; then
  if [[ $PrintOnly == "no" ]]; then
    conda activate envs/bwa

    mkdir -p ${out}/data/PB

    if [[ ${pb} != *q.gz ]]; then
      cat ${pb}/*q.gz >>${out}/data/PB/${name}_pb.fq.gz
    else
      cat ${pb} >${out}/data/PB/${name}_pb.fq.gz
    fi
  fi
  printf "## PacBio data copied\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh
fi

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

wait

###############################################
############# (1) QC and Trimming #############

printf "# Start raw QC\n" |
  tee -a ${out}/shell/pipeline.sh

## Illumina data
if [[ !(-z $fwd) ]]; then

  printf "## ... of Illumina data\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/fastqc.sh \
    $out \
    $name \
    $PWD \
    $threads \
    $RAM \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh

fi

## ONT data
if [[ !(-z $ont) ]]; then

  printf "## ... of ONT data\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/nanoplot.sh \
    $out \
    $name \
    "ONT" \
    $PWD \
    $threads \
    $RAM \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh

fi

## PacBio data
if [[ !(-z $pb) ]]; then

  printf "## ... of PacBio data\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/nanoplot.sh \
    $out \
    $name \
    "PB" \
    $PWD \
    $threads \
    $RAM \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh

fi

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## minimum PHRED basequality: 20
## minimum read length 75bp
## automatically detect adapter sequences

if [[ !(-z $fwd) ]]; then

  printf "# Start trimming\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/trim_${Trimmer}.sh \
    $out \
    $name \
    $PWD \
    $threads \
    $RAM \
    $BaseQuality \
    $MinReadLen \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh

  printf "########################\n\n" |
    tee -a ${out}/shell/pipeline.sh

fi

if [[ $decont != "no" ]]; then

  ###############################################
  ########## (2) Detect contamination ###########

  ## detect human, bacterial and viral contamination in the trimmed reads, make a report and only retain the non-conmatinant reads for de-novo assembly

  printf "# Start decontamination\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/kraken.sh \
    $out \
    $name \
    $data \
    $PWD \
    $threads \
    $RAM \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh
  printf "########################\n\n" |
    tee -a ${out}/shell/pipeline.sh

fi

##############################################
######## (3) Estimate Genome Size ############

# using Jellyfish to calculate kmer-coverage and genomoscope for formal analyses

printf "# Estimation of genomesize\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/genomesize.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threads \
  $RAM \
  $RAMAssembly \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

###############################################
########### (4) Denovo assembly ###############

## denovo assembly with Spades or Flye

printf "## Starting denovo assembly\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/denovo.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threadsAssembly \
  $RAMAssembly \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

if [[ $racon != "no" ]]; then

  ###############################################
  ########### (5) Polishing with Racon ###############

  ## denovo assembly with Spades

  printf "## Starting polishing with Racon\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  bash FullPipeline_exp/racon.sh \
    $out \
    $name \
    $data \
    $PWD \
    $threads \
    $RAMAssembly \
    $racon \
    $decont \
    $openpbs \
    $PrintOnly |
    tee -a ${out}/shell/pipeline.sh
  printf "########################\n\n" |
    tee -a ${out}/shell/pipeline.sh

fi

###############################################
########### (6) Assembly QC ###############

## (A) QUAST analysis

printf "# Starting assembly QC with Quast\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/quast.sh \
  $out \
  $name \
  $data \
  $PWD \
  $threads \
  $RAM \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

# (B) BUSCO analysis

printf "# Starting assembly QC with BUSCO\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/busco.sh \
  $out \
  $name \
  $busco \
  $data \
  $PWD \
  $threads \
  $RAM \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (C) Mapping reads

printf "# Mapping reads against reference\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/mapping.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threads \
  $RAM \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (D) BLAST genome against the nt database

printf "# BLASTing genome against the nt database\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/blast.sh \
  $out \
  $name \
  $data \
  $PWD \
  $threads \
  $RAM \
  $BLASTdb \
  $openpbs \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (E) Summarize results with blobtools

printf "# Summarize with Blobtools\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

bash FullPipeline_exp/blobtools.sh \
  $out \
  $name \
  $busco \
  $data \
  $PWD \
  $threads \
  $RAM \
  $openpbs \
  $taxdump \
  $PrintOnly |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

printf "# Anlayses done!!\n# Now copying results to output folder and writing commands for HTML output\n# check ${out}/output/${name}_HTML_outputs.sh for more details\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

if [[ $PrintOnly == "no" ]]; then
  ## remove index files and gzip assembly FASTA

  conda activate envs/pigz

  rm -f ${out}/output/${name}_${data}.fa.*
  pigz -p ${threads} ${out}/output/${name}_${data}.fa
fi
## Write commands to shell output
printf """
# ############### HTML output #####################
# # run the following commands in terminal to open Firefox and view the HTML output files
# """ >${out}/output/${name}_HTML_outputs.sh

if [[ !(-z $fwd) ]]; then
  ## Write commands to shell output
  printf """
## Illumina Data - FASTQC of raw reads
firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.html
firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.html
""" >>${out}/output/${name}_HTML_outputs.sh

  if [[ $PrintOnly == "no" ]]; then
    cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.zip ${out}/output/${name}_1_raw_Illumina_fastqc.zip &
    cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.zip ${out}/output/${name}_2_raw_Illumina_fastqc.zip
  fi
  printf """
## Illumina Data - FASTQC after trimming
firefox --new-tab ${out}/data/Illumina/${name}_1_val_1_fastqc.html
firefox --new-tab ${out}/data/Illumina/${name}_2_val_2_fastqc.html
""" >>${out}/output/${name}_HTML_outputs.sh

  if [[ $PrintOnly == "no" ]]; then
    if [[ ${Trimmer} == "Trimgalore" ]]; then
      cp ${out}/data/Illumina/${name}_1_val_1_fastqc.zip ${out}/output/${name}_1_trimmed_Illumina_fastqc.zip &
      cp ${out}/data/Illumina/${name}_2_val_2_fastqc.zip ${out}/output/${name}_2_trimmed_Illumina_fastqc.zip
    fi

    if [[ $decont != "no" ]]; then
      ## Kraken
      cp ${out}/results/kraken_reads/${name}_Illumina_filtered.report ${out}/output/${name}_Illumina_kraken.txt
    fi

  fi

  if [[ !(-z $ont) ]]; then

    ## Nanoplot
    cp -r ${out}/results/rawQC/${name}_ONT_nanoplot ${out}/output/

    if [[ $decont != "no" ]]; then
      ## Kraken
      cp ${out}/results/kraken_reads/${name}_ONT_filtered.report ${out}/output/${name}_ONT_kraken.txt
    fi

  fi

  if [[ !(-z $pb) ]]; then

    ## Nanoplot
    cp -r ${out}/results/rawQC/${name}_PB_nanoplot ${out}/output/

    if [[ $decont != "no" ]]; then
      ## Kraken
      cp ${out}/results/kraken_reads/${name}_PB_filtered.report ${out}/output/${name}_PB_kraken.txt
    fi

  fi

  ## genomesize
  cp -r ${out}/results/GenomeSize/${name} ${out}/output/${name}_genomesize

  ## QUAST
  cp ${out}/results/AssemblyQC/Quast/report.pdf ${out}/output/${name}_quast.pdf

  ## BLAST
  cp ${out}/results/BLAST/blastn_${name}.txt ${out}/output/${name}_blastn.txt
  pigz -p ${threads} ${out}/output/${name}_blastn.txt

  ## BUSCO
  cp -r ${out}/results/AssemblyQC/Busco/${name}/run_${busco}/busco_sequences ${out}/output/
fi
## Write commands to shell output
printf """
## QUAST
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html
""" >>${out}/output/${name}_HTML_outputs.sh

printf """
## Blobtools

conda activate ${BASEDIR}/envs/blobtools

blobtools view \
  --out ${out}/results/AssemblyQC/blobtools/out \
  --interactive \
  ${out}/results/AssemblyQC/blobtools \

### now copy the URL that is printed in the commandline and paste it in Firefox

""" >>${out}/output/${name}_HTML_outputs.sh
