rule get_vep_cache:
    output:
        directory("files/vep/cache")
    params:
        species=config["params"]["vep"]["data"]["species"],
        build=config["params"]["vep"]["data"]["build"],
        release=config["params"]["vep"]["data"]["release"]
    log:
        "logs/vep/cache.log",
    conda:
        "../envs/vep_cache.yaml",
    cache: True  # save space and time with between workflow caching (see docs)
    wrapper:
        "v1.4.0/bio/vep/cache"


rule download_vep_plugins:
    output:
        directory("files/vep/plugins")
    params:
        release=config["params"]["vep"]["data"]["release"]
    conda:
        "../envs/vep_cache.yaml",
    wrapper:
        "v1.4.0/bio/vep/plugins"

"""
rule annotate_variants:
    input:
        calls="files/calls/filtered/{groups}.filtered.vcf",  # .vcf, .vcf.gz or .bcf
        cache="files/vep/cache",  # can be omitted if fasta and gff are specified
        plugins="files/vep/plugins",
        # optionally add reference genome fasta
        fasta=config["data"]["reference"],
        fai=config["data"]["reference"] + ".fai", # fasta index

    output:
        calls="files/annotated/{groups}_variants.annotated.vcf",  # .vcf, .vcf.gz or .bcf
        stats="files/annotated/{groups}_variants.html",
    params:
        # Pass a list of plugins to use, see https://www.ensembl.org/info/docs/tools/vep/script/vep_plugins.html
        # Plugin args can be added as well, e.g. via an entry "MyPlugin,1,FOO", see docs.
        plugins=config["params"]["vep"]["data"]["plugins"],
        extra="",  # optional: extra arguments
    log:
        "logs/vep/{groups}_annotate.log",
    conda:
        "../envs/vep_cache.yaml",
    threads: 
        config["params"]["vep"]["annotate"]["threads"]
    wrapper:
        "v1.4.0/bio/vep/annotate"
"""


rule annotate_variants:
    input:
        calls="files/calls/filtered/{groups}.filtered.vcf",  # .vcf, .vcf.gz or .bcf
        cache="files/vep/cache",  # can be omitted if fasta and gff are specified
        plugins="files/vep/plugins",
        # optionally add reference genome fasta
        fasta=config["data"]["reference"],
        fai=config["data"]["reference"] + ".fai", # fasta index
    output:
        calls="files/annotated/{groups}_variants.annotated.vcf",  # .vcf, .vcf.gz or .bcf
        stats="files/annotated/{groups}_variants.html",
        warningf="files/vep/{groups}_annotate_warnings.txt",
    params:
        # Pass a list of plugins to use, see https://www.ensembl.org/info/docs/tools/vep/script/vep_plugins.html
        # Plugin args can be added as well, e.g. via an entry "MyPlugin,1,FOO", see docs.
        plugins=["LoFtool"],
        extra="",  # optional: extra arguments
    log:
        "logs/vep/{groups}_annotate.log",
    conda:
        "../envs/vep_cache.yaml",
    threads: 
        config["params"]["vep"]["annotate"]["threads"]
    script:
        "../scripts/vep-wrapper.py"
    #wrapper:
        #"v1.4.0/bio/vep/annotate"


        