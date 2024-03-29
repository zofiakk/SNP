# SNP
Snakemake pipeline for SNP and SNV detection starting from raw fastq files

## Authors
 Zofia Kochańska, Julia Smolik, Jakub Białecki, Małgorzata Kukiełka

## About
This program was developed as part of a project on the subject Architecture of large bioinformatics projects at the Faculty of Mathematics, Informatics and Mechanics, University of Warsaw under the tutelage of [Łukasz Kozłowski, PhD](https://github.com/lukasz-kozlowski). It is a Snakemake pipeline for SNP detection using tools from GATK. The only argument that the user will need to do is provide a config file specifying parameters (e.g., whether the data comes from single-end (SE) or pair-end (PE) sequencing as well as whether the input files are from DNA or RNA sequencing) and locations of raw FASTQ (.GZ) files.

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

### Data used
* Pair-end sequencing data from RNA-seq (SRA database, under BioProject accession number PRJNA508203)
* *Ovis aries* genome (ENV database, accession number GCA_000298735.1)

### Functions and tools used
* Read trimming
  * [trimmomatic](http://www.usadellab.org/cms/index.php?page=trimmomatic)
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
* Quality control
  * [MultiQC](https://multiqc.info)

## Output
* Variant calls (vcf file)
* MultiQC report (includes summaries of the input data after data pre-processing)
* Plots visualizing the found variants (and the filters used on them) and comparing the results for the test and control group 

Intermediate output files such as bam files are also kept. In addition to the above tools, there are other tools used to combine the steps. If you are interested in the details, please see the snakemake [rules](https://github.com/zofiakk/SNP/tree/main/rules) for each step.

## Documentation

* [PDF version](https://github.com/zofiakk/SNP/blob/main/documentation.pdf)
* [Online version](https://students.mimuw.edu.pl/~js406162/documentation/index.html)

