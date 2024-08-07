##  trim and QC of raw reads

out=$1
name=$2
type=$3
pwd=$4
threads=$5
RAM=$6
openpbs=$7
PrintOnly=$8

printf "bash FullPipeline_exp/nanoplot.sh $1 $2 $3 $4 $5 $6 $7 $8\n# "

#############################

echo """
  #!/usr/bin/env bash

  ## name of Job
  #PBS -N nanoplot_${name}

  ## Redirect output stream to this file.
  #PBS -o ${out}/log/raw_nanoplot_${name}_${type}_log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select ${threads} cores and ${RAM}gb of RAM
  #PBS -l select=1:ncpus=${threads}:mem=${RAM}g

  ## Go to pwd
  cd ${pwd}

  ######## load dependencies #######

  eval \"\$(conda shell.bash hook)\"
  conda activate envs/nanoplot

  ######## run analyses #######

  mkdir -p ${out}/results/rawQC

  ## loop through all raw FASTQ and test quality

  if [[ ( $type == 'ONT' ) ]]
  then

    NanoPlot \
      -t ${threads} \
      --summary ${out}/data/ONT/${name}_sequencing_summary.txt \
      --plots dot \
      -o ${out}/results/rawQC/${name}_ONT_nanoplot

      ## convert HTML Report to PDF

      conda deactivate
      conda activate envs/pandoc

      pandoc -f html \
      -t pdf \
      -o ${out}/results/rawQC/${name}_ONT_nanoplot/${name}_ONT_nanoplot-report.pdf \
      ${out}/results/rawQC/${name}_ONT_nanoplot/NanoPlot-report.html

  else

    NanoPlot \
      -t ${threads} \
      --fastq ${out}/data/PB/${name}_pb.fq.gz \
      --plots dot \
      -o ${out}/results/rawQC/${name}_PB_nanoplot

    ## convert HTML Report to PDF

      conda deactivate
      conda activate envs/pandoc

    pandoc -f html \
    -t pdf \
    -o ${out}/results/rawQC/${name}_PB_nanoplot/${name}_PB_nanoplot-report.pdf \
    ${out}/results/rawQC/${name}_PB_nanoplot/NanoPlot-report.html

  fi
""" >${out}/shell/qsub_nanoplot_${name}_${type}.sh

if [[ $PrintOnly == "no" ]]; then
  if [[ $openpbs != "no" ]]; then
    qsub -W block=true ${out}/shell/qsub_nanoplot_${name}_${type}.sh
  else
    bash ${out}/shell/qsub_nanoplot_${name}_${type}.sh &>${out}/log/raw_nanoplot_${name}_${type}_log.txt
  fi
fi
