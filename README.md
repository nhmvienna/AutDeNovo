# Automated de-novo assembly pipeline (AutDeNovo)

(c) Martin Kapun

The purpose of this repository is to provide a simple yet state-of-the-art de-novo assembly pipeline specifically tailored for short-read paired-end Illumina sequencing data of museum samples. This pipeline is laregly based on the workflow kindly provided by **Tilman Schell** from the [TBG Loewe](https://tbg.senckenberg.de/de/) of the Senkenberg Gesellschaft in Frankfurt. Note, that this pipeline is specifically tailored to our computer server and can thus only be run at the NHM without further modifications.

## Input

The pipeline requires four obligatory input parameters:

-   **Name**:   The name (without spacesand special characters) of the sample to be used for naming the output folder, e.g. _Garra_474_
-   **OutputFolder**: The full path to the output folder where are the processed data and output should be stored, e.g. _/media/inter/GarraDenovo_
-   **Fwd**: The full path to the raw foward-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_1.fq.gz_
-   **Rev**: The full path to the corresponding raw reverse-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_2.fq.gz_

In addition, you can optionally also provide the name of the BUSCO database, which should be used for BUSCO analyses during the quality control steps to evaluate the quality and the completeness of the denovo assembly.

-   **BUSCOdb**: The name of the BUSCO database to be used for the QC analyses, a complete list can be found [here](https://busco.ezlab.org/busco_v4_data.html) and [here](https://busco.ezlab.org/list_of_lineages.html). By default, the database `vertebrata_odb10` is used.

## Command

The pipeline is a simple shell script that executes a series of sub-shells that serially send jobs to OpenPBS. A typcial command lines looks like this:

```bash
./AutDeNovo.sh \
Name=Yeti_01 \
OutputFolder=/media/output \
Fwd=/media/seq/fwd.fq.gz \
Rev=/media/seq/rev.fq.gz \
BuscoDB=vertebrata_odb10
```
