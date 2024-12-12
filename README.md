# Variant (SV) calling pipeline
This pipeline was made to be used in https://doi.org/10.1101/2024.04.18.590093. It takes FASTQ files from a sample and optionally from its parents (see config) as an input and it outputs SV VCFs from [Sniffles], [Phased Aseebmly Variant Caller (PAV)] or both (see config). Additional VCFs without SVs found in the [centromere/satellite repeat annotation (Cen/Sat)] regions are also produced.

## System Requirements

- python=3.9.12
- snakemake=7.32.4
- conda=24.1.2
- singularity=3.5.2

## Installation Guide

### Instructions

The pipeline is run with snakemake and the dependencies of each rule is resolved by the specified conda environment.

## Instructions for use

### Input

This pipeline requires FASTQ files as an input, and it is optimised for PacBio HiFi reads. SV calling with PAV can be improved by providing parental HiFi reads, which will then be used to generate genome assemblies using [hifiasm]'s trio binning mode (together with [yak]). Lists of FASTQ file names should be provided in the `config/config.yaml` as demonstrated there. You can obviously replace `name1` and `name2` by your sample's names, but please don't change `sample`/`paternal`/`maternal`, as this will cause the pipeline to fail.

Additionally, you need to provide (a) reference genome(s) to have your variants called against (see config).

Lastly, you need to specify the list of callers you want to call SVs with. Right now, the available callers are:
- [Sniffles]
- [PAV]

**Important**: If PAV is selected, this has to be done prior to running the pipeline, so that you can download the correct PAV container:
```
$ mkdir workflow/container
$ cd workflow/container
$ singularity pull library://becklab/pav/pav:2.3.4
```

### Output

The main outputs of the pipeline are:
- A SV VCF file per given `sample` (SVs aren't called for `paternal`/`maternal` reads) per given `caller` in: `results/{ref}/variant-calling/{sample}/{caller}/svs_{sample}-{ref}-{caller}.vcf.gz`
- A SV VCF file per given `sample` (SVs aren't called for `paternal`/`maternal` reads) per given `caller`, excluding all SVs intersecting with the [Cen/Sat] annotation from the T2T consortium, in: `results/{ref}/variant-calling/{sample}/{caller}/svs_{sample}-{ref}-{caller}.filter-censat.vcf.gz`
- If [PAV] is selected, [hifiasm] assemblies will also be generated. They'll either be in trio-binning mode or normal mode, depending whether parental reads are provided or not, respectively, in: `results/assemblies/{sample}/sample.asm.dip.hap{1/2}.p_ctg.gfa`
- If [Sniffles] is selected, BAM files will be produced by [pbmm2] with the alignments of the `sample` reads to the refence genome(s) provided in: `results/{ref}/mapping/{sample}/{sample}-{ref}.sorted.bam`

### How to run

First, set `config/config.yaml` according to the instructions.

Then, under the directory `variant-calling`:
```
$ snakemake --singularity-args "--bind $(pwd):$(pwd)" -j <cores> --use-conda
```

[pbmm2]: https://github.com/PacificBiosciences/pbmm2
[hifiasm]: https://github.com/chhylp123/hifiasm
[yak]: https://github.com/lh3/yak
[Sniffles]: https://github.com/fritzsedlazeck/Sniffles
[Phased Assembly Variant Caller (PAV)]: https://github.com/EichlerLab/pav
[PAV]: https://github.com/EichlerLab/pav
[centromere/satellite repeat annotation (Cen/Sat)]: https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_censat_v2.1.bed
[Cen/Sat]: https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_censat_v2.1.bed