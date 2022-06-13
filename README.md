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

## Pipeline overview

### Input
* Config file
* Snakefile
* Reference genome fasta file
* Sequencing (DNA or RNA-seq) fasta files (single-end or pair-end)

### Functions and tools used
* Quality control
  * [MultiQC](https://multiqc.info)
* Read trimming
  * [trimmomatic]([actual URL to navigate](http://www.usadellab.org/cms/index.php?page=trimmomatic))
* Read mapping
  * [BWA](http://bio-bwa.sourceforge.net/bwa.shtml)
  * [BOWTIE2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml)
  * [HISAT2](http://daehwankimlab.github.io/hisat2/)
* Marking of duplicates
  * [MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates)
* Modification of reads
  * [SplitNCigarReads](https://gatk.broadinstitute.org/hc/en-us/articles/360036858811-SplitNCigarReads)
* Searching for variants
  * [HaplotypeCaller](https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller)
  * [SelectVariants](https://gatk.broadinstitute.org/hc/en-us/articles/360037055952-SelectVariants)
* Filtering and evaluation
  * [VariantFiltration](https://gatk.broadinstitute.org/hc/en-us/articles/360036834871-VariantFiltration)
  * [VEP](https://www.ensembl.org/info/docs/tools/vep/index.html)
  * [Custom scripts creating summary charts](https://github.com/zofiakk/SNP/tree/main/scripts)

## Output
* Variant calls (vcf file)
* MultiQC report (includes summaries of the input data after data pre-processing)
* Plots visualizing the found variants and comparing the results for the test and control group 
* 
Intermediate output files such as bam files are also kept. In addition to the above tools, there are other tools used to combine the steps. If you are interested in the details, please see the snakemake [rules](https://github.com/zofiakk/SNP/tree/main/rules) for each step.
