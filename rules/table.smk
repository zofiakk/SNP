#from snakemake.shell import shell
#log = snakemake.log_fmt_shell(stdout=True, stderr=True)

rule variantsToTable:
	input:
		reference=config["data"]["reference"],
		vcf="files/calls/{groups}_{vartype}.vcf",
	output:
		table="files/tables/{groups}_{vartype}.raw.table",
	threads:
		config["params"]["gatk"]["table"]["threads"]

	log:
		"logs/gatk/table/{groups}_{vartype}.log",
	shell:
		"(gatk VariantsToTable \
			-R {input.reference} \
			-V {input.vcf} \
			-F CHROM -F POS -F QUAL -F QD -F DP -F MQ -F MQRankSum -F FS -F ReadPosRankSum -F SOR \
			-O {output.table} ) 2> {log}"