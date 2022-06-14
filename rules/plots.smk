rule plot_final:
	input:
		c="files/annotated/control_variants.annotated.vcf",
		t="files/annotated/test_variants.annotated.vcf",
		configuration="config.yaml",
		script="scripts/final_plots.py",
	output:
		venn="files/figures/venn.png",
		heatmap="files/figures/heatmaps.png",
		location="files/figures/variant_locations.png"
	shell:
		"python {input.script} -c {input.c} -t {input.t} -o2 {output.venn} -o1 {output.heatmap} -o3 {output.location}"
