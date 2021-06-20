# Ultra-Rapid Whole Genome Sequencing pipeline

### host instance
* Start an instance with Ubuntu18.04 and SSD with NVME interface:
```
gcloud compute instances create host-instance1 \
        --zone us-west1-a \
	--machine-type='n1-standard-16' \
	--create-disk=boot=yes,image-project='ubuntu-os-cloud',image='ubuntu-1804-bionic-v20210604',size=100GB \
        --local-ssd=interface=NVME \
        --local-ssd=interface=NVME
```
* Log into the instance and mount the local ssd
```
sudo apt update && sudo apt -y install mdadm --no-install-recommends
DEVICES=$(ls  /dev/nvme0n*)
sudo mdadm --create /dev/md0 --level=0 --raid-devices=2 $DEVICES
sudo mkfs.ext4 -F /dev/md0
sudo mkdir -p /data
sudo mount /dev/md0 /data
sudo chmod a+w /data
```
* Install pre-requisites:
```
sudo apt-get update
sudo apt-get --yes install git parallel rsync
```
* Google Cloud SDK ([Instructions for a non-GCP instance](https://cloud.google.com/sdk/docs/install))
* urWGS repository
```
git clone https://github.com/gsneha26/urWGS-private
cd urWGS-private/
export PROJECT_DIR=$(pwd)
```
* Start a simulation for a giveb duration
```
$PROJECT_DIR/prom_simulation/simulate_prom.sh simulation_duration_in_seconds
```
## Base calling and Alignment
### Software:
* Guppy v4.2.2 (Commercial software from Oxford Nanopore Technologies)
* Minimap2 [v2.17-r974](https://github.com/lh3/minimap2/commit/2da649d1d724561d4c2bbe1be9123e2b61bc0029)
* samtools [v1.11](https://github.com/samtools/samtools/commit/d58fc8a16729f25407da6729c440a51140396f4c)

### Instance type:
* Custom N1 instance
* 48 vCPUs
* 200 GB RAM
* 4 x NVIDIA Tesla V100
* 3 x Local SSD Scratch Disk

## Small Variant Calling
### Software:
* PEPPER (Docker - kishwars/pepper_deepvariant:test-v0.5)
* Margin (Docker - kishwars/pepper_deepvariant:test-v0.5)
* Google DeepVariant (Docker)
  * none model (Docker - kishwars/pepper_deepvariant:test-v0.5)
  * rows model (Docker - kishwars/pepper_deepvariant:test-v0.5-rows)
* samtools [v1.11](https://github.com/samtools/samtools/commit/d58fc8a16729f25407da6729c440a51140396f4c)

### Instance type:
* Standard N1 instance
* 96 vCPUs
* 360 GB RAM
* 4 x NVIDIA Tesla P100
* 1 x Local SSD Scratch Disk

## Structural Variant Calling
### Software:
* Sniffles [v1.0.12](https://github.com/fritzsedlazeck/Sniffles/commit/0f9a068ecee84fff862c12e581693be273ccf89e)

### Instance type:
* Standard N1 instance
* 96 vCPUs
* 360 GB RAM
* 1 x Local SSD Scratch Disk

## Variant Call Annotation
### Software:
* bctools [v1.11](https://github.com/samtools/bcftools/commit/df43fd4781298e961efc951ba33fc4cdcc165a19)

### Instance type:
* Standard N1 instance
* 64 vCPUs
* 240 GB RAM
* 1 x Local SSD Scratch Disk
