
rule freebayes:
    input:
        bam = "DNA_bam/{sample}-ready.bam",
        bai = "DNA_bam/{sample}-ready.bam.bai",
        ref = "/data/ref_genomes/hg19/bwa/BWA_0.7.10_refseq/hg19.with.mt.fasta",
        bed = "DATA/TST500C_manifest.bed"
    output:
        temp("freebayes/{sample}.freebayes.unsort.vcf")  # either .vcf or .bcf
    log:
        "logs/variantCalling/freebayes/{sample}.log"
    #singularity:
    #    "/projects/wp2/nobackup/Twist_Myeloid/Containers/freebayes-1.3.1-0.simg"
    params:
        extra = " --min-alternate-fraction 0.01 --allele-balance-priors-off --pooled-discrete --pooled-continuous --report-genotype-likelihood-max --genotype-qualities --strict-vcf --no-partial-observations ",
        chunksize = 100000  # reference genome chunk size for parallelization (default: 100000)
    #threads: 1
    shell:
        "(singularity exec -B /data -B /projects /projects/wp2/nobackup/Twist_Myeloid/Containers/freebayes-1.3.1-0.simg freebayes {params.extra} -t {input.bed} -f {input.ref} {input.bam} |"
        " singularity exec /projects/wp2/nobackup/Twist_Myeloid/Containers/bcftools-1.9--8.simg bcftools filter -i 'ALT=\"<*>\" || QUAL > 5' |"
        " awk -F$'\t' -v OFS='\t' '{{if ($0 !~ /^#/) gsub(/[KMRYSWBVHDXkmryswbvhdx]/, \"N\", $4) }} {{print}}' > {output}) &> {log}"


rule sortFreebayes:
    input:
        "freebayes/{sample}.freebayes.unsort.vcf"
    output:
        #temp("freebayes/{sample}.freebayes.fixAF.vcf")
        "freebayes/{sample}.freebayes.fixAF.vcf"
    singularity:
        "/projects/wp2/nobackup/Twist_Myeloid/Containers/bcftools-1.9--8.simg"
    log:
        "logs/variantCalling/freebayes/{sample}.sort.log"
    shell:
        "(bcftools sort -o {output} -O v {input}) &> {log}"


#| bcftools view  -a - | /sw/pipelines/bcbio-nextgen/1.0.5/anaconda/bin/py -x 'bcbio.variation.freebayes.remove_missingalt(x)' | vcfallelicprimitives -t DECOMPOSED --keep-geno | v
#cffixup - | vcfstreamsort | vt normalize -n -r /data/ref_genomes/bcbio-nextgen/sam/hg19.with.mt.fasta -q - | vcfuniqalleles | vt uniq - 2> /dev/null | bgzip -c > /beegfs-scratch/wp1/nobackup/ngs/
#klinik/analys/2020/20200818_HN_GL/bcbiotx/tmpx39l5_/20-1618-chr11_17741307_61197676.vcf.gz
