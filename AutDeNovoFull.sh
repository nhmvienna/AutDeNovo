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


AutDeNovo v. 0.01 - 31/01/2022

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

if [ -z "$name" ]; then echo "${help}Name=Yeti_01 is missing: The name of the sample needs to be specified"; exit 1 ; fi
if [ -z "$out" ]; then echo "${help}OutputFolder=/media/output is missing: The full path to the output folder needs to be defined"; exit 2 ; fi
if [[ -z "$fwd" && !(-z "$rev" ) ]]; then echo "${help}Fwd=/media/seq/fwd.fq.gz is missing: The full path to the Illumina raw read forward FASTQ file needs to be defined"; exit 3; fi
if [[  -z "$rev" && !(-z "$fwd" ) ]]; then echo "${help}Rev=/media/seq/rev.fq.gz is missing: The full path to the Illumina raw read revese FASTQ file needs to be defined"; exit 4; fi
if [[ -z "$rev" && -z "$fwd" && -z "$ont" && -z "$pb" ]]; then echo "${help}No input defined"; exit 4; fi
if [ -z "$busco" ]; then busco="vertebrata_odb10"; fi

## Test which data are available
if [[ !(-z "$fwd") && -z "$ont" && -z "$pb" ]]; then data="ILL";
elif [[ !(-z "$fwd") && !(-z "$ont") && -z "$pb" ]]; then data="ILL_ONT";
elif [[ !(-z "$fwd") && !(-z "$pb") && -z "$ont" ]]; then data="ILL_PB";
elif [[ !(-z "$fwd") && !(-z "$pb") && !(-z "$ont") ]]; then data="ILL_ONT_PB";
elif [[ -z "$fwd" && !(-z "$pb") && !(-z "$ont") ]]; then data="ONT_PB";
elif [[ -z "$fwd" && -z "$pb" && !(-z "$ont") ]]; then data="ONT";
elif [[ -z "$fwd" && -z "$ont" && !(-z "$pb") ]]; then data="PB"; fi

echo "Dataset consists of "$data

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
echo "Copying data"
date

## for Illumina data
if [[ !(-z $fwd) ]]
then
  mkdir -p ${out}/data/Illumina
  cp ${fwd} ${out}/data/Illumina/${name}_1.fq.gz &
  cp ${rev} ${out}/data/Illumina/${name}_2.fq.gz

  echo "Illumina data copied"
  date
fi

