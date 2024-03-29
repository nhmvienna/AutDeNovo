#!/bin/bash

## AutDeNovo -v 0.2.3 - 16/01/2023

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

~/AutDeNovo.sh \                ## The script name
Name=SomeName \                 ## The sample name
OutputFolder=/media/output \    ## The full path to the output folder
Fwd=/media/seq/fwd.fq.gz \      ## The full path to the raw read forward FASTQ file
Rev=/media/seq/rev.fq.gz \      ## The full path to the raw read reverse FASTQ file
ONT=Test/subset/ONT \           ## The full path to a folder containing reads generated with ONT
PB=Test/subset/PacBio \         ## The full path to a folder containing reads generated with PacBio
threads=10 \                    ## The total number of cores needed [optional; default=10]
RAM=20 \                        ## The total amount of RAM [in GB] reserved for all analyses except the denovo assembly [optional; default=20]
RAMAssembly=20 \                ## The total amount of RAM [in GB] reserved for the denovo assembly [optional; default=20]
Trimmer=TrimGalore \            ## The Software used for trimming Illumina data; choose one option from (Atria, FastP, Trimgalore and UrQt) [optional; default=TrimGalore]
MinReadLen=85 \                 ## The minimmum read length accepted after trimming, otherwise the read pair gets discarded [optional; default=85]
BaseQuality=20 \                ## The minimmum PHRED-scaled base quality for trimming [optional; default=20]
decont=no \                     ## optional decontamination with KRAKEN [default=no]
SmudgePlot=no \                 ## optional estimation of ploidy with SmudgePlot [default=no]
BuscoDB=vertebrata_odb10 \      ## The BUSCO database to be used; by default it is set to "vertebrata_odb10"; see here to pick the right one: https://busco.ezlab.org/busco_v4_data.html and here: https://busco.ezlab.org/list_of_lineages.html


