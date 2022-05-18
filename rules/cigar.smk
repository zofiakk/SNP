rule splitncigarreads:
    input:
        bam="files/dedup/{sample}.bam",
        ref=config["data"]["reference"],
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

