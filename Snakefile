import os
from pathlib import Path
from os import listdir
from os.path import isfile, join

# =================================================================================================
#     Setup
# =================================================================================================

# Include config file
configfile: "config.yaml"
# Można potem dodać validate ale to jak już się skończy

# Check if reference is compressed and if it is get just the base name
if config["data"]["reference"].endswith(".gz"):
    config["data"]["reference"] = os.path.splitext(config["data"]["reference"])[0]


reference_name = config["data"]["reference"].split("/")[-1]
reference_name = reference_name.split(".")[0]

# Check if the reference is in supported file
if not config["data"]["reference"].endswith(('.fa', '.fasta')):
    raise Exception(
        "Reference genome file is not in a supported file. " + 
        "Please make sure that file given as reference is either .fasta or .fa"
    )

# Check if path to samples is correctly speciefied
if not config["data"]["samples"].endswith("/"):
    raise Exception(
        "There seems to be something wrong with path to samples folder " + 
        "Please make sure that it ends with '/' "
    )    

allfiles = [f for f in listdir(config["data"]["samples"]) if isfile(join(config["data"]["samples"], f)) and f.endswith(('.fastq.gz', '.fastq'))]
sample_names = [i.split(".")[0] for i in allfiles]
if config["settings"]["reads"] == "pe":
    sample_names = [i.split("_")[0] for i in sample_names]

config["global"] = {}
config["global"]["samples"] = set(sample_names)

# Reading file with control group into a list
with open(config["data"]["control"]) as file:
    control = file.readlines()
    control = [line.rstrip() for line in control]
    control = list(set(control))
config["global"]["controls"] = control


tests = list(set([x for x in sample_names if x not in control]))
config["global"]["tests"] = tests

config["global"]["type"] = ["snvs", "indels"]

# Setting wildcard constraints- only samples given in a folder
wildcard_constraints:
    sample="|".join(config["global"]["samples"]),
    type="snvs|indels",
    groups="control|test",


# Get the samples as dictionary
def get_sample_files(wildcards):
    all_files = listdir(config["data"]["samples"])
    curr_files = [i for i in all_files if i.startswith(wildcards.sample)]
    if len(curr_files) == 2 and config["settings"]["reads"] == "pe":
        if config["settings"]["trim"] == "true":
            print(config["data"]["samples"] + curr_files[0])
            return {"r1": config["data"]["samples"] + curr_files[0], "r2": config["data"]["samples"] + curr_files[1]}
        else:
            return [config["data"]["samples"] + curr_files[0], config["data"]["samples"] + curr_files[1]]
    elif len(curr_files) == 1 and config["settings"]["reads"] == "se":
        if config["settings"]["trim"] == "true":
            return {"r1": config["data"]["samples"] + curr_files[0]}
        else:
            return [config["data"]["samples"] + curr_files[0]]
    else:
        raise Exception(
        "Please make sure that all the data is pe or se and its correctly declared in config file" 
    )  


Path("./files/").mkdir(exist_ok=True)



# =================================================================================================
#     Rules
# =================================================================================================

# Trimming
if config["settings"]["trim"] == "true":
    include: "rules/trim.smk"


# Mapping
if config["settings"]["mapping"] == "hisat":
    include: "rules/hisat.smk"
elif  config["settings"]["mapping"] == "bwa":
    include: "rules/bwa.smk"
elif config["settings"]["mapping"] == "bowtie2":
    include: "rules/bowtie2.smk"   
else:
    raise Exception("Unknown mapping-tool: " + config["settings"]["mapping"])    

# Duplicates
include: "rules/duplicates.smk"

# SplitNCigarReads
if config["settings"]["type"] == "rna":
    print("cigar")
    include: "rules/cigar.smk"
else:
    raise Exception("Unknown type of sequenced data: " + config["settings"]["type"])    

# Haplotype
include: "rules/haplotype.smk"

# VariantsToTable
if config["settings"]["visualize_filters"] == "true":
    include: "rules/table.smk"
    include: "rules/visualize.smk"


# Filtering
include: "rules/filtering.smk"

# Annotattion
include: "rules/annotate.smk"


results = "data/results/"

rule all:
    input:
        "files/calls/filtered/control.filtered.vcf",
        "files/tables/control_snvs.raw.table",
        "files/tables/control_indels.raw.table",
        "files/calls/filtered/test.filtered.vcf",
        "files/tables/test_snvs.raw.table",
        "files/tables/test_indels.raw.table",
        "files/figures/test_used_filters.png",
        "files/figures/control_used_filters.png"
        #"files/calls/control_snvs.vcf",
        #"files/calls/test_snvs.vcf"


