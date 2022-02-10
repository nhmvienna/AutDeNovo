# Automated de-novo assembly pipeline (AutDeNovo)

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

## Pipeline

Below, you will find a brief description of the consecutive analysis steps in the pipeline, as well as links to further literature.

### (1) [Trimming and base quality control](FullPipeline/trim.sh)

In the first step, the pipeline uses [trim_galore](https://github.com/FelixKrueger/TrimGalore) for quality trimming and for quality control. More specifically, Trim Galore is a Perl-based wrapper around [Cutadapt](https://github.com/marcelm/cutadapt) and [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) to consistently apply adapter and quality trimming to FastQ files. The parameters used by AutDeNovo are (1) automated adapter detection, (2) a minimum base quality of 20 and (3) a minimum read length of 75. This means that terminal bases with base-quality &lt;20 will be trimmed away and that only intact read-pairs with a minimum length of 75bp each will be retained. After that, FASTQC is generating a html output for a visual inspection of the filtered and trimmed data quality. A browser window will autmatically load once the pipeline is finished. Please check the [trim_galore](https://github.com/FelixKrueger/TrimGalore) and [Cutadapt](https://github.com/marcelm/cutadapt) documentation for more details about the trimming algorithm.

### (2) [Detection of microbial and human contamination](FullPipeline/kraken_reads.sh)

In the second step, the pipeline invoces [kraken2](https://ccb.jhu.edu/software/kraken2/), which was originally conceived for metagenomic analyses, for detecting and removing contamination with human or microbial DNA in the filtered reads. In brief, Kraken2 is a taxonomic classification system using exact k-mer matches to a reference database for high accuracy and fast classification speeds. This step retains decontaminated reads without hits in the reference database. After the pipeline is completed, Firefox will load the browser-based application [Pavian](https://ccb.jhu.edu/software/pavian/) which allows to visulaize the Kraken output, i.e. &lt;out>/results/kraken_reads/&lt;name>.report, where &lt;out> is the output directory and name is the sample name, see above.

### (3) [Genome-size estimation](FullPipeline/kraken_reads.sh)

After that, the pipeline uses JELLYFISH for counting k-mers in the filtered and decontaminated reads and Genomescope to estimate the approximate genomesize. Conceptually, the number of unique k-mers and their coverage allows for a rough estimation of the genome-size, which is a function of the sequencing depth and the number of unique kmers. Specifcally, for a given sequence of length L, and a k-mer size of k, the total k-mer’s (N) possible will be given by N = ( L – k ) + 1. In genomes > 1mb, N (theoretically) converges to the true genomesize. Since the genome is usually sequenced more than 1-fold, the number of total kmers further needs to be divided by the coverage. However, the average coverage is usually unknown and influenced by seqencing errors, heterozygosity and repetitive elements. The average coverage is thus estimated from the empirical coverage distribution at unique kmers. For a more detailed description, see this great [tutorial](https://bioinformatics.uconn.edu/genome-size-estimation-tutorial/). Genomescope calculates the estimated genome-size, the prospective ploidy level and the ratio of unique and repetitive sequences in the genome. This is summarized in a historgramm plot and a summary text file.

### (4) [de-novo assembly](FullPipeline/denovo.sh)

De novo assembly based on SPAdes with standard parameters using trimmed and decontaminated reads. More details will be added soon

### (5) Assembly QC

#### (a) [Quast](FullPipeline/denovo.sh)

Summary statistics of the SPAdes assembly, i.e. #contigs, N50, N90, etc. with QUAST. More details will be added soon.

#### (b) [BLAST](FullPipeline/blast.sh)

BLASTing each contig against a local copy of the NCBI nt database. Only the Top 10 hits with e &lt; 1e-25 are retained for each hit, which allows estimating off-target DNA contamination in the library. The result table is quantified with BlobTools (see below)

#### (c) [BUSCO](FullPipeline/busco.sh)

Detecting of Benchmarking Universal Single-Copy Orthologs (BUSCO) from all vertebrates (vertebrata_odb10) in the de-novo assembled scaffolds to estimate the completeness of the assembly. The result table is quantified with BlobTools (see below).

#### (d) [Mapping](FullPipeline/mapping.sh)

The trimmed reads are remapped to the assembled scaffolds to investigate the variation in read depth among the different scaffolds, which may indicate off-target DNA contamination in the library. These results are quantified with BlobTools (see below).

#### (e) [BlobTools](FullPipeline/blobtools.sh)

Quantitative analysis of assembly quality based on variation of read-depth, GC-content and taxonomic assignment of each scaffold. The summary plots and tables are accessible through an interactive browser window.
