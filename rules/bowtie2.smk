import os

rule bowtie2_build:
    input:
        ref=config["data"]["reference"],
    output:
        expand(
            os.path.dirname(config["data"]["reference"]) + "/bowtie2_index/" + reference_name + "fa.{format}",
            format=[ "1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2", "rev.2.bt2" ]
        ),
    log:
        "logs/bowtie2/build.log",
    params:
        extra="",  # optional parameters
    threads: 
        config["params"]["bowtie2"]["threads"]
    wrapper:
        "v1.4.0/bio/bowtie2/build"

rule bowtie2:
    input:
        sample=["files/trimmed/B.1.fastq.gz", "files/trimmed/B.2.fastq.gz"],
        idx=expand(
            os.path.dirname(config["data"]["reference"]) + "/bowtie2_index/" + reference_name +  "fa.{format}", format=[ "1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2", "rev.2.bt2" ]),
    output:
        "files/mapped/B.bam",
    log:
        "logs/bowtie2/B.log",
    params:
        index=config["data"]["reference"],
        extra="--rg-id B --rg SM:B ",  # optional parameters
    threads: 
        config["params"]["bowtie2"]["threads"]  # Use at least two threads
    conda:
        "../envs/bowtie2.yaml"  
    wrapper:
        "v1.4.0/bio/bowtie2/align"