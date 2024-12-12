rule run_sniffles:
    input:
        "results/{ref}/mapping/{sample}/{sample}-{ref}.sorted.bam"
    output:
        "results/{ref}/variant-calling/{sample}/sniffles/{sample}-{ref}-sniffles.vcf.gz"
    conda:
        "../envs/variant-calling.yaml"
    resources:
        mem_mb = 5000,
        walltime = "01:00:00"
    threads: 24
    shell:
        "sniffles --input {input} --allow-overwrite --sample-id {wildcards.sample}-{wildcards.ref} --vcf {output}"

rule gfa_to_fasta:
    input:
        "results/assemblies/{sample}/sample.asm.{trio}.{hap}.p_ctg.gfa"
    output:
        "results/{ref}/variant-calling/{sample}/pav-{trio}/data/input/sample.asm.{trio}.{hap}.p_ctg.fa"
    shell:
        "awk '/^S/{{print \">\"$2_{wildcards.sample}_{wildcards.hap}; printf \"%s\", $3 | \"fold -w 80\"; close(\"fold -w 80\"); print \"\"}}' {input} > {output}"

rule prepare_assembly_table:
    input:
        h1 = "results/{ref}/variant-calling/{sample}/pav-{trio}/data/input/sample.asm.{trio}.hap1.p_ctg.fa",
        h2 = "results/{ref}/variant-calling/{sample}/pav-{trio}/data/input/sample.asm.{trio}.hap2.p_ctg.fa"
    output:
        tsv = "results/{ref}/variant-calling/{sample}/pav-{trio}/assemblies.tsv"
    params:
        h1_in = "data/input/sample.asm.dip.hap1.p_ctg.fa",
        h2_in = "data/input/sample.asm.dip.hap2.p_ctg.fa"
    shell:
        """
        echo \"NAME\tHAP1\tHAP2\" > {output}
        echo \"{wildcards.sample}\t{params.h1_in}\t{params.h2_in}\" >> {output}
        """

rule prepare_pav_config:
    input:
        fasta = lambda wildcards: config["references"][wildcards.ref]
    output:
        json = "results/{ref}/variant-calling/{sample}/{folder}/config.json"
    run:
        ref = input.fasta
        with open(output.json, 'w') as outfile:
            outfile.write("{\n")
            outfile.write("\t\"reference\": \"{}\"\n".format(ref))
            outfile.write("}\n")

rule run_pav:
    input:
        tsv = "results/{ref}/variant-calling/{sample}/{folder}/assemblies.tsv",
        pav_config = "results/{ref}/variant-calling/{sample}/{folder}/config.json"
    output:
        complete = "results/{ref}/variant-calling/{sample}/{folder}/run.complete",
        vcf = "results/{ref}/variant-calling/{sample}/{folder}/pav_{sample}.vcf.gz"
    params:
        wdir = "results/{ref}/variant-calling/{sample}/{folder}/"
    log:
        "results/{ref}/variant-calling/{sample}/{folder}/pav.log"
    benchmark:
        "results/{ref}/variant-calling/{sample}/{folder}/pav.benchmark"
    wildcard_constraints:
        folder = "|".join(["pav-dip", "pav-bp"])
    resources:
        mem_mb = 200000,
        walltime = "18:00:00"
    threads: 24
    singularity:
        "workflow/container/pav_2.3.4.sif"
    shell:
        """
        snakemake --verbose --jobs {threads} -d {params.wdir} -s /opt/pav/Snakefile --rerun-incomplete --restart-times 0 --notemp &> {log} && touch {output.complete}
        """

rule change_pav_name:
    input:
        "results/{ref}/variant-calling/{sample}/{folder}/pav_{sample}.vcf.gz"
    output:
        "results/{ref}/variant-calling/{sample}/{folder}/{sample}-{ref}-pav.vcf.gz"
    shell:
        "mv {input} {output}"

rule filter_by_type:
    input:
        "results/{ref}/variant-calling/{sample}/{folder}/{sample}-{ref}-{caller}.vcf.gz"
    output:
        svs = "results/{ref}/variant-calling/{sample}/{folder}/svs_{sample}-{ref}-{caller}.vcf.gz",
        indels = temp("results/{ref}/variant-calling/{sample}/{folder}/indels_{sample}-{ref}-{caller}.vcf"),
        snps = temp("results/{ref}/variant-calling/{sample}/{folder}/snps_{sample}-{ref}-{caller}.vcf")
    params:
        unzip = "results/{ref}/variant-calling/{sample}/{folder}/svs_{sample}-{ref}-{caller}.vcf"
    conda:
        "../envs/variant-calling.yaml"
    wildcard_constraints:
        caller = "|".join(config["callers"])
    shell:
        """
        python workflow/scripts/split_vcf_per_type.py -v {input}
        bgzip {params.unzip} && tabix {output.svs}
        """

rule filter_censat:
    input:
        vcf = "results/{ref}/variant-calling/{sample}/{folder}/svs_{sample}-{ref}-{caller}.vcf.gz",
        censat = "workflow/resources/chm13v2.0_censat_v2.1.merged.bed"
    output:
        "results/{ref}/variant-calling/{sample}/{folder}/svs_{sample}-{ref}-{caller}.filter-censat.vcf.gz"
    conda:
        "../envs/variant-calling.yaml"
    params:
        unzip = "results/{ref}/variant-calling/{sample}/{folder}/svs_{sample}-{ref}-{caller}.filter-censat.vcf"
    shell:
        """
        bcftools view -h {input.vcf} -Ov -o {params.unzip}
        bedtools subtract -a {input.vcf} -b {input.censat} >> {params.unzip}
        bgzip {params.unzip} && tabix {output}
        """