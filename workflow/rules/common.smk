# This creates a list of the SRA accession to download from the 
# sra_config variable in config.yml.
with open(config["sra_list"]) as fin:
    SRA_LIST = [line.rstrip() for line in fin.readlines() if line.startswith('SRR')]