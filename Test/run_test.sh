## get repository
git clone https://github.com/nhmvienna/AutDeNovo

## change to repository folder
cd /media/inter/pipelines/AutDeNovo

## run pipeline on test dataset
./AutDeNovo.sh \
  Name=SomeFish \
  OutputFolder=Test/SomeFish \
  Fwd=Test/subset/Illumina/Garra474_1.fq.gz \
  Rev=Test/subset/Illumina/Garra474_2.fq.gz \
  ONT=Test/subset/ONT \
  PB=Test/subset/PacBio \
  threads=10 \
  RAM=20 \
  RAMAssembly=20 \
  decont=no \
  SmudgePlot=no \
  BuscoDB=vertebrata_odb10 \
  Trimmer=Atria \
  Racon=4
