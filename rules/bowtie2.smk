import os

rule bowtie2_build:
    input:
        ref=config["data"]["reference"],
    output:
        expand(
            os.path.dirname(config["data"]["reference"]) + "/bowtie2_index/" + reference_name + ".fa.{format}",
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


def get_extra_bowtie(wildcards):
    extra = r"--rg-id \"" + wildcards.sample + r"\""
    rg_tags = [ "ID:" + wildcards.sample, "SM:" + wildcards.sample ]
    for tag in rg_tags:
        extra += r" --rg \"" + tag + r"\""
    return extra


rule bowtie2:
    input:
        sample=mapping_input,
        idx=expand(
            os.path.dirname(config["data"]["reference"]) + "/bowtie2_index/" + reference_name +  ".fa.{format}", format=[ "1.bt2", "2.bt2", "3.bt2", "4.bt2", "rev.1.bt2", "rev.2.bt2" ]),
    output:
        "files/mapped/{sample}.bam",
    log:
        "logs/bowtie2/{sample}.log",
    params:
        index=config["data"]["reference"] + "/bowtie2_index/" + reference_name ,
        extra=get_extra_bowtie,  # optional parameters
    threads: 
        config["params"]["bowtie2"]["threads"]  # Use at least two threads
    conda:
        "../envs/bowtie2.yaml"  
    wrapper:
        "v1.4.0/bio/bowtie2/align"

def get_hisat_report(sample):
    return "logs/bowtie2/" + sample + ".log"