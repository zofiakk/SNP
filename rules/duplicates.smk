rule sort_bam:
    input:
        "files/mapped/{sample}.bam",
    output:
        "files/mapped/{sample}.sorted.bam",
    log:
        "logs/picard/sort_sam/{sample}.log",
    params:
        sort_order="coordinate",
        extra=" ",  # optional: Extra arguments for picard.
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/picard/sortsam"

rule filter_mapped_reads:
    input:
        "files/mapped/{sample}.sorted.bam"
    output:
        "files/mapped/{sample}.sorted.filtered.bam"
    params:
        "-q 1 -b"
    wrapper:
        "0.72.0/bio/samtools/view"


rule mark_duplicates:
    input:
        "files/mapped/{sample}.sorted.filtered.bam",
    # optional to specify a list of BAMs; this has the same effect
    # of marking duplicates on separate read groups for a sample
    # and then merging
    output:
        bam="files/dedup/{sample}.bam",
        metrics="files/dedup/{sample}.metrics.txt",
    log:
        "logs/picard/dedup/{sample}.log",
    params:
        extra="--REMOVE_DUPLICATES true --CREATE_INDEX true",
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/picard/markduplicates"
       

checkpoint reference_faidx:
    input:
        config["data"]["reference"]
    output:
        config["data"]["reference"] + ".fai"
    log:
        "logs/" + reference_name + ".samtools_faidx.log"
    params:
        "" 
    wrapper:
        "v1.4.0/bio/samtools/faidx"

checkpoint create_dict:
    input:
        config["data"]["reference"],
    output:
        '.'.join(config["data"]["reference"].split(".")[:-1]) + ".dict",
    log:
        "logs/picard/create_dict.log",
    params:
        extra="",  # optional: extra arguments for picard.
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/picard/createsequencedictionary"


def get_dedup_report(sample):
    return "files/dedup/" + sample + ".metrics.txt"

