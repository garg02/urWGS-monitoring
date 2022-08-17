#!/bin/bash

gcloud compute instances create $1 \
  --zone us-west1-a \
  --source-instance-template guppy-mm2-template \
	--create-disk=boot=yes,image=guppy-mm2-image-v1,size=100GB \
	--scopes=storage-full,compute-rw,logging-write \
	--local-ssd=interface=NVME \
	--local-ssd=interface=NVME \
	--local-ssd=interface=NVME \
  --metadata FC=$2,CONFIG_FILE_URL=$3,startup-script='#!/bin/bash
		nvidia-smi -pm 1
		git clone https://github.com/gsneha26/urWGS.git 
		bash -c ./urWGS/setup/mount_ssd_nvme.sh
		mv urWGS /data/
		export PROJECT_DIR=/data/urWGS
    gsutil -o "GSUtil:parallel_thread_count=1" -o "GSUtil:sliced_object_download_max_components=8" cp gs://ur_wgs_test_data/GRCh37.mmi /data/
		CONFIG_FILE_URL=$(gcloud compute instances describe $(hostname) --zone=$(gcloud compute instances list --filter="name=($(hostname))" --format "value(zone)") --format=value"(metadata[CONFIG_FILE_URL])")
		gsutil cp $CONFIG_FILE_URL /data/sample.config
		echo "2" > /data/postprocess_status.txt
		echo "2" > /data/basecalling_status.txt
		echo "2" > /data/upload_status.txt
		chmod a+w -R /data/
		chmod +x $PROJECT_DIR/*/*.sh
		echo "PROJECT_ID=$(gcloud info --format="value(config.project)")" > ~/batch_info.txt
		echo "INSTANCE_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/id -H Metadata-Flavor:Google)" >> ~/batch_info.txt
		echo "ZONE_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H Metadata-Flavor:Google | rev | cut -d/ -f1 | rev)" >> ~/batch_info.txt
		echo "cpu_batch_num=$(date +%s)" >> ~/batch_info.txt
		echo "gpu_batch_num=$(date +%s)" >> ~/batch_info.txt
    $PROJECT_DIR/guppy_mm2/generate_scripts.sh
		echo -e "SHELL=/bin/bash\nPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin\nPROJECT_DIR=$PROJECT_DIR\n* * * * * bash -c ./custom-metric-reporter-gcp/metrics -f ~/batch_info.txt >> batch_metrics_stdout.log 2>> batch_metrics_stderr.log\n2-26/3\005432-56/3 * * * * bash -c $PROJECT_DIR/guppy_mm2/run_basecalling_wrapper.sh >> /data/logs/basecall_stdout.log 2>> /data/logs/basecall_stderr.log\n*/3 * * * * bash -c $PROJECT_DIR/guppy_mm2/run_alignment_wrapper.sh >> /data/logs/align_stdout.log 2>> /data/logs/align_stderr.log\n*/5 * * * * bash -c $PROJECT_DIR/guppy_mm2/upload_log.sh" | crontab -'
