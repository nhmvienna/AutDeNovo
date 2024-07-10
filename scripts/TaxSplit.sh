## link Tax info to BLAST
python /media/inter/pipelines/AutDeNovo/scripts/LinkTaxonomy.py \
    --Nodes /media/scratch/NCBI_taxdump/nodes.dmp \
    --Names /media/scratch/NCBI_taxdump/names.dmp \
    --BLAST /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/results/BLAST/blastn_Lapus_Luchetti.txt \
    --output /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/results/BLAST/blastn_Lapus_Luchetti.tax

## split by Tax info
mkdir /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/output/SplitByTax

python /media/inter/pipelines/AutDeNovo/scripts/SplitFASTAByBLAST.py \
    --Tax /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/results/BLAST/blastn_Lapus_Luchetti.tax \
    --FASTA /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/output/Lapus_Luchetti_ILL.fa \
    --output /media/inter/aloewenstein/Lapus_assembly_Luchetti_NCBI/output/SplitByTax \
    --Filenames species \
    --Foldername kingdom
