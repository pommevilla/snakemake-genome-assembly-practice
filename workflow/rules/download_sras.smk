# ---------------------------
# Rules related to download reads from the SRA
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# Prefetches SRA files
rule download_sra:
    output:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}.sra"
    log:
        err="logs/download_sra/{sra}/prefetch.err",
        out="logs/download_sra/{sra}/prefetch.out"
    conda:
        "../envs/sra-tools.yml"
    params:
        sra_download_directory=config["sra_download_directory"]
    shell:
        """
        prefetch {wildcards.sra} -O {params.sra_download_directory} 1> {log.out} 2> {log.err}
        """

# Dumps fastqs from prefetched SRA files
rule dump_fastqs:
    input:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}.sra"
    output:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.fastq.gz"
    log:
        err="logs/dump_fastqs/{sra}/fastq-dump.err",
        out="logs/dump_fastqs/{sra}/fastq-dump.out"
    conda:
        "../envs/sra-tools.yml"
    params:
        sra_download_directory=config["sra_download_directory"]
    shell:
        """
        fastq-dump --outdir {params.sra_download_directory}/{wildcards.sra} \
            --gzip --skip-technical --readids --read-filter pass \
            --split-3 --clip \
            {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}.sra 
        """
