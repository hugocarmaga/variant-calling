configfile: "config/config.yaml"

samples = [i for i in config["reads"].keys()]
members = [i for i in config["reads"][samples[0]].keys()]
refs = [i for i in config["references"].keys()]


rule map_to_ref:
    input:
        reads = lambda wildcards: config["reads"][wildcards.sample]["sample"],
        ref = lambda wildcards: config["references"][wildcards.ref]
    output:
        fofn = "results/{ref}/mapping/{sample}/{sample}.fofn",
        bam = "results/{ref}/mapping/{sample}/{sample}-{ref}.sorted.bam"
    conda:
        "../envs/mapping.yaml"
    wildcard_constraints:
        sample = "|".join(samples),
        ref = "|".join(refs)
    params:
        fnames = lambda wildcards: "\n".join(config["reads"][wildcards.sample]["sample"])
    resources:
        mem_mb = 100000,
        walltime = "4:00:00"
    threads: 24
    shell:
        '''
        echo "{params.fnames}" > {output.fofn}
        pbmm2 align {input.ref} {output.fofn} {output.bam} --sort
        samtools index {output.bam}
        '''

rule count_yak:
    input:
        lambda wildcards: config["reads"][wildcards.sample][wildcards.member] if wildcards.member != "sample" else ""
    output:
        "results/assemblies/{sample}/yak-counts/{member}.yak"
    conda:
        "../envs/assembly.yaml"
    wildcard_constraints:
        sample = "|".join(samples),
        member = "|".join(members)
    params:
        names = lambda wildcards, input: " ".join(input),
    resources:
        mem_mb = 100000,
        walltime = "4:00:00"
    threads: 24
    shell:
        '''
        yak count -b37 -t {threads} -o {output} {params.names}
        '''

rule hifiasm_assembly_trio:
    input:
        reads = lambda wildcards: config["reads"][wildcards.sample]["sample"],
        pat_yak = "results/assemblies/{sample}/yak-counts/paternal.yak",
        mat_yak = "results/assemblies/{sample}/yak-counts/maternal.yak"
    output:
        h1 = "results/assemblies/{sample}/sample.asm.dip.hap1.p_ctg.gfa",
        h2 = "results/assemblies/{sample}/sample.asm.dip.hap2.p_ctg.gfa"
    conda:
        "../envs/assembly.yaml"
    wildcard_constraints:
        sample = "|".join(samples)
    params:
        names = lambda wildcards: " ".join(config["reads"][wildcards.sample]["sample"]),
        prefix = "results/assemblies/{sample}/sample.asm"
    resources:
        mem_mb = 200000,
        walltime = "30:00:00"
    threads: 24
    shell:
        """
        hifiasm -o {params.prefix} -t {threads} -1 {input.pat_yak} -2 {input.mat_yak} {params.names}
        """

rule hifiasm_assembly_normal:
    input:
        lambda wildcards: config["reads"][wildcards.sample][wildcards.member]
    output:
        h1 = "results/assemblies/{sample}/{member}.asm.bp.hap1.p_ctg.gfa",
        h2 = "results/assemblies/{sample}/{member}.asm.bp.hap2.p_ctg.gfa"
    conda:
        "../envs/assembly.yaml"
    wildcard_constraints:
        sample = "|".join(samples),
        member = "|".join(members)
    params:
        names = lambda wildcards: " ".join(config["reads"][wildcards.sample][wildcards.member]),
        prefix = "results/assemblies/{sample}/{member}.asm"
    resources:
        mem_mb = 200000,
        walltime = "30:00:00"
    threads: 24
    shell:
        """
        hifiasm -o {params.prefix} -t {threads} {params.names}
        """