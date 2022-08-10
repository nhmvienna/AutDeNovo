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
  ONT=/media/inter/pipelines/AutDeNovo/Test/subset/ONT \
  PB=/media/inter/pipelines/AutDeNovo/Test/subset/PacBio \
  Trimmer=Atria \
  BuscoDB=vertebrata_odb10
