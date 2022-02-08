#!/bin/bash

## AutDeNovo -v 0.0.1 - 31/01/2022

## Author: Martin Kapun, largely based on the pipleine of TBG Loewe@Senkenberg/Frankfurt from Tilman Schell
## test if Shell is indeed BASH

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

~/AutDeNovo.sh \             ## The script name
Name=Yeti_01 \                  ## The sample name
OutputFolder=/media/output \    ## The full path to the output folder
Fwd=/media/seq/fwd.fq.gz \      ## The full path to the raw read forward FASTQ file
Rev=/media/seq/rev.fq.gz \      ## The full path to the raw read reverse FASTQ file
BuscoDB=vertebrata_odb10 \      ## The BUSCO database to be used; by default it is set to "vertebrata_odb10"; see here to pick the right one: https://busco.ezlab.org/busco_v4_data.html and here: https://busco.ezlab.org/list_of_lineages.html


Please see below, which parameter is missing:
*******************************
'''

if [ -z "$name" ]; then echo "${help}Name=Yeti_01 is missing: The name of the sample needs to be specified"; exit 1 ; fi
if [ -z "$out" ]; then echo "${help}OutputFolder=/media/output is missing: The full path to the output folder needs to be defined"; exit 2 ; fi
if [ -z "$fwd" ]; then echo "${help}Fwd=/media/seq/fwd.fq.gz is missing: The full path to the raw read forward FASTQ file needs to be defined"; exit 3; fi
if [ -z "$rev" ]; then echo "${help}Rev=/media/seq/rev.fq.gz is missing: The full path to the raw read revese FASTQ file needs to be defined"; exit 4; fi
if [ -z "$busco" ]; then busco="vertebrata_odb10"; fi

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

## (1) make copy of original reads
echo "Copying data"
date

cp $fwd ${out}/data/${name}_1.fq.gz &
cp $rev ${out}/data/${name}_2.fq.gz
printf "########################\n\n"

wait

###############################################
############# (1) Trimming and QC #############

## minimum PHRED basequality: 20
## minimum read length 75bp
## automatically detect adapter sequences

echo "Start trimming"
date

sh FullPipeline/trim.sh \
$out \
$name
printf "########################\n\n"

###############################################
########## (2) Detect contamination ###########

## detect human, bacterial and viral contamination in the trimmed reads, make a report and only retain the non-conmatinant reads for de-novo assembly

echo "Start decontamination"
date

sh FullPipeline/kraken_reads.sh \
$out \
$name
printf "########################\n\n"

###############################################
######### (3) Estimate Genome Size ############

## using Jellyfish to calculate kmer-coverage and genomoscope for formal analyses

echo "Estimation of genomesize starting"
date

sh FullPipeline/genomesize.sh \
$out \
$name
printf "########################\n\n"

###############################################
########### (4) Denovo assembly ###############

## using Jellyfish to calculate kmer-coverage and genomoscope for formal analyses

echo "Starting denovo assembly with Spades"
date

sh FullPipeline/denovo.sh \
$out \
$name
printf "########################\n\n"

###############################################
########### (5) Assembly QC ###############

## (A) QUAST analysis

echo "Starting assembly QC with Quast"
date

sh FullPipeline/quast.sh \
$out \
$name
printf "########################\n\n"

## (B) BUSCO analysis

echo "Starting assembly QC with BUSCO"
date

sh FullPipeline/busco.sh \
$out \
$name \
$busco
printf "########################\n\n"

# (C) Mapping reads

echo "Mapping reads against reference"
date

sh FullPipeline/mapping.sh \
$out \
$name
printf "########################\n\n"

## (D) Blast genome against the nt database

echo "BLASTing genome against the nt database"
date

sh FullPipeline/blast.sh \
$out \
$name
printf "########################\n\n"

## (E) Summarize results with blobtools

echo "Summarize with Blobtools"
date

sh FullPipeline/blobtools.sh \
$out \
$name \
$busco
printf "########################\n\n"

printf "______________________\n"
printf "Anlayses done!!\nNow copying results to output folder and starting Firefox with summaries"
date
printf "______________________\n"

mkdir ${out}/output

## trimming
firefox --new-tab ${out}/data/${name}_1_val_1_fastqc.html
firefox --new-tab ${out}/data/${name}_2_val_2_fastqc.html

cp ${out}/data/${name}_1_val_1_fastqc.zip > ${out}/output/${name}_1_fastqc.zip
cp ${out}/data/${name}_2_val_2_fastqc.zip > ${out}/output/${name}_2_fastqc.zip

## kraken
cp ${out}/results/kraken_reads/${name}_filtered.report > ${out}/output/${name}_kraken.txt
cp ${out}/results/kraken_reads/${name}_filtered.report > ${out}/output/${name}_kraken.txt

docker run -p 5000:80 florianbw/pavian &
firefox --new-tab http://127.0.0.1:5000

## genomesize
cp -r ${out}/results/GenomeSize/${name} ${out}/output/${name}_genomesize
firefox --new-tab ${out}/output/${name}_genomesize/linear_plot.png

##QUAST
cp ${out}/results/AssemblyQC/Quast/report.pdf ${out}/output/${name}_quast.pdf
firefox --new-tab ${out}/results/AssemblyQC/Quast/report.html

##blobtools
docker rm -f \$(docker ps -a -q)

docker run -d --rm --name ${name} \
  -v ${out}/results/AssemblyQC/blobtools/datasets:/blobtoolkit/datasets \
  -p 8000:8000 -p 8080:8080 \
  -e VIEWER=true \
  genomehubs/blobtoolkit:latest

awhile=10
sleep $awhile && firefox --new-tab http://localhost:8080/view/all
