#!/bin/bash

gcloud compute instances create $1 \
        --zone us-west1-a \
        --source-instance-template annotation-template \
	--create-disk=boot=yes,image=annotation-image-v1,size=100GB \
	--local-ssd=interface=NVME \
        --metadata startup-script='#!/bin/bash
		gsutil cp gs://ur_wgs_public_data/test_data/mount_ssd_nvme.sh .
		bash -c mount_ssd_nvme.sh 
		gsutil -o "GSUtil:parallel_thread_count=1" -o "GSUtil:sliced_object_download_max_components=8" cp gs://ur_wgs_public_data/test_data/GRCh37.fa /data/
		mkdir -p /data/bed_files
		gsutil -o "GSUtil:parallel_thread_count=1" -o "GSUtil:sliced_object_download_max_components=8" cp gs://ur_wgs_public_data/small_variant_annotation/* /data/bed_files/
		cd /data/
		git clone https://gitfront.io/r/gsneha26/e351ab7e8a8eed487da76fbbc09fa73d7ab40dfb/urWGS.git
		export PROJECT_DIR=/data/urWGS
		CONFIG_FILE_URL=$(gcloud compute instances describe $(hostname) --zone=$(gcloud compute instances list --filter="name=($(hostname))" --format "value(zone)") --format=value"(metadata[CONFIG_FILE_URL])")
		gsutil cp $CONFIG_FILE_URL /data/
		echo "2" > /data/download_status.txt 
		echo "2" > /data/pmdv_annotation_status.txt 
		echo "2" > /data/sniffles_annotation_status.txt 
		chmod a+w -R /data/
		chmod +x $PROJECT_DIR/*/*.sh
		echo -e "SHELL=/bin/bash\nPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin\n*/1 * * * * bash -c /data/scripts/annotate_pmdv_wrapper.sh >> /data/pmdv_stdout.log 2>> /data/pmdv_stderr.log\n*/1 * * * * bash -c /data/scripts/annotate_sniffles_wrapper.sh >> /data/sniffles_stdout.log 2>> /data/sniffles_stderr.log" | crontab -'
