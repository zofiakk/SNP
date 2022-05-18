def get_files(wildcards):
    # Stop at the snakemake checkpoint first to ensure that the fai file is available.
    return checkpoints.reference_faidx.get().output[0], checkpoints.create_dict.get().output[0]

def input_files(wildcards):
    if config["settings"]["type"] == "dna":
            print("DNA")
            return "files/dedup/{sample}.bam",
    elif config["settings"]["type"] == "rna":
        print("rna")
        return "files/dedup/{sample}.split.bam",
    else:
        raise Exception("Unknown type of sequenced data: " + config["settings"]["type"])

rule haplotype_caller:
    input:
        bam=input_files,
        ref=config["data"]["reference"],
        files=get_files
    output:
        gvcf="files/calls/{sample}.g.vcf.gz",
    log:
        "logs/gatk/haplotypecaller/{sample}.log",
    params:
        extra="",
        java_opts="", 
    threads: 
        2
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/gatk/haplotypecaller"


def get_vcfs(wildcards):
    return expand("files/calls/{sample}.g.vcf.gz",
            sample=config["global"]["samples"])

samples_grouped = {"test": config["global"]["tests"], "control": config["global"]["controls"]}
print(samples_grouped)


def grouped_samples(wildcards):
    return expand("files/calls/{sample}.g.vcf.gz", sample=samples_grouped[wildcards.groups])


rule combine_gvcfs:
    input:
        gvcfs=grouped_samples,
        ref=config["data"]["reference"]
    output:
        gvcf="files/calls/{groups}.g.vcf.gz"
    log:
        "logs/gatk/combine/{groups}.log",
    params:
        extra="",  # optional
        java_opts="",  # optional
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/gatk/combinegvcfs"


"""rule combine_gvcfs:
    input:
        gvcfs=get_vcfs,
        ref=config["data"]["reference"]
    output:
        gvcf="files/calls/all.g.vcf.gz"
    log:
        "logs/gatk/combine/combinegvcfs.log",
    params:
        extra="",  # optional
        java_opts="",  # optional
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/gatk/combinegvcfs"""


rule genotype_gvcfs:
    input:
        gvcf="files/calls/{groups}.g.vcf.gz",  # combined gvcf over multiple samples
    # N.B. gvcf or genomicsdb must be specified
    # in the latter case, this is a GenomicsDB data store
        ref=config["data"]["reference"]
    output:
        vcf="files/calls/{groups}.vcf",
    log:
        "logs/gatk/genotypegvcfs/{groups}.log"
    params:
        extra="",  # optional
        java_opts="", # optional
    resources:
        mem_mb=1024
    wrapper:
        "v1.4.0/bio/gatk/genotypegvcfs"


def type_to_include(wildcards):
     return "--select-type-to-include {}".format( "SNP" if wildcards.vartype == "snvs" else "INDEL")

rule select_variants:
    input:
        vcf="files/calls/{groups}.vcf",
        ref=config["data"]["reference"],
    output:
        vcf="files/calls/{groups}_{vartype}.vcf",
    log:
        "logs/gatk/select/{groups}_{vartype}.log",
    params:
        extra=type_to_include,  # optional filter arguments, see GATK docs
        java_opts="",  # optional
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/gatk/selectvariants"