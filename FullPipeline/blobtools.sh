## Summarize with blobtools

out=$1
name=$2
busco=$3

##########################

### and BlobTools
mkdir ${out}/results/AssemblyQC/blobtools
echo """
  #!/bin/sh

  ## name of Job
  #PBS -N blobtools_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/blobtools_${name}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 20 cores and 200gb of RAM
  #PBS -l select=1:ncpus=200:mem=200gb

  ## create all project directories
  export btkroot=${out}/results/AssemblyQC/blobtools
  mkdir \$btkroot
  mkdir \$btkroot/datasets
  mkdir \$btkroot/data
  mkdir \$btkroot/taxdump

  ## download taxdump from NCBI
  cd \$btkroot/taxdump
  curl -L ftp://ftp.ncbi.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz | tar xzf -
  cd ..

  ##put all your input data files into the directory \$btkroot/data
  ##Here you can use the test examples in /programs/blobtoolkit_test/
  cp ${out}/results/assembly/${name}/scaffolds.fasta  \$btkroot/data/
  cp ${out}/results/AssemblyQC/Busco/${name}/run_${busco}/full_table.tsv  \$btkroot/data/
  cp ${out}/results/mapping/${name}.bam  \$btkroot/data/
  cp ${out}/results/BLAST/blastn_${name}.txt \$btkroot/data/

  docker rm -f \$(docker ps -a -q)

  ## create a genome BlobDir
  docker run --rm --name ${name} \
    -u \$UID:\$GROUPS \
    -v \$btkroot/datasets:/blobtoolkit/datasets \
    -v \$btkroot/data:/blobtoolkit/data \
    -v \$btkroot/taxdump:/blobtoolkit/taxdump \
    genomehubs/blobtoolkit:latest \
    ./blobtools2/blobtools create \
    --fasta data/scaffolds.fasta  \
    --taxdump taxdump \
    datasets/${name}

  ## add BUSCO results
  docker run --rm --name ${name} \
    -u \$UID:\$GROUPS \
    -v \$btkroot/datasets:/blobtoolkit/datasets \
    -v \$btkroot/data:/blobtoolkit/data \
    -v \$btkroot/taxdump:/blobtoolkit/taxdump \
    genomehubs/blobtoolkit:latest \
    ./blobtools2/blobtools add \
    --busco data/full_table.tsv  \
    datasets/${name}

  ## add BLAST results
  docker run --rm --name ${name} \
    -u \$UID:\$GROUPS \
    -v \$btkroot/datasets:/blobtoolkit/datasets \
    -v \$btkroot/data:/blobtoolkit/data \
    -v \$btkroot/taxdump:/blobtoolkit/taxdump \
    genomehubs/blobtoolkit:latest \
    ./blobtools2/blobtools add \
    --hits data/blastn_${name}.txt  \
    --taxdump taxdump \
    datasets/${name}

  ## add coverage info
  docker run --rm --name ${name} \
    -u \$UID:\$GROUPS \
    -v \$btkroot/datasets:/blobtoolkit/datasets \
    -v \$btkroot/data:/blobtoolkit/data \
    -v \$btkroot/taxdump:/blobtoolkit/taxdump \
    genomehubs/blobtoolkit:latest \
    ./blobtools2/blobtools add \
    --cov data/${name}.bam  \
    --threads 100 \
    datasets/${name}

  chmod a+rX \$btkroot

""" > ${out}/shell/qsub_blobtools_${name}.sh

qsub -W block=true ${out}/shell/qsub_blobtools_${name}.sh

## Show results in firefox
docker rm -f $(docker ps -a -q)

docker run -d --rm --name ${name} \
  -v ${out}/results/AssemblyQC/blobtools/datasets:/blobtoolkit/datasets \
  -p 8000:8000 -p 8080:8080 \
  -e VIEWER=true \
  genomehubs/blobtoolkit:latest

awhile=10
sleep $awhile && firefox http://localhost:8080/view/all
