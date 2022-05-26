def get_files(wildcards):
    # Stop at the snakemake checkpoint first to ensure that the fai file is available.
    return checkpoints.reference_faidx.get().output[0], checkpoints.create_dict.get().output[0]

rule splitncigarreads:
    input:
        bam="files/dedup/{sample}.bam",
        ref=config["data"]["reference"],
        files=get_files,
    output:
        "files/dedup/{sample}.split.bam",
    log:
        "logs/gatk/splitNCIGARreads/{sample}.log",
    params:
        extra="",  # optional
        java_opts="",  # optional
    threads:
        config["params"]["gatk"]["splitNcigar"]["threads"]
    resources:
        mem_mb=1024,
    wrapper:
        "v1.5.0/bio/gatk/splitncigarreads"

