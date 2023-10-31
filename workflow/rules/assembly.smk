# ---------------------------
# Rules related to preparing and performing assemblies
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------


# QC on fastqs using fastp
rule fastp_qc:
    input:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.fastq.gz"
    output:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.fastp.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.fastp.fastq.gz",
    log:
        err="logs/fastp_qc/{sra}/fastp_qc.err",
        out="logs/fastp_qc/{sra}/fastp_qc.out"
    conda:
        "../envs/fastp.yml"
    params:
        sra_download_directory=config["sra_download_directory"]
    shell:
        """
        fastp -i {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastq.gz \
            -I {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastq.gz \
            -o {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastp.fastq.gz \
            -O {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastp.fastq.gz \
            --failed_out {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_failed_reads.txt \
            -h {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_fastp_report.html \
            -j {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_fastp_report.json \
        """

# Remove phiX spikein
rule phix_removal:
    input:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.fastp.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.fastp.fastq.gz",
    output:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.unmatched.fastp.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.unmatched.fastp.fastq.gz",
    log:
        err="logs/phix_removal/{sra}/phix_removal.err",
        out="logs/phix_removal/{sra}/phix_removal.out"
    conda:
        "../envs/bbduk.yml"
    resources:
        time="1h",
        partition="short",
    params:
        sra_download_directory=config["sra_download_directory"]
    shell:
        """
        bbduk.sh in={params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastp.fastq.gz \
            in2={params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastp.fastq.gz \
            out={params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.unmatched.fastp.fastq.gz \
            out2={params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.unmatched.fastp.fastq.gz \
            stats={params.sra_download_directory}/{wildcards.sra}/bbduk_stats.txt \
            hdist=1
        """

# Use SPAdes to assemble genomes
rule spades_py:
    input:
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_1.unmatched.fastp.fastq.gz",
        f"{config['sra_download_directory']}/{{sra}}/{{sra}}_pass_2.unmatched.fastp.fastq.gz",
    output:
        f"{config['sra_download_directory']}/{{sra}}/spades_output/scaffolds.fasta",
    log:
        err="logs/spades_py/{sra}/spades_py.err",
        out="logs/spades_py/{sra}/spades_py.out"
    conda:
        "../envs/spades.yml"
    threads: 32
    resources:
        time="12h",
        mem_mb="64G"
    params:
        sra_download_directory=config["sra_download_directory"]
    benchmark:
        "benchmarks/spades_py/{sra}.txt"
    shell:
        """
        spades.py --threads {threads} \
            -1 {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.unmatched.fastp.fastq.gz \
            -2 {params.sra_download_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.unmatched.fastp.fastq.gz \
            -o {params.sra_download_directory}/{wildcards.sra}/spades_output 
        """

# Move genomes to final directory
rule collect_genomes:
    input:
        f"{config['sra_download_directory']}/{{sra}}/spades_output/scaffolds.fasta",
    output:
        f"{config['final_genome_directory']}/{{sra}}_scaffolds.fasta",
    log:
        err="logs/collect_genomes/{sra}/collect_genomes.err",
        out="logs/collect_genomes/{sra}/collect_genomes.out"
    params:
        final_genome_directory=config["final_genome_directory"]
    shell:
        """
        cp {input} {params.final_genome_directory}/{wildcards.sra}_scaffolds.fasta 1> {log.out} 2> {log.err}
        """
