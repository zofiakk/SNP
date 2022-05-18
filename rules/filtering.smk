def filter_value(wildcards):
    return {"used-filter": config["params"]["gatk"]["filtering"][wildcards.type] }


rule gatk_filter:
    input:
        vcf="files/calls/{groups}_{type}.vcf",
        ref=config["data"]["reference"],
    output:
        vcf="files/calls/filtered/{groups}_{type}.filtered.vcf",
    log:
        "logs/gatk/filter/{groups}_{type}.log",
    params:
        filters=filter_value,
        extra="",  # optional arguments, see GATK docs
        java_opts="",  # optional
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/gatk/variantfiltration"


samples_grouped_types = {"test": config["global"]["type"], "control": config["global"]["type"]}
print(samples_grouped_types)


def grouped_samples_filtered(wildcards):
    return expand("files/calls/filtered/{groups}_{type}.filtered.vcf", type=samples_grouped_types[wildcards.groups], groups=wildcards.groups)


rule combine_filtered:
    input:
        vcfs=grouped_samples_filtered,
        #vcfs=expand("files/calls/filtered/{wildcards.groups}_{type}.filtered.vcf", type=["snvs", "indels"])
    output:
        "files/calls/filtered/{groups}.filtered.vcf"
    log:
        "logs/picard/mergevcfs/{groups}.log",
    params:
        extra="",
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024,
    wrapper:
        "v1.4.0/bio/picard/mergevcfs"
