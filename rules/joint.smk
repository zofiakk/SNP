
rule bgzip:
    input:
        "files/calls/filtered/{groups}.filtered.vcf",
    output:
        "files/joint/{groups}.vcf.gz",
    params:
        extra="", # optional
    threads: 
    	config["params"]["bgzip"]["threads"]
    log:
        "logs/bgzip/{groups}.log",
    wrapper:
        "v1.5.0/bio/bgzip"



rule bcftools_index:
    input:
        "files/joint/{groups}.vcf.gz",
    output:
        "files/joint/{groups}.vcf.gz.csi",
    params:
        extra=""  # optional parameters for bcftools index
    wrapper:
        "v1.5.0/bio/bcftools/index"



rule isec:
	input:
		file1 = "files/joint/control.vcf.gz",
		file2 = "files/joint/test.vcf.gz",
		tbx1 = "files/joint/control.vcf.gz.csi",
		tbx2 = "files/joint/test.vcf.gz.csi",
	output:
		directory("files/joint/isec_output"),
	shell:
		"bcftools isec {input.file1} {input.file2} -p {output} -Ov "


