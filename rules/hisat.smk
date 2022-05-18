import os

def mapping_input(wildcards):
    if config["settings"]["trim"] == "true":
        if config["settings"]["reads"] == "se":
            # SE reads
            return ["files/trimmed/{sample}.fastq.gz".format(
                sample=wildcards.sample)]
        else:
            # PE reads
            return expand("files/trimmed/{sample}.{pair}.fastq.gz",
                pair=[1, 2], sample=wildcards.sample)   
    elif config["settings"]["trim"] == "false":
        return get_sample_files(wildcards)
    else:
        raise Exception("Unknown setting in trim configuration: " + config["settings"]["trim"])

rule hisat2_index:
    input:
        fasta = config["data"]["reference"]
    output:
        directory(os.path.dirname(config["data"]["reference"]) + "/index_hisat")
    params:
        prefix = os.path.dirname(config["data"]["reference"]) + "/index_hisat/"
    log:
        "logs/hisat2/hisat2_index.log"
    threads:
        config["params"]["hisat"]["threads"]
    wrapper:
        "v1.4.0/bio/hisat2/index"

rule hisat2_align:
    input:
      reads=mapping_input,
      indx=expand(os.path.dirname(config["data"]["reference"]) + "/index_hisat/"+".{ix}.ht2", ix=range(1, 9))
    output:
      "files/mapped/{sample}.bam"
    log:
        "logs/hisat2/hisat2_align_{sample}.log"
    params:
      extra="--rg ID:{sample} --rg SM:{sample}",
      idx=directory(os.path.dirname(config["data"]["reference"]) + "/index_hisat/")
    threads: 
        config["params"]["hisat"]["threads"]
    wrapper:
      "v1.4.0/bio/hisat2/align"     

