## get repository
git clone https://github.com/nhmvienna/AutDeNovo

## change to repository folder
cd AutDeNovo

## run pipeline on test dataset
./AutDeNovoFull.sh \
  Name=SomeFish \
  OutputFolder=Test/SomeFish \
  Fwd=Test/subset/Illumina/Garra474_1.fq.gz \
  Rev=Test/subset/Illumina/Garra474_2.fq.gz \
  ONT=/media/inter/mkapun/projects/AutDeNovo/Test/subset/ONT \
  PB=/media/inter/mkapun/projects/AutDeNovo/Test/subset/PacBio \
  BuscoDB=vertebrata_odb10
