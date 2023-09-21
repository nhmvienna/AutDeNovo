## Install all required software

echo "...testing if Conda and Mamba are installed"
echo "*********************"
echo ""

command -v conda >/dev/null 2>&1 || {
    echo >&2 "The installation pipeline requires Anaconda/Miniconda but it is not installed. Please check here: https://anaconda.org/ for more details. Aborting."
    exit 1
}

command -v mamba >/dev/null 2>&1 || {
    echo >&2 "The installation pipeline requires Mamba but it is not installed. Please check here: https://github.com/conda-forge/miniforge#mambaforge for more details. Aborting."
    exit 1
}

printf "successfully done\n"
echo "Have a cup of coffee, this may take a while... "
echo '''
   ( (
    ) )
  ........
  |      |]
  \      /
   `----´ '''
sleep 2
## change to home directory of AutDeNovo
BASEDIR=$(dirname $0)
cd ${BASEDIR}
mkdir envs

ConPath=$(whereis conda)
tmp=${ConPath#* }
Conda=${tmp%%/bin/co*}

## install FASTQC
mamba create \
    -p ${BASEDIR}/envs/fastqc \
    -y \
    -c bioconda \
    -c conda-forge \
    fastqc=0.11.9

## install BLAST+
mamba create \
    -p ${BASEDIR}/envs/blast \
    -y \
    -c bioconda \
    -c conda-forge \
    blast=2.14.1

## install blobtools
mamba create \
    -p ${BASEDIR}/envs/blobtools \
    -y \
    pip

source ${Conda}/etc/profile.d/conda.sh

conda activate \
    ${BASEDIR}/envs/blobtools

${Conda}/bin/pip install \
    blobtoolkit[full]==4.2.1

conda deactivate

## install BUSCO
mamba create \
    -p ${BASEDIR}/envs/busco \
    -y \
    -c conda-forge \
    -c bioconda \
    busco=5.4.3

## install SPAdes
mamba create \
    -p ${BASEDIR}/envs/spades \
    -y \
    -c conda-forge \
    -c bioconda \
    spades=3.15.5

## install Flye
mamba create \
    -p ${BASEDIR}/envs/flye \
    -y \
    -c conda-forge \
    -c bioconda \
    flye=2.9.2

## install Minimap
mamba create \
    -p ${BASEDIR}/envs/minimap \
    -y \
    -c conda-forge \
    -c bioconda \
    minimap2=2.26

source ${Conda}/etc/profile.d/conda.sh
conda activate \
    ${BASEDIR}/envs/minimap

mamba install \
    -y \
    -c conda-forge \
    -c bioconda \
    samtools=1.17

## install BWA
mamba create \
    -p ${BASEDIR}/envs/bwa \
    -y \
    -c conda-forge \
    -c bioconda \
    bwa=0.7.17

source ${Conda}/etc/profile.d/conda.sh
conda activate \
    ${BASEDIR}/envs/bwa

mamba install \
    -y \
    -c conda-forge \
    -c bioconda \
    samtools=1.17

## install Jellyfish
mamba create \
    -p ${BASEDIR}/envs/jellyfish \
    -y \
    -c conda-forge \
    -c bioconda \
    kmer-jellyfish=2.3.0

## install GenomeScope
mamba create \
    -p ${BASEDIR}/envs/genomescope \
    -y \
    -c conda-forge \
    -c bioconda \
    genomescope2=2.0

## install Kraken
mamba create \
    -p ${BASEDIR}/envs/kraken \
    -y \
    -c conda-forge \
    -c bioconda \
    kraken2=2.1.3

## install Nanoplot
mamba create \
    -p ${BASEDIR}/envs/nanoplot \
    -y \
    -c conda-forge \
    -c bioconda \
    nanoplot=1.41.6

## install Quast
mamba create \
    -p ${BASEDIR}/envs/quast \
    -y \
    -c conda-forge \
    -c bioconda \
    quast=5.2.0

## install Racon
mamba create \
    -p ${BASEDIR}/envs/racon \
    -y \
    -c conda-forge \
    -c bioconda \
    racon=1.5.0

## install Sequeltools
mamba create \
    -p ${BASEDIR}/envs/sequeltools \
    -y \
    python

cd ${BASEDIR}/envs/sequeltools
git clone https://github.com/ISUgenomics/SequelTools.git
cd SequelTools/Scripts
chmod +x *.sh *.py *.R
mv * ../../bin
rm -rf ${BASEDIR}/envs/sequeltools/SequelTools

## install Atria
mamba create \
    -p ${BASEDIR}/envs/atria \
    -y \
    -c conda-forge \
    -c bioconda \
    pigz pbzip2

source ${Conda}/etc/profile.d/conda.sh

conda activate \
    ${BASEDIR}/envs/atria

cd ${BASEDIR}

wget https://github.com/cihga39871/Atria/releases/download/v3.1.2/atria-3.1.2-linux.tar.gz

tar -zxvf atria-3.1.2-linux.tar.gz -C .

mv atria-3.1.2/bin/* envs/atria/bin
mv atria-3.1.2/lib/* envs/atria/lib

rm -rf atria-3.1.2*

conda deactivate

## install Fastp
mamba create \
    -p ${BASEDIR}/envs/fastp \
    -y \
    -c conda-forge \
    -c bioconda \
    fastp=0.23.4

## install trimgalore
mamba create \
    -p ${BASEDIR}/envs/trimgalore \
    -y \
    -c conda-forge \
    -c bioconda \
    trim-galore=0.6.2

## install pandoc
mamba create \
    -p ${BASEDIR}/envs/pandoc \
    -y \
    -c conda-forge \
    -c bioconda \
    pandoc

## install pigz
mamba create \
    -p ${BASEDIR}/envs/pigz \
    -y \
    -c conda-forge \
    -c bioconda \
    pigz
