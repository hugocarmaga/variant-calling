import argparse
import gzip
import os

def parse_arguments():
    parser = argparse.ArgumentParser()

    parser.add_argument("-v", "--vcf", help="The vcf file", required=True)

    return parser.parse_args()

def split_vcf_per_type(file):

    if file.split(".")[-1]=="gz":
        vcf = gzip.open(file,'rt')
        file = os.path.basename(file)
        out_snps = open("snps_"+file[:-3], 'w')
        out_indels = open("indels_"+file[:-3], 'w')
        out_svs = open("svs_"+file[:-3], 'w')
    else:
        file = os.path.basename(file)
        vcf = open(file,'r')
        out_snps = open("snps_"+file, 'w')
        out_indels = open("indels_"+file, 'w')
        out_svs = open("svs_"+file, 'w')

    for line in vcf:
        if line.startswith("#"):
            out_snps.write(line)
            out_indels.write(line)
            out_svs.write(line)
        else:
            col = line.split()
            ref = col[3]
            alt = col[4].split(",")
            if len(alt) == 1:
                if len(ref) == 1 and len(alt[0]) == 1:
                    out_snps.write(line)
                elif len(ref) <= 50 and len(alt[0]) <= 50:
                    out_indels.write(line)
                else:
                    out_svs.write(line)
            else:
                is_snp = True
                is_sv = False
                for allele in alt:
                    if len(allele) > 50:
                        out_svs.write(line)
                        is_snp = False
                        is_sv = True
                        break
                    elif len(allele) > 1:
                        is_snp = False
                if len(ref) >= 1:
                    is_snp = False
                    if len(ref) > 50 and not is_sv:
                        out_svs.write(line)
                        is_sv = True
                if is_snp:
                    out_snps.write(line)
                elif not is_sv:
                    out_indels.write(line)

def main():
    args = parse_arguments()
    split_vcf_per_type(args.vcf)

if __name__ == "__main__":
    main()



