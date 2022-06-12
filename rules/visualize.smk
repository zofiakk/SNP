rule visualize:
	input:
		s_c="files/tables/control_snvs.raw.table",
		i_c="files/tables/control_indels.raw.table",
		s_t="files/tables/test_snvs.raw.table",
		i_t="files/tables/test_indels.raw.table",
		configuration="config.yaml",
		script="scripts/visualize.py",
	output:
		"files/figures/used_filters.png",
	shell:
		"python {input.script} -sc {input.s_c} -st {input.s_t} -ic {input.i_c} -it {input.i_t} -c {input.configuration} -o {output}"