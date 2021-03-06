rule trim_se:
	input:
		unpack(get_sample_files)
	output:
		"files/trimmed/{sample}.fastq.gz"
	params:
		trimmer = config["params"]["trimmomatic"]["se"],
		extra=""
	threads:
		config["params"]["trimmomatic"]["threads"]	
	message:
		"Trimming FASTQ files with Trimmomatic"
	log:
		"logs/trimmomatic/trimmomatic_{sample}.log" 	    
	wrapper:
		"v1.4.0/bio/trimmomatic/se"	

rule trim_pe:
	input:
		unpack(get_sample_files)
	output:
		r1="files/trimmed/{sample}.1.fastq.gz",
		r2="files/trimmed/{sample}.2.fastq.gz",
		r1_unpaired="files/trimmed/{sample}.1.unpaired.fastq.gz",
		r2_unpaired="files/trimmed/{sample}.2.unpaired.fastq.gz"
	params:
		trimmer = config["params"]["trimmomatic"]["pe"]
	threads:
		config["params"]["trimmomatic"]["threads"]
	message:
		"Trimming FASTQ files with Trimmomatic" 
	log:
		"logs/trimmomatic/trimmomatic_{sample}.log"  
	wrapper:
		"v1.4.0/bio/trimmomatic/pe"


def get_trimming_report(sample):
    if config["settings"]["reads"] == "se":
        # se samples
        return "logs/trimmomatic/trimmomatic_" + config["settings"]["reads"] + "_" + sample + ".log"
    elif config["settings"]["reads"] == "pe":
        # paired-end sample
    	return "logs/trimmomatic/trimmomatic_" + config["settings"]["reads"] + "_" + sample + ".log"

