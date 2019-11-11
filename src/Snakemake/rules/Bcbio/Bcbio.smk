

rule create_config:
    output:
        conf = "config.yaml"
    params:
        #samples = expand(config["DNA_Samples"])
        samples = [s for s in config["DNA_Samples"]]
    run:
        from datetime import date
        conf = open("config.yaml", "w")
        conf.write("details:\n")
        for s in params.samples :
            conf.write("- algorithm:\n")
            conf.write("    aligner: bwa\n")
            conf.write("    mark_duplicates: true\n")
            conf.write("    recalibrate: gatk\n")
            conf.write("    realign: gatk\n")
            conf.write("    variantcaller: [mutect2, vardict, varscan, freebayes]\n")
            conf.write("    indelcaller: pindel\n")
            conf.write("    ensemble:\n")
            conf.write("      numpass: 1\n")
            conf.write("    platform: illumina\n")
            conf.write("    quality_format: Standard\n")
            conf.write("    variant_regions: /data/illumina/TSO500/runfiles/TST500C_manifest.bed\n")
            conf.write("    min_allele_fraction: 1\n")
            conf.write("    umi_type: fastq_name\n")
            conf.write("  analysis: variant2\n")
            conf.write("  description: " + s + "\n")
            conf.write("  files:\n")
            conf.write("  - fastq/DNA/" + s + "_R1.fastq.gz\n")
            conf.write("  - fastq/DNA/" + s + "_R2.fastq.gz\n")
            conf.write("  genome_build: hg19_consensus\n")
            conf.write("  metadata:\n")
            conf.write("    phenotype: tumor\n")
        conf.write("_date: '" + date.today().strftime("%Y%m%d") + "'\n")
        conf.write("fc_name: TSO500\n")
        conf.write("upload:\n")
        conf.write("  dir: ./final\n")
        conf.close()


bcbio_cores = len(config["DNA_Samples"]) * 16
if bcbio_cores > 64 :
    bcbio_cores = 64

rule run_bcbio:
    input:
        merged_fastq_R1 = ["fastq/DNA/" + s + "_R1.fastq.gz" for s in config["DNA_Samples"]],
        merged_fastq_R2 = ["fastq/DNA/" + s + "_R2.fastq.gz" for s in config["DNA_Samples"]],
        config = "config.yaml",
        bcbio_moriarty_config = "DATA/bcbio_system_Moriarty.yaml"
    output:
        bams = ["final/" + s + "/" + s + "-ready.bam" for s in config["DNA_Samples"]],
        bais = ["final/" + s + "/" + s + "-ready.bam.bai" for s in config["DNA_Samples"]],
        vcf = ["final/" + s + "/" + s + "-ensemble.vcf.gz" for s in config["DNA_Samples"]]
    run:
        import subprocess
        subprocess.call("module load bcbio-nextgen/1.0.5; module load slurm; bcbio_nextgen.py {input.bcbio_moriarty_config} {input.config} -t ipython -s slurm -q core -n " + str(bcbio_cores) + " -r \"time=48:00:00\" -r \"job-name=wp1_bcbio-nextgen\" -r \"export=JAVA_HOME,BCBIO_JAVA_HOME\" -r \"account=wp1\" --timeout 99999", shell= True)
