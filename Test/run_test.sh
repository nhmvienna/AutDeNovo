## get repository
git clone https://github.com/nhmvienna/AutDeNovo

## define repository folder
BaseDir=/Users/martinkapun/Documents/GitHub/AutDeNovo

## run pipeline on test dataset
bash ${BaseDir}/AutDeNovo_exp.sh \
  Name=SomeFish \
  OutputFolder=${BaseDir}/Test/SomeFish \
  Fwd=${BaseDir}/Test/subset/Illumina/Garra474_1.fq.gz \
  Rev=${BaseDir}/Test/subset/Illumina/Garra474_2.fq.gz \
  ONT=${BaseDir}/Test/subset/ONT \
  PB=${BaseDir}/Test/subset/PacBio \
  threads=10 \
  threadsAssembly=10 \
  RAM=20 \
  RAMAssembly=20 \
  decont=no \
  Trimmer=trimgalore \
  BuscoDB=vertebrata_odb10 \
  BLASTdb=/media/scratch/NCBI_nt_DB_210714/nt \
  Racon=4
