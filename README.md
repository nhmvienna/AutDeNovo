# Automated de-novo assembly pipeline (AutDeNovo)

(c) Martin Kapun

The purpose of this repository is to provide a simple yet state-of-the-art de-novo assembly pipeline specifically tailored for short-read paired-end Illumina sequencing data of museum samples. This pipeline is laregly based on the workflow kindly provided by **Tilman Schell** from the [TBG Loewe](https://tbg.senckenberg.de/de/) of the Senkenberg Gesellschaft in Frankfurt. Note, that this pipeline is specifically tailored to our computer server and can thus only be run at the NHM without further modifications.

## Input

The pipeline requires four obligatory input parameters:

-   **Name**:   The name (without spacesand special characters) of the sample to be used for naming the output folder, e.g. _Garra_474_
-   **OutputFolder**: The full path to the output folder where are the processed data and output should be stored, e.g. _/media/inter/GarraDenovo_
-   **Fwd**: The full path to the raw foward-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_1.fq.gz_
-   **Rev**: The full path to the corresponding raw reverse-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_2.fq.gz_
