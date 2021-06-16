#!/bin/bash

source /data/sample.config
EMAIL_SUB="Alignment"
ERROR_EMAIL_SUB="Alignment Error"

OUTPUT_FOLDER=/data/output_folder
CHR_BAM_FOLDER=/data/chr_bam/
REF_FILE=/data/GRCh37.mmi
TMP_FASTQ_FOLDER=/data/tmp_fastq
BATCH_FASTQ_FOLDER=/data/batch_fastq

UPLOAD_STATUS_FILE=/data/upload_status.txt
BASECALLING_STATUS_FILE=/data/basecalling_status.txt
POSTPROCESS_STATUS_FILE=/data/postprocess_status.txt

mkdir -p $BATCH_FASTQ_FOLDER
mkdir -p $CHR_BAM_FOLDER

for i in `ls ${TMP_FASTQ_FOLDER}/`;
do
	ORIG_FASTQ_FOLDER=${OUTPUT_FOLDER}/$i/guppy_output/pass
	if [ ${BARCODE_DONE} == "YES" ]; then
		ORIG_FASTQ_FOLDER=${ORIG_FASTQ_FOLDER}/${BARCODE_NUM}
	fi
	if [ $(ls ${TMP_FASTQ_FOLDER}/$i/*.fastq | wc -l) -eq $(ls ${ORIG_FASTQ_FOLDER}/*.fastq | wc -l) ]; then
		BATCH=$i
		BATCH_FOLDER=${OUTPUT_FOLDER}/$BATCH
		EMAIL_FILE=${BATCH_FOLDER}/${BATCH}_alignment.log
		BAM_FILE=${BATCH_FOLDER}/${BATCH}.bam
		FASTQ_FILES=$(ls ${TMP_FASTQ_FOLDER}/$i/*.fastq)

		echo "" > $EMAIL_FILE
		1>&2 echo "Aligning $BATCH"
		echo "=========== Alignment logs for $BATCH ============" >> $EMAIL_FILE
	
		NUM_ATTEMPT=0
		ALIGN_EXIT=1
		
		while [ $ALIGN_EXIT -gt 0 ] && [ $NUM_ATTEMPT -lt 5 ] ; do
		
			add_guppy_mm2_update "Starting attempt $NUM_ATTEMPT" $EMAIL_FILE

			add_guppy_mm2_update "Starting alignment" $EMAIL_FILE
			
			minimap2 -ax map-ont --MD -t 37 $REF_FILE $FASTQ_FILES | samtools view -F 0x904 -hb -@6 | samtools sort -@6 | samtools view -hb -@6 > $BAM_FILE

			ALIGN_EXIT=$?

			NUM_ATTEMPT=$(((NUM_ATTEMPT)+1))

		done
		
		if [ ${ALIGN_EXIT} -gt 0 ]; then

			add_guppy_mm2_update "Minimap2 job exited with non-zero code $ALIGN_EXIT even after 5 attempts, exiting job for ${BATCH}" $EMAIL_FILE
                        email_guppy_mm2_update "ALIGNMENT STATUS: Minimap2 job unsuccessful" $EMAIL_FILE $ERROR_EMAIL_SUB 
			break

                else

			add_guppy_mm2_update "Minimap2 job exited successfully in $NUM_ATTEMPT attempt/s" $EMAIL_FILE

                fi		


		mv ${TMP_FASTQ_FOLDER}/$i $BATCH_FASTQ_FOLDER/

		NUM_ATTEMPT=0
		SAM_EXIT=1
		
		while [ $SAM_EXIT -gt 0 ] && [ $NUM_ATTEMPT -lt 5 ] ; do
			
			samtools index -@40 $BAM_FILE
			SAM_EXIT=$?
			
			NUM_ATTEMPT=$(((NUM_ATTEMPT)+1))
			
		done

		if [ ${SAM_EXIT} -gt 0 ]; then

			add_guppy_mm2_update "samtools index exited with non-zero code $SAM_EXIT even after 5 attempts, exiting job for ${BATCH}" $EMAIL_FILE
                        email_guppy_mm2_update "ALIGNMENT STATUS: samtools index unsuccessful" $EMAIL_FILE $ERROR_EMAIL_SUB 
			break

		else

			add_guppy_mm2_update "samtools index exited successfully in $NUM_ATTEMPT attempt/s" $EMAIL_FILE

		fi

		for i in $(seq 1 22) X Y MT;
		do

			NUM_ATTEMPT=0
			SAM_EXIT=1
			
			while [ $SAM_EXIT -gt 0 ] && [ $NUM_ATTEMPT -lt 5 ] ; do
				
				samtools view -b -@40 $BAM_FILE $i > ${CHR_BAM_FOLDER}/${BATCH}_chr$i.bam
				samtools quickcheck ${CHR_BAM_FOLDER}/${BATCH}_chr$i.bam 

				SAM_EXIT=$?
				
				NUM_ATTEMPT=$(((NUM_ATTEMPT)+1))
				
			done

			if [ ${SAM_EXIT} -gt 0 ]; then

				add_guppy_mm2_update "samtools view (split for chr$i) exited with non-zero code $SAM_EXIT even after 5 attempts, exiting job for ${BATCH}" $EMAIL_FILE 
                	        email_guppy_mm2_update "ALIGNMENT STATUS: samtools view (split for chr$i) unsuccessful" $EMAIL_FILE $ERROR_EMAIL_SUB 
				break

			else
				
				add_guppy_mm2_update "samtools view (split for chr$i) exited successfully in $NUM_ATTEMPT attempt/s" $EMAIL_FILE 

			fi
		done

		email_guppy_mm2_update "ALIGNMENT STATUS: minimap2, merge, index, chr-wise bam split successful" $EMAIL_FILE $EMAIL_SUB 
	fi
done

UPLOAD_STATUS=$(cat $UPLOAD_STATUS_FILE)
BASECALLING_STATUS=$(cat $BASECALLING_STATUS_FILE)
POSTPROCESS_STATUS=$(cat $POSTPROCESS_STATUS_FILE)
NUM_FASTQ_FILES=$(ls $BATCH_FASTQ_FOLDER | wc -l)
NUM_TMP_FASTQ_FILES=$(ls $TMP_FASTQ_FOLDER | wc -l)

1>&2 echo "UPLOAD_STATUS: $UPLOAD_STATUS"
1>&2 echo "BASECALLING_STATUS: $BASECALLING_STATUS"
1>&2 echo "NUM_FASTQ_FILES: $NUM_FASTQ_FILES"
1>&2 echo "NUM_TMP_FASTQ_FILES: $NUM_TMP_FASTQ_FILES"
1>&2 echo "POSTPROCESS_STATUS: $POSTPROCESS_STATUS"

if [ $UPLOAD_STATUS -eq 1 ] && [ $BASECALLING_STATUS -eq 1 ] && [ $NUM_TMP_FASTQ_FILES -eq 0 ] && [ $NUM_FASTQ_FILES -gt 0 ] && [ $POSTPROCESS_STATUS -eq 2 ]; then
        add_guppy_mm2_update "Starting post-processing job-wise chr-wise bam" $EMAIL_FILE
        /data/scripts/postprocess_bam.sh
else
        add_guppy_mm2_update "Not starting post-processing job-wise chr-wise bam" $EMAIL_FILE
fi

