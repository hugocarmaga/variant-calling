# Variant (SV) calling pipeline
This pipeline is currently being made. It'll contain these steps, used in https://doi.org/10.1101/2024.04.18.590093:

## Reference genome alignments
Reads were aligned to the CHM13 linear reference genome (other references are possible) using [pbmm2]’s (version 1.9.0) “align” subcommand to map the HiFi reads using the option “--sort” to generate sorted BAM files.

## Individual assembly generation
Individual phased assemblies of these genomes were generated using [hifiasm] (version 0.19.8-r603) trio binning mode. In order to do so, k-mer counts for parental reads were required, and for that we used [yak]’s (version 0.1-r56) count subcommand with the “-b37” option, generating both a maternal and paternal k-mer count yak file for each sample. We then used these yak files as input parameters for hifiasm using the “-1” and “-2” options to generate a phased assembly, with one GFA file per haplotype.

## SV calling using linear reference genomes
We used [Sniffles] version 2.0.7 and [Phased Assembly Variant Caller (PAV)] version 2.3.4 to discover SVs in the four patient genomes using the CHM13 linear reference genome. For Sniffles, an alignment-based caller, we used BAM files to compute candidate SVs for each sample in a VCF file. For PAV, an assembly-based caller, we converted the GFA phased assemblies to FASTA, and used them as input to PAV, together with the CHM13 linear reference genome, in order to generate a VCF with genomic variants. Furthermore, we filtered PAV results to include only variants bigger than 50bp in size, creating a PAV SV set.

## Filtering SVs
Filtered SV sets were obtained by excluding all variants overlapping the [centromere/satellite repeat annotation (Cen/Sat)] version 2.1 for the CHM13 linear reference genome, from the Telomere-to-telomere (T2T) consortium13. For that, we used [bedtools]’ (version 2.30.0) subtract subcommand with the VCF files and the BED file with the Cen/Sat positions, creating a new VCF file without SVs overlapping with those regions.


[pbmm2]: https://github.com/PacificBiosciences/pbmm2
[hifiasm]: https://github.com/chhylp123/hifiasm
[yak]: https://github.com/lh3/yak
[Sniffles]: https://github.com/fritzsedlazeck/Sniffles
[Phased Assembly Variant Caller (PAV)]: https://github.com/EichlerLab/pav
[centromere/satellite repeat annotation (Cen/Sat)]: https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_censat_v2.1.bed
[bedtools]: https://bedtools.readthedocs.io/en/latest/index.html