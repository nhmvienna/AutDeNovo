#!/bin/bash

## AutDeNovo -v 0.0.1 - 31/01/2022

## Author: Martin Kapun, largely based on the pipeline of TBG Loewe@Senkenberg/Frankfurt from Tilman Schell

###############################################
######### READ COMMANDLINE ARGUMENTS ##########
###############################################

for i in "$@"
do
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
    BUSCOdb=*)
      busco="${i#*=}"
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
Name=SomeFish \                 ## The sample name
OutputFolder=/media/output \    ## The full path to the output folder
Fwd=/media/seq/fwd.fq.gz \      ## The full path to the raw read forward FASTQ file
Rev=/media/seq/rev.fq.gz \      ## The full path to the raw read reverse FASTQ file
BuscoDB=vertebrata_odb10 \      ## The BUSCO database to be used; by default it is set to "vertebrata_odb10"; see here to pick the right one: https://busco.ezlab.org/busco_v4_data.html and here: https://busco.ezlab.org/list_of_lineages.html


Please see below, which parameter is missing:
*******************************
'''

if [ -z "$name" ]; then echo "## ${help}Name=Yeti_01 is missing: The name of the sample needs to be specified"; exit 1 ; fi
if [ -z "$out" ]; then echo "## ${help}OutputFolder=/media/output is missing: The full path to the output folder needs to be defined"; exit 2 ; fi
if [[ -z "$fwd" && !(-z "$rev" ) ]]; then echo "## ${help}Fwd=/media/seq/fwd.fq.gz is missing: The full path to the Illumina raw read forward FASTQ file needs to be defined"; exit 3; fi
if [[  -z "$rev" && !(-z "$fwd" ) ]]; then echo "## ${help}Rev=/media/seq/rev.fq.gz is missing: The full path to the Illumina raw read revese FASTQ file needs to be defined"; exit 4; fi
if [[ -z "$rev" && -z "$fwd" && -z "$ont" && -z "$pb" ]]; then echo "## ${help}No input defined"; exit 4; fi
if [ -z "$busco" ]; then busco="vertebrata_odb10"; fi

## Test which data are available
if [[ !(-z "$fwd") && -z "$ont" && -z "$pb" ]]; then data="ILL";
elif [[ !(-z "$fwd") && !(-z "$ont") && -z "$pb" ]]; then data="ILL_ONT";
elif [[ !(-z "$fwd") && !(-z "$pb") && -z "$ont" ]]; then data="ILL_PB";
elif [[ !(-z "$fwd") && !(-z "$pb") && !(-z "$ont") ]]; then data="ILL_ONT_PB";
elif [[ -z "$fwd" && !(-z "$pb") && !(-z "$ont") ]]; then data="ONT_PB";
elif [[ -z "$fwd" && -z "$pb" && !(-z "$ont") ]]; then data="ONT";
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
echo "# Copying data" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

## for Illumina data
if [[ !(-z $fwd) ]]
then
  mkdir -p ${out}/data/Illumina
  cp ${fwd} ${out}/data/Illumina/${name}_1.fq.gz &
  cp ${rev} ${out}/data/Illumina/${name}_2.fq.gz

  echo "## Illumina data copied" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh
fi

## for ONT data
if [[ !(-z $ont) ]]
then
  mkdir -p ${out}/data/ONT
  cat ${ont}/*fastq.gz > ${out}/data/ONT/${name}_ont.fq.gz &
  cp ${ont}/sequencing_summary.txt ${out}/data/ONT/${name}_sequencing_summary.txt

  echo "## ONT data copied" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh
fi

## for PacBio
if [[ !(-z $pb) ]]
then
  module load Tools/samtools-1.12

  mkdir -p ${out}/data/PB
  cp ${pb}/*fastq.gz | gzip >> ${out}/data/PB/${name}_pb.fq.gz

  echo "## PacBio data copied" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh
fi

printf "########################\n\n"\
| tee -a ${out}/shell/pipeline.sh

wait

###############################################
############# (1) QC and Trimming #############

echo "# Start raw QC" \
| tee -a ${out}/shell/pipeline.sh

## Illumina data
if [[ !(-z $fwd) ]]
then

  echo "## ... of Illumina data" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/fastqc.sh \
  $out \
  $name \
  $PWD \
  | tee -a ${out}/shell/pipeline.sh

fi

## ONT data
if [[ !(-z $ont) ]]
then

  echo "## ... of ONT data" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/nanoplot.sh \
  $out \
  $name \
  "ONT" \
  $PWD \
  | tee -a ${out}/shell/pipeline.sh

fi

## PacBio data
if [[ !(-z $pb) ]]
then

  echo "## ... of PacBio data" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/nanoplot.sh \
  $out \
  $name \
  "PB" \
  $PWD \
  | tee -a ${out}/shell/pipeline.sh

fi

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

## minimum PHRED basequality: 20
## minimum read length 75bp
## automatically detect adapter sequences

if [[ !(-z $fwd) ]]
then

  echo "# Start trimming" \
  | tee -a ${out}/shell/pipeline.sh
  date \
  | tee -a ${out}/shell/pipeline.sh

  sh FullPipeline/trim.sh \
  $out \
  $name \
  $PWD \
  | tee -a ${out}/shell/pipeline.sh

  printf "########################\n\n" \
  | tee -a ${out}/shell/pipeline.sh

fi

###############################################
########## (2) Detect contamination ###########

## detect human, bacterial and viral contamination in the trimmed reads, make a report and only retain the non-conmatinant reads for de-novo assembly

echo "# Start decontamination" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/kraken.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

##############################################
######## (3) Estimate Genome Size ############

# using Jellyfish to calculate kmer-coverage and genomoscope for formal analyses

echo "# Estimation of genomesize" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/genomesize.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh


###############################################
########### (4) Denovo assembly ###############

## denovo assembly with Spades

echo "## Starting denovo assembly" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/denovo.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

###############################################
########### (5) Assembly QC ###############

## (A) QUAST analysis

echo "# Starting assembly QC with Quast" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/quast.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

# (B) BUSCO analysis

echo "# Starting assembly QC with BUSCO" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/busco.sh \
$out \
$name \
$busco \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

## (C) Mapping reads

echo "# Mapping reads against reference" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/mapping.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

## (D) Blast genome against the nt database

echo "# BLASTing genome against the nt database" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/blast.sh \
$out \
$name \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

## (E) Summarize results with blobtools

echo "# Summarize with Blobtools" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh

sh FullPipeline/blobtools.sh \
$out \
$name \
$busco \
$data \
$PWD \
| tee -a ${out}/shell/pipeline.sh

printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

printf "# Anlayses done!!\n## Now copying results to output folder and writing commands for HTML output\n## check out ${out}/output/HTML_outputs.sh for more details" \
| tee -a ${out}/shell/pipeline.sh
date \
| tee -a ${out}/shell/pipeline.sh
printf "########################\n\n" \
| tee -a ${out}/shell/pipeline.sh

## gzip assembly FASTA
pigz ${out}/output/${name}_${data}.fa

printf """
# ############### HTML output #####################
# # run the following commands in terminal to open Firefox and view the HTML output files
# """ > ${out}/output/HTML_outputs.sh

if [[ !(-z $fwd) ]]
then

printf """
## Illumina Data - FASTQC of raw reads
firefox --new-tab ${out}/results/${name}_Illumina_fastqc/rawQC/${name}_1_fastqc.html
firefox --new-tab ${out}/results/${name}_Illumina_fastqc/rawQC/${name}_2_fastqc.html
""" >> ${out}/output/HTML_outputs.sh

cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.zip ${out}/output/${name}_1_raw_Illumina_fastqc.zip &
cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.zip ${out}/output/${name}_2_raw_Illumina_fastqc.zip

printf """
## Illumina Data - FASTQC after trimming
firefox --new-tab ${out}/data/Illumina/${name}_1_val_1_fastqc.html
firefox --new-tab ${out}/data/Illumina/${name}_2_val_2_fastqc.html
""" >> ${out}/output/HTML_outputs.sh

cp ${out}/data/Illumina/${name}_1_val_1_fastqc.zip ${out}/output/${name}_1_trimmed_Illumina_fastqc.zip &
cp ${out}/data/Illumina/${name}_2_val_2_fastqc.zip ${out}/output/${name}_2_trimmed_Illumina_fastqc.zip

## kraken
cp ${out}/results/kraken_reads/${name}_Illumina_filtered.report ${out}/output/${name}_Illumina_kraken.txt

fi

if [[ !(-z $ont) ]]
then

## Nanoplot
cp -r ${out}/results/rawQC/${name}_ONT_nanoplot ${out}/output/

##kraken
cp ${out}/results/kraken_reads/${name}_ONT_filtered.report ${out}/output/${name}_ONT_kraken.txt

fi

if [[ !(-z $pb) ]]
then

## Nanoplot
cp -r ${out}/results/rawQC/${name}_PB_nanoplot ${out}/output/

##kraken
cp ${out}/results/kraken_reads/${name}_PB_filtered.report ${out}/output/${name}_PB_kraken.txt

fi

printf """
## run Pavian to explore the Kraken output(s)
docker run -p 5000:80 florianbw/pavian &
firefox --new-tab http://127.0.0.1:5000
""" >> ${out}/output/HTML_outputs.sh

## genomesize
cp -r ${out}/results/GenomeSize/${name} ${out}/output/${name}_genomesize
cp ${out}/results/GenomeSize/${name}_smudgeplot.png ${out}/output/${name}_genomesize

##QUAST
cp ${out}/results/AssemblyQC/Quast/report.pdf ${out}/output/${name}_quast.pdf

#blobtools
printf """
## QUAST
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html
""" >> ${out}/output/HTML_outputs.sh

printf """
## Blobtools
source /opt/venv/blobtools-3.0.0/bin/activate

blobtools view \
  --out ${out}/results/AssemblyQC/blobtools/out \
  --interactive \
  ${out}/results/AssemblyQC/blobtools \

### now copy the URL that is printed in the commandline and paste it in Firefox

""" >> ${out}/output/HTML_outputs.sh
