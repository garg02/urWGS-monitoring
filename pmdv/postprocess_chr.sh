#!/bin/bash

source /data/sample.config
CHR_FOLDER=/data/$1_folder

gsutil cp $CHR_FOLDER/${SAMPLE}_pmd_$1.vcf.gz ${PMD_VCF_BUCKET}/
gsutil -o "GSUtil:parallel_composite_upload_threshold=750M" -m cp $CHR_FOLDER/margin/MARGIN_PHASED.PEPPER_SNP_MARGIN.haplotagged.bam ${CURATION_OUTPUT_BUCKET}/HP_bam/${SAMPLE}_$1.bam
gsutil -o "GSUtil:parallel_composite_upload_threshold=750M" -m cp $CHR_FOLDER/margin/MARGIN_PHASED.PEPPER_SNP_MARGIN.haplotagged.bam.bai ${CURATION_OUTPUT_BUCKET}/HP_bam/${SAMPLE}_$1.bam.bai
gsutil -m rsync -r $CHR_FOLDER/ ${PMD_LOG_BUCKET}/$1_folder/

echo "1" > $CHR_FOLDER/$1_pmd_status.txt
gsutil cp  $CHR_FOLDER/$1_pmd_status.txt ${PMD_STATUS_BUCKET}/