Please see below, which parameter is missing:
*******************************
'''

array=("atria" "trimgalore" "urqt" "fastp")

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
if [ -z "$Trimmer" ]; then Trimmer="Trimgalore"; fi
if [[ ! " ${array[*]} " =~ " ${Trimmer,,} " ]]; then
  echo "## ${help}No correct Trimmer for Illumina data assigned; choose from: Atria, FastP, UrQt or Trimgalore "
  exit 4
fi
if [ -z "$busco" ]; then busco="vertebrata_odb10"; fi
if [ -z "$decont" ]; then decont="no"; fi
if [ -z "$threads" ]; then threads="10"; fi
if [ -z "$RAM" ]; then RAM="20"; fi
if [ -z "$RAMAssembly" ]; then RAMAssembly="20"; fi
if [ -z "$SmudgePlot" ]; then SmudgePlot="no"; fi
if [ -z "$racon" ]; then racon="no"; fi
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
BASEDIR=$(dirname $0)
cd $BASEDIR

## (1) make folder structure
mkdir -p ${out}/data
mkdir ${out}/results
mkdir ${out}/shell
mkdir ${out}/log
mkdir ${out}/output

## (1) make copy of original reads
printf "# Copying data\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

## for Illumina data
if [[ !(-z $fwd) ]]; then
  mkdir -p ${out}/data/Illumina
  cp ${fwd} ${out}/data/Illumina/${name}_1.fq.gz &
  cp ${rev} ${out}/data/Illumina/${name}_2.fq.gz

  printf "## Illumina data copied\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh
fi

## for ONT data
if [[ !(-z $ont) ]]; then
  mkdir -p ${out}/data/ONT

  if [[ ${ont} != *q.gz ]]; then
    cat ${ont}/*q.gz >${out}/data/ONT/${name}_ont.fq.gz &
    cp ${ont}/sequencing_summary.txt ${out}/data/ONT/${name}_sequencing_summary.txt
  else
    cat ${ont} >${out}/data/ONT/${name}_ont.fq.gz

  fi
  printf "## ONT data copied\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh
fi

## for PacBio
if [[ !(-z $pb) ]]; then
  module load Tools/samtools-1.12

  mkdir -p ${out}/data/PB

  if [[ ${pb} == */ ]]; then
    cat ${pb}/*q.gz >>${out}/data/PB/${name}_pb.fq.gz
  else
    cat ${pb} >${out}/data/PB/${name}_pb.fq.gz
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

  sh FullPipeline/fastqc.sh \
    $out \
    $name \
    $PWD \
    $threads \
    $RAM |
    tee -a ${out}/shell/pipeline.sh

fi

## ONT data
if [[ !(-z $ont) ]]; then

  printf "## ... of ONT data\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/nanoplot.sh \
    $out \
    $name \
    "ONT" \
    $PWD \
    $threads \
    $RAM |
    tee -a ${out}/shell/pipeline.sh

fi

## PacBio data
if [[ !(-z $pb) ]]; then

  printf "## ... of PacBio data\n# " |
    tee -a ${out}/shell/pipeline.sh
  date |
    tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/nanoplot.sh \
    $out \
    $name \
    "PB" \
    $PWD \
    $threads \
    $RAM |
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

  sh FullPipeline/trim_${Trimmer,,}.sh \
    $out \
    $name \
    $PWD \
    $threads \
    $RAM \
    $BaseQuality \
    $MinReadLen |
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

  sh FullPipeline/kraken.sh \
    $out \
    $name \
    $data \
    $PWD \
    $threads \
    $RAM |
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

sh FullPipeline/genomesize.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threads \
  $RAM \
  $RAMAssembly \
  $SmudgePlot |
  tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

###############################################
########### (4) Denovo assembly ###############

## denovo assembly with Spades

printf "## Starting denovo assembly\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

sh FullPipeline/denovo.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threads \
  $RAMAssembly |
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

  sh FullPipeline/racon.sh \
    $out \
    $name \
    $data \
    $PWD \
    $threads \
    $RAMAssembly \
    $racon \
    $decont |
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

sh FullPipeline/quast.sh \
  $out \
  $name \
  $data \
  $PWD \
  $threads \
  $RAM |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

# (B) BUSCO analysis

printf "# Starting assembly QC with BUSCO\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

sh FullPipeline/busco.sh \
  $out \
  $name \
  $busco \
  $data \
  $PWD \
  $threads \
  $RAM |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (C) Mapping reads

printf "# Mapping reads against reference\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

sh FullPipeline/mapping.sh \
  $out \
  $name \
  $data \
  $decont \
  $PWD \
  $threads \
  $RAM |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (D) Blast genome against the nt database

printf "# BLASTing genome against the nt database\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

sh FullPipeline/blast.sh \
  $out \
  $name \
  $data \
  $PWD \
  $threads \
  $RAM |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## (E) Summarize results with blobtools

printf "# Summarize with Blobtools\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh

sh FullPipeline/blobtools.sh \
  $out \
  $name \
  $busco \
  $data \
  $PWD \
  $threads \
  $RAM |
  tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

printf "# Anlayses done!!\n# Now copying results to output folder and writing commands for HTML output\n# check ${out}/output/${name}_HTML_outputs.sh for more details\n# " |
  tee -a ${out}/shell/pipeline.sh
date |
  tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" |
  tee -a ${out}/shell/pipeline.sh

## remove index files and gzip assembly FASTA
rm -f ${out}/output/${name}_${data}.fa.*
pigz ${out}/output/${name}_${data}.fa

printf """
# ############### HTML output #####################
# # run the following commands in terminal to open Firefox and view the HTML output files
# """ >${out}/output/${name}_HTML_outputs.sh

if [[ !(-z $fwd) ]]; then

  printf """
## Illumina Data - FASTQC of raw reads
firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.html
firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.html
""" >>${out}/output/${name}_HTML_outputs.sh

  cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.zip ${out}/output/${name}_1_raw_Illumina_fastqc.zip &
  cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.zip ${out}/output/${name}_2_raw_Illumina_fastqc.zip

  printf """
## Illumina Data - FASTQC after trimming
firefox --new-tab ${out}/data/Illumina/${name}_1_val_1_fastqc.html
firefox --new-tab ${out}/data/Illumina/${name}_2_val_2_fastqc.html
""" >>${out}/output/${name}_HTML_outputs.sh

  cp ${out}/data/Illumina/${name}_1_val_1_fastqc.zip ${out}/output/${name}_1_trimmed_Illumina_fastqc.zip &
  cp ${out}/data/Illumina/${name}_2_val_2_fastqc.zip ${out}/output/${name}_2_trimmed_Illumina_fastqc.zip

  if [[ $decont != "no" ]]; then
    ## kraken
    cp ${out}/results/kraken_reads/${name}_Illumina_filtered.report ${out}/output/${name}_Illumina_kraken.txt
  fi

fi

if [[ !(-z $ont) ]]; then

  ## Nanoplot
  cp -r ${out}/results/rawQC/${name}_ONT_nanoplot ${out}/output/

  if [[ $decont != "no" ]]; then
    ##kraken
    cp ${out}/results/kraken_reads/${name}_ONT_filtered.report ${out}/output/${name}_ONT_kraken.txt
  fi

fi

if [[ !(-z $pb) ]]; then

  ## Nanoplot
  cp -r ${out}/results/rawQC/${name}_PB_nanoplot ${out}/output/

  if [[ $decont != "no" ]]; then
    ##kraken
    cp ${out}/results/kraken_reads/${name}_PB_filtered.report ${out}/output/${name}_PB_kraken.txt
  fi

fi

## genomesize
cp -r ${out}/results/GenomeSize/${name} ${out}/output/${name}_genomesize
#cp ${out}/results/GenomeSize/${name}_smudgeplot.png ${out}/output/${name}_genomesize

##QUAST
#cp ${out}/results/AssemblyQC/Quast/report.pdf ${out}/output/${name}_quast.pdf

##BLAST
cp ${out}/results/BLAST/blastn_${name}.txt ${out}/output/${name}_blastn.txt
pigz ${out}/output/${name}_blastn.txt

## BUSCO
cp -r ${out}/results/AssemblyQC/Busco/${name}/run_${busco}/busco_sequences ${out}/output/

#blobtools
printf """
## QUAST
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html
""" >>${out}/output/${name}_HTML_outputs.sh

printf """
## Blobtools
source /opt/venv/blobtools-3.0.0/bin/activate

blobtools view \
  --out ${out}/results/AssemblyQC/blobtools/out \
  --interactive \
  ${out}/results/AssemblyQC/blobtools \

### now copy the URL that is printed in the commandline and paste it in Firefox

""" >>${out}/output/${name}_HTML_outputs.sh
