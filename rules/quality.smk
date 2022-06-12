rule fastqc:
    input:
        unpack(get_sample_files)
    output:
        html="files/fastqc/{sample}.html",
        zip="files/fastqc/{sample}_fastqc.zip" # the suffix _fastqc.zip is necessary for multiqc to find the file. If not using multiqc, you are free to choose an arbitrary filename
    params: "--quiet"
    log:
        "logs/fastqc/{sample}.log"
    threads: 
        config["params"]["fastqc"]["threads"]  
    wrapper:
        "v1.5.0/bio/fastqc"


def get_trimming_reports():
    result=[]
    for sample in config["global"]["samples"]:
        result.append( get_trimming_report( sample ))
    return result

def get_dedup_reports():
    result=[]
    for sample in config["global"]["samples"]:
        result.append( get_dedup_report( sample ))
    return result 

def get_mapp_reports():
    result=[]
    if config["settings"]["mapping"] == "hisat":
        for sample in config["global"]["samples"]:
            result.append( get_hisat_report( sample ))
    elif config["settings"]["mapping"] == "bowtie2":
        for sample in config["global"]["samples"]:
            result.append( get_bowtie_report( sample ))
    return result

rule multiqc:
    input:
        expand(
            "files/fastqc/{sample}.html",
            sample=config["global"]["samples"]
        ),
        get_trimming_reports(),
        get_dedup_reports(),
        get_mapp_reports(),
        #expand("files/annotated/{groups}_variants.html", groups=config["global"]["groups"] 
        #                       ),"""
        directory("files/annotated/"),

    output:
        "files/qc/multiqc.html"
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        "logs/multiqc.log"
    wrapper:
        "v1.5.0/bio/multiqc"