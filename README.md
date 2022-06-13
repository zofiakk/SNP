# SNP
Snakemake pipeline for SNP and SNV detection starting from raw fastq files

## Members
Julia Smolik, Jakub Białecki, Małgorzata Kukiełka,  Zofia Kochańska

## About
In our project we will try to create a Snakemake pipeline for detection of SNPs using tools from GATK. 
The only thing that the user will need to do is provide a config file specifying parameters (e.g. wether the data is a SE or PE) and locations of raw FASTQ(.GZ) files. 

## Getting started

The user must have Anaconda installed. To run the program, the user does not need to install the necessary packages themselves. It is enough to import the environment included by the authors. In this environment there are libraries necessary to run the program. To install the environment in the console you must type:

```
$ conda env create -f environment.yml

```

The program will load the raw DNA/RNA-seq files, perform pre-processing on them to eventually identify the SNPs and SNVs found in them. The program also performs annotation of the variants found and produces plots summarizing the results obtained.

## Tutorial
### How to call the program

In order to run the program, you have to be in the directory where the Snakefile script is located and enter the following command in the console:

```
$ snakemake -c [number] --use-conda

```
where [number] is an integer indicating how many threads to use.

