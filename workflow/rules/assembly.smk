# ---------------------------
# Rules related to preparing and performing assemblies
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------


# QC on fastqs using fastp
rule fastp_qc:
    input:
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_1.fastq.gz",
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_2.fastq.gz"
    output:
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_1.fastp.fastq.gz",
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_2.fastp.fastq.gz",
    log:
        err="logs/fastp_qc/{sra}/fastp_qc.err",
        out="logs/fastp_qc/{sra}/fastp_qc.out"
    conda:
        "../envs/fastp.yml"
    params:
        working_directory=config["directories"]["working_directory"]
    shell:
        """
        fastp -i {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastq.gz \
            -I {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastq.gz \
            -o {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastp.fastq.gz \
            -O {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastp.fastq.gz \
            --failed_out {params.working_directory}/{wildcards.sra}/{wildcards.sra}_failed_reads.txt \
            -h {params.working_directory}/{wildcards.sra}/{wildcards.sra}_fastp_report.html \
            -j {params.working_directory}/{wildcards.sra}/{wildcards.sra}_fastp_report.json \
        """

# Remove phiX spikein
rule phix_removal:
    input:
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_1.fastp.fastq.gz",
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_2.fastp.fastq.gz",
    output:
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_1.unmatched.fastp.fastq.gz",
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_2.unmatched.fastp.fastq.gz",
    log:
        err="logs/phix_removal/{sra}/phix_removal.err",
        out="logs/phix_removal/{sra}/phix_removal.out"
    conda:
        "../envs/bbduk.yml"
    resources:
        time="1h",
        partition="short",
    params:
        working_directory=config["directories"]["working_directory"]
    shell:
        """
        bbduk.sh in={params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.fastp.fastq.gz \
            in2={params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.fastp.fastq.gz \
            out={params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.unmatched.fastp.fastq.gz \
            out2={params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.unmatched.fastp.fastq.gz \
            stats={params.working_directory}/{wildcards.sra}/bbduk_stats.txt \
            hdist=1
        """

rule unicycler:
    input:
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_1.unmatched.fastp.fastq.gz",
        f"{config['directories']['working_directory']}/{{sra}}/{{sra}}_pass_2.unmatched.fastp.fastq.gz",
    output:
        f"{config['directories']['working_directory']}/{{sra}}/unicycler_output/assembly.fasta",
    log:
        err="logs/unicycler/{sra}/spades_py.err",
        out="logs/unicycler/{sra}/spades_py.out"
    conda:
        "../envs/unicycler.yml"
    threads: 32
    resources:
        time="12h",
        mem_mb="64G"
    params:
        working_directory=config["directories"]["working_directory"],
        min_fasta_length=config["assembly"]["minimum_contig_length"]
    benchmark:
        "benchmarks/unicycler/{sra}.txt"
    shell:
        """
        unicycler --threads {threads} \
            -1 {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_1.unmatched.fastp.fastq.gz \
            -2 {params.working_directory}/{wildcards.sra}/{wildcards.sra}_pass_2.unmatched.fastp.fastq.gz \
            -o {params.working_directory}/{wildcards.sra}/unicycler_output \
            --min_fasta_length {params.min_fasta_length} \
            --keep 0 \
            1> {log.out} 2> {log.err}
        """


# Move genomes to final directory
rule collect_genomes:
    input:
        # f"{config["directories"]['working_directory']}/{{sra}}/spades_output/scaffolds.fasta",
        f"{config['directories']['working_directory']}/{{sra}}/unicycler_output/assembly.fasta",
    output:
        # f"{config['final_genome_directory']}/{{sra}}_scaffolds.fasta",
        f"{config['directories']['final_genome_directory']}/{{sra}}_assembly.fasta",
    log:
        err="logs/collect_genomes/{sra}/collect_genomes.err",
        out="logs/collect_genomes/{sra}/collect_genomes.out"
    params:
        final_genome_directory=config["directories"]["final_genome_directory"]
    shell:
        """
        cp {input} {params.final_genome_directory}/{wildcards.sra}_assembly.fasta 1> {log.out} 2> {log.err}
        """
