## get repository
git clone https://github.com/nhmvienna/AutDeNovo

## change to repository folder
cd AutDeNovo

## run pipeline on test dataset
./AutDeNovo.sh \
  Name=SomeFish \
  OutputFolder=Test/SomeFish \
  Fwd=Test/subset/Garra474_1.fq.gz \
  Rev=Test/subset/Garra474_2.fq.gz \
  BuscoDB=vertebrata_odb10