## for ONT data
if [[ !(-z $ont) ]]
then
  mkdir -p ${out}/data/ONT
  cat ${ont}/*fastq.gz > ${out}/data/ONT/${name}_ont.fq.gz &
  cp ${ont}/sequencing_summary.txt ${out}/data/ONT/${name}_sequencing_summary.txt

  echo "ONT data copied"
  date
fi

## for PacBio
if [[ !(-z $pb) ]]
then
  module load Tools/samtools-1.12

  mkdir -p ${out}/data/PB
  samtools view ${pb}/*subreads.bam | awk '{print "@"$1"\n"$10"\n+\n"$11}' | gzip > ${out}/data/PB/${name}_pb.fq.gz

  echo "PacBio data copied"
  date
fi

printf "########################\n\n"

wait

###############################################
############# (1) QC and Trimming #############

echo "Start raw QC"

## Illumina data
if [[ !(-z $fwd) ]]
then

  echo "of Illumina data"
  date

  sh FullPipeline/fastqc.sh \
  $out \
  $name \
  $PWD

fi

## ONT data
if [[ !(-z $ont) ]]
then

  echo "of ONT data"
  date

  sh FullPipeline/nanoplot.sh \
  $out \
  $name \
  "ONT" \
  $PWD

fi

## PacBio data
if [[ !(-z $pb) ]]
then

  echo "of PacBio data"
  date

  sh FullPipeline/nanoplot.sh \
  $out \
  $name \
  "PB" \
  $PWD


fi

printf "########################\n\n"

## minimum PHRED basequality: 20
## minimum read length 75bp
## automatically detect adapter sequences

if [[ !(-z $fwd) ]]
then

  echo "Start trimming"
  date

  sh FullPipeline/trim.sh \
  $out \
  $name \
  $PWD
  printf "########################\n\n"

fi

###############################################
########## (2) Detect contamination ###########

## detect human, bacterial and viral contamination in the trimmed reads, make a report and only retain the non-conmatinant reads for de-novo assembly

echo "Start decontamination"
date

sh FullPipeline/kraken_reads.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

##############################################
######## (3) Estimate Genome Size ############

# using Jellyfish to calculate kmer-coverage and genomoscope for formal analyses

echo "Estimation of genomesize"
date

sh FullPipeline/genomesize.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

###############################################
########### (4) Denovo assembly ###############

## denovo assembly with Spades

echo "Starting denovo assembly"
date

sh FullPipeline/denovo.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

###############################################
########### (5) Assembly QC ###############

## (A) QUAST analysis

echo "Starting assembly QC with Quast"
date

sh FullPipeline/quast.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

# (B) BUSCO analysis

echo "Starting assembly QC with BUSCO"
date

sh FullPipeline/busco.sh \
$out \
$name \
$busco \
$data \
$PWD
printf "########################\n\n"

## (C) Mapping reads

echo "Mapping reads against reference"
date

sh FullPipeline/mapping.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

## (D) Blast genome against the nt database

echo "BLASTing genome against the nt database"
date

sh FullPipeline/blast.sh \
$out \
$name \
$data \
$PWD
printf "########################\n\n"

## (E) Summarize results with blobtools

echo "Summarize with Blobtools"
date

sh FullPipeline/blobtools.sh \
$out \
$name \
$busco \
$data \
$PWD
printf "########################\n\n"

printf "Anlayses done!!\nNow copying results to output folder and starting Firefox with summaries"
date
printf "########################\n\n"

printf """
# ############### HTML output #####################
# # run the following commands in terminal to open Firefox and view the HTML output files
# """ > ${out}/output/HTML_outputs.sh

if [[ !(-z $fwd) ]]
then
  ## raw read QC
  firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.html &
  firefox --new-tab ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.html &

  printf """
  ## Illumina Data - FASTQC of raw reads
  firefox --new-tab ${out}/results/${name}_Illumina_fastqc/rawQC/${name}_1_fastqc.html
  firefox --new-tab ${out}/results/${name}_Illumina_fastqc/rawQC/${name}_2_fastqc.html
  """ >> ${out}/output/HTML_outputs.sh

  cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_1_fastqc.zip ${out}/output/${name}_1_raw_Illumina_fastqc.zip &
  cp ${out}/results/rawQC/${name}_Illumina_fastqc/${name}_2_fastqc.zip ${out}/output/${name}_2_raw_Illumina_fastqc.zip


  ## trimming
  firefox --new-tab ${out}/data/Illumina/${name}_1_val_1_fastqc.html &
  firefox --new-tab ${out}/data/Illumina/${name}_2_val_2_fastqc.html &

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
cp -r ${out}/results/rawQC/${name}_PB_sequeltools ${out}/output/

##kraken
cp ${out}/results/kraken_reads/${name}_PB_filtered.report ${out}/output/${name}_PB_kraken.txt

fi

## Explore Kraken output
docker run -p 5000:80 florianbw/pavian &
firefox --new-tab http://127.0.0.1:5000 &

printf """
## run Pavian to explore the Kraken output(s)
docker run -p 5000:80 florianbw/pavian &
firefox --new-tab http://127.0.0.1:5000
""" >> ${out}/output/HTML_outputs.sh

## genomesize
cp -r ${out}/results/GenomeSize/${name} ${out}/output/${name}_genomesize
firefox --new-tab ${out}/output/${name}_genomesize/linear_plot.png &

##QUAST
cp ${out}/results/AssemblyQC/Quast/report.pdf ${out}/output/${name}_quast.pdf
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html &

printf """
## QUAST
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html
""" >> ${out}/output/HTML_outputs.sh

#blobtools
awhile=10
source /opt/venv/blobtools-3.0.0/bin/activate

blobtools view \
  --out ${out}/results/AssemblyQC/blobtools/out \
  --interactive \
  ${out}/results/AssemblyQC/blobtools \
  & sleep $awhile && firefox --new-tab http://localhost:8001/view/all &

printf """
## Blobtools
source /opt/venv/blobtools-3.0.0/bin/activate

## if you get an error message, try other ports, 8002, 8003, etc.
blobtools view \
  --out ${out}/results/AssemblyQC/blobtools/out \
  --interactive \
  ${out}/results/AssemblyQC/blobtools \
  & sleep $awhile && firefox --new-tab http://localhost:8001/view/all

""" >> ${out}/output/HTML_outputs.sh

## finally, copy scaffolds file from

pigz ${out}/output/${name}_${data}.fa