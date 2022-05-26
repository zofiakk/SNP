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

def get_one_trimmed_read(wildcards):
    # Get the list that comes from the trimming tool.

    list = mapping_input(wildcards)
    if wildcards.pair == "1":
        return list[0]
    elif wildcards.pair == "2":
        if len(list) != 2:
            raise Exception( "Inncorect type of reads decleared" )
        return list[1]

rule bwa_index:
    input:
        config["data"]["reference"],
    output:
        idx=multiext(config["data"]["reference"], ".amb", ".ann", ".bwt", ".pac", ".sa"),
    log:
        "logs/bwa/index.log",
    params:
        algorithm="bwtsw",
    wrapper:
        "v1.4.0/bio/bwa/index"

rule bwa_aln:
    input:
        fastq=get_one_trimmed_read,
        idx=multiext(config["data"]["reference"], ".amb", ".ann", ".bwt", ".pac", ".sa"),
    output:
        "files/sai/{sample}.{pair}.sai",
    params:
        extra="",
    log:
        "logs/bwa/{sample}.{pair}.log",
    threads: 
        config["params"]["bwa"]["threads"]
    wrapper:
        "v1.4.0/bio/bwa/aln"


def sai_files(wildcards):
    if config["settings"]["reads"] == "se":
        # SE reads
        return ["files/sai/{sample}.1.sai".format(
            sample=wildcards.sample)]
    else:
        # PE reads
        return expand("files/sai/{sample}.{pair}.sai",
            pair=[1, 2], sample=wildcards.sample)     

def get_extra(wildcards):
    rg_tags = "\\t".join([ "ID:" + wildcards.sample, "SM:" + wildcards.sample ])
    extra = "-r '@RG\\t" + rg_tags + "' " 
    return extra

rule bwa_bam_pe:
    input:
        fastq=mapping_input,
        sai=sai_files,
        ref=config["data"]["reference"],
        idx=multiext(config["data"]["reference"], ".amb", ".ann", ".bwt", ".pac", ".sa"),
    output:
        "files/mapped/{sample}.unready.bam",
    params:
        index=config["data"]["reference"],
        extra=get_extra,  # optional: Extra parameters for bwa.
        sort="samtools",
        #sort_order="coordinate",
    log:
        "logs/bwa/sai_to_bam/{sample}.log",
    wrapper:
        "v1.4.0/bio/bwa/samxe"


rule bwa_bam_clean:
    input:
        "files/mapped/{sample}.unready.bam"
    output:
        "files/mapped/{sample}.bam"
    log:
        "logs/picard/cleansam/{sample}.log"
    shell:
        "picard CleanSam INPUT={input} OUTPUT={output} &> {log}"  