rule visualize:
	input:
		snps="files/tables/{groups}_snvs.raw.table",
		indels="files/tables/{groups}_indels.raw.table",
		configuration="config.yaml",
		script="scripts/visualize.py"
	output:
		"files/figures/{groups}_used_filters.png"
	shell:
		"python {input.script} -s {input.snps} -i {input.indels} -c {input.configuration} -o {output}"