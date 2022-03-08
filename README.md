# Automated de-novo assembly pipeline (AutDeNovo)

The purpose of this repository is to provide a simple yet state-of-the-art de-novo assembly pipeline of non-human museum samples based on either high-quality short-read Illumina sequencing data, PacBio long reads based on SMRTcell technology or Oxford Nanopore long-read sequencing data after high accuracy basecalling. The workflow allows to use each data type separately or us any combination of sequencing data. The QC and Illumina-specifc steps of this pipeline are largely based on the workflow kindly provided by **Tilman Schell** from the **[LOEWE Centre for Translational Biodiversity Genomics​](https://tbg.senckenberg.de/de/)** in Frankfurt. Note, that this pipeline is specifically tailored to our server infrastructure and can thus only be run at the NHM without further modifications.

## Input

The pipeline requires these two obligatory input parameters:

-   **Name**:   The name (without spaces and special characters) of the sample to be used for naming the output folder, e.g. _SomeFish_
-   **OutputFolder**: The full path to the output folder where are the processed data and output should be stored, e.g. _/media/inter/SomeFish_

In addition, you need to provide the paths to **at least one input dataset**, which can be either (1) high-quality short-read Illumina sequencing data, (2) PacBio long reads based on SMRTcell technology or (3) Oxford Nanopore long-read sequencing data after high accuracy basecalling.

**_Illumina_**

-   **Fwd**: The full path to the raw forward-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_1.fq.gz_
-   **Rev**: The full path to the corresponding raw reverse-oriented Illumina read-file in gzipped FASTQ-format, e.g. _/media/inter/rawreads/Garra_2.fq.gz_

**_Oxford Nanopore_**

-   **ONT**: The full path to the folder that contains the **passed** based-called reads split in one or multiple FASTQ files (a folder usually called `/PASS`) AND the `sequencing_summary.txt` output file from basecalling with [Guppy](https://denbi-nanopore-training-course.readthedocs.io/en/latest/basecalling/basecalling.html). This summary file is needed for QC of the raw reads.

**_Pacific Biosciences_**

-   **PB**: The full path to the folder that contains the **circular consensus sequences (CCS)** in FASTQ format generated from the raw subreads.bam file using the ccs program from PacBio. See [here](https://ccs.how), for more details.

In addition, you can optionally also provide the name of the BUSCO database, which should be used for BUSCO analyses during the quality control steps to evaluate the quality and the completeness of the denovo assembly.

-   **BUSCOdb**: The name of the BUSCO database to be used for the QC analyses, a complete list can be found [here](https://busco.ezlab.org/busco_v4_data.html) and [here](https://busco.ezlab.org/list_of_lineages.html). By default, the database `vertebrata_odb10` is used.

## Command

The pipeline is a simple shell script that executes a series of sub-shells that serially send jobs to OpenPBS. A typcial command lines looks like this:

```bash
## get repository
git clone https://github.com/nhmvienna/AutDeNovo

## change to repository folder
cd AutDeNovo

## run pipeline on test dataset
## run pipeline on test dataset
./AutDeNovo.sh \
  Name=SomeFish \
  OutputFolder=Test/SomeFish \
  Fwd=Test/subset/Illumina/Garra474_1.fq.gz \
  Rev=Test/subset/Illumina/Garra474_2.fq.gz \
  ONT=Test/subset/ONT \
  PB=Test/subset/PacBio \
  BuscoDB=vertebrata_odb10
```

## Pipeline

Below, you will find a brief description of the consecutive analysis steps in the pipeline, as well as links to further literature.

### (1) [Trimming and base quality control](FullPipeline/trim.sh)

In the first step, the pipeline uses [trim_galore](https://github.com/FelixKrueger/TrimGalore) for quality trimming and for quality control. More specifically, Trim Galore is a Perl-based wrapper around [Cutadapt](https://github.com/marcelm/cutadapt) and [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) to consistently apply adapter and quality trimming to FastQ files. The parameters used by AutDeNovo are (1) automated adapter detection, (2) a minimum base quality of 20 and (3) a minimum read length of 75. This means that terminal bases with base-quality &lt;20 will be trimmed away and that only intact read-pairs with a minimum length of 75bp each will be retained. After that, FASTQC is generating a html output for a visual inspection of the filtered and trimmed data quality. A browser window will autmatically load once the pipeline is finished. Please check the [trim_galore](https://github.com/FelixKrueger/TrimGalore) and [Cutadapt](https://github.com/marcelm/cutadapt) documentation for more details about the trimming algorithm.

### (2) [Detection of microbial and human contamination](FullPipeline/kraken.sh)

In the second step, the pipeline invoces [kraken2](https://ccb.jhu.edu/software/kraken2/), which was originally conceived for metagenomic analyses, for detecting and removing contamination with human or microbial DNA in the filtered reads. In brief, Kraken2 is a taxonomic classification system using exact k-mer matches to a reference database for high accuracy and fast classification speeds. This step retains decontaminated reads without hits in the reference database. After the pipeline is completed, Firefox will load the browser-based application [Pavian](https://ccb.jhu.edu/software/pavian/) which allows to visulaize the Kraken output, i.e. &lt;out>/results/kraken_reads/&lt;name>.report, where &lt;out> is the output directory and name is the sample name, see above.

### (3) [Genome-size estimation](FullPipeline/genomesize.sh)

After that, the pipeline uses [Jellyfish](https://github.com/gmarcais/Jellyfish) for counting k-mers in the filtered and decontaminated reads and [Genomescope](https://github.com/schatzlab/genomescope) to estimate the approximate genomesize. Conceptually, the number of unique k-mers and their coverage allows for a rough estimation of the genome-size, which is a function of the sequencing depth and the number of unique kmers. Specifcally, for a given sequence of length L, and a k-mer size of k, the total k-mer’s (N) possible will be given by N = ( L – k ) + 1. In genomes > 1mb, N (theoretically) converges to the true genomesize. Since the genome is usually sequenced more than 1-fold, the number of total kmers further needs to be divided by the coverage. However, the average coverage is usually unknown and influenced by seqencing errors, heterozygosity and repetitive elements. The average coverage is thus estimated from the empirical coverage distribution at unique kmers. For a more detailed description, see this great [tutorial](https://bioinformatics.uconn.edu/genome-size-estimation-tutorial/). Genomescope calculates the estimated genome-size, the prospective ploidy level and the ratio of unique and repetitive sequences in the genome. This is summarized in a historgramm plot and a summary text file. In addition, the program [smudgeplot](https://github.com/KamilSJaron/smudgeplot) will estimate the ploidy of the dataset based on the distribution of coverages.

### (4) [De-novo assembly](FullPipeline/denovo.sh)

The pipeline employs the [Flye](https://github.com/fenderglass/Flye) assembler with standard parameters for either ONT or PacBio long-read sequencing data or a combination of both. If ONT and PacBio reads are processed jointly, the pipleine follows the [best practice recommendations](https://github.com/fenderglass/Flye/blob/flye/docs/FAQ.md#can-i-use-both-pacbio-and-ont-reads-for-assembly) and uses the ONT data for the initial assembly and the PacBio data for polishing. In case, Illumina HiFi sequencing data are available, the de-novo assembly is based on [SPAdes](https://github.com/ablab/spades) with standard parameters using trimmed and decontaminated reads. In case a combination of Illumina HiFi sequencing data and long-read data is available, the pipleine will nevertheless employ SPAdes for de-novo assembly based on Illumina reads. The long-read sequencing data will in this case be used for scaffolding. See [here](https://cab.spbu.ru/files/release3.15.4/manual.html) for more details on how SPAdes works.

### (5) Assembly QC

After the assembly is finished, the quality of the assembled genome will be assessed with a combination of different analysis tools as described below:

#### (a) [Quast](FullPipeline/quast.sh)

Summary statistics of the SPAdes assembly, i.e. #contigs, N50, N90, etc. with QUAST. Check out the QUAST [manual](https://github.com/ablab/quast) for more details. More details on the  pipeline will be added soon.

#### (b) [BLAST](FullPipeline/blast.sh)

[BLASTing](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download) each contig against a local copy of the NCBI `nt` database. Only the Top 10 hits with e &lt; 1e-25 are retained for each hit, which allows estimating off-target DNA contamination in the library. The result table is quantified with BlobTools (see below)

#### (c) [BUSCO](FullPipeline/busco.sh)

Detecting of [Benchmarking Universal Single-Copy Orthologs (BUSCO)](https://busco.ezlab.org/busco_userguide.html) from all vertebrates (by default `vertebrata_odb10`) in the de-novo assembled scaffolds to estimate the completeness of the assembly. The result table is quantified with BlobTools (see below).

#### (d) [Mapping](FullPipeline/mapping.sh)

The trimmed reads are remapped with [bwa](http://bio-bwa.sourceforge.net/) (Illumina reads), or [minimap2](https://github.com/lh3/minimap2) (ONT and PacBio reads) to the assembled scaffolds to investigate the variation in read depth among the different scaffolds, which may indicate off-target DNA contamination in the library. These results are quantified with BlobTools (see below).

#### (e) [BlobTools](FullPipeline/blobtools.sh)

[Blobtools](https://github.com/blobtoolkit/blobtoolkit) allows a quantitative analysis of assembly quality based on variation of read-depth, GC-content and taxonomic assignment of each scaffold. The summary plots and tables are accessible through an interactive browser window. Note, occasionally port 8001 may be already occuppied. In this case, you can retry to load the html page with ports of increasing number, e.g. 8002, 8003, etc.

## Output

After the pipeline is finished, the scaffolds of the de-novo assembly and the most important QC outputs will be copied to the /output folder. These output files include:

-   FASTQC/Nanoplot outputs before and after trimming (of Illumina data)
-   A report of the Kraken2 decontamination pipeline
-   Genomesize estimates
-   The assembled genome
-   A report with basic assembly QC statistics generated by QUAST
-   A table with BLAST hits of each contig
-   A folder with the amino-acid sequences of all BUSCO hits

In addition, various html-based results can be loaded in Firefox. The file `HTML_outputs.sh` in the /output folder contains all commands to load the HTML output in Firefox at a later timepoint.
Moreover, the full pipeline including all commands will be written to a file named `pipeline.sh` in the /shell folder. In particular, this file allows to repeat certain analyses in the whole pipeline.

## Future updates

This is just the very first version and I will implement more functionality in the near future. Additional features may include:

-   [ ]  Modify more parameters via the commandline or through a config file
-   [ ]  Possibility to skip certain steps of the pipeline
-   [x]  Allow ONT or PacBio data or a combination of Illumina and single molecule sequencing data for de-novo assemblies

Please le me know if you have further ideas or need help by posting an issue in this repository.
