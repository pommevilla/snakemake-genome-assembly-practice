# ---------------------------
# Rules related to generating or organizing metrics for the assembled genomes
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# Generate Quast metrics
rule quast:
    input:
        # f"{config["directories"]['working_directory']}/{{sra}}/spades_output/scaffolds.fasta",
        f"{config['directories']['working_directory']}/{{sra}}/unicycler_output/assembly.fasta",
    output:
        f"{config['directories']['working_directory']}/{{sra}}/quast_output/transposed_report.tsv",
    log:
        err="logs/quast/{sra}/quast.err",
        out="logs/quast/{sra}/quast.out"
    conda:
        "../envs/quast.yml"
    resources:
        time="2h",
        partition="short",
    params:
        working_directory=config["directories"]["working_directory"]
    shell:
        """
        quast.py {input} -o \
            {params.working_directory}/{wildcards.sra}/quast_output 
        """

# Collect transposed Quast metrics into one file
rule collect_quast_metrics:
    input:
        quast_metrics=expand(
            "{working_directory}/{sra}/quast_output/transposed_report.tsv",
            working_directory=config["directories"]['working_directory'],
            sra=SRA_LIST
        )
    output:
        f"{config['directories']['final_metrics_directory']}/quast_metrics.txt",
    log:
        err="logs/collect_metrics/collect_metrics.err",
        out="logs/collect_metrics/collect_metrics.out"
    shell:
        """
        set +u
        counter=0
        for fin in {input.quast_metrics};
        do
            if [ $counter -eq 0 ]
            then
                head -1 $fin > {output}
            fi
            tail -1 $fin | sed "1s|^assembly|$(echo $fin | cut -f 2 -d '/') |" >> {output}
            counter=$((counter+1))
        done
        set -u
        """

# Generate checkm2 metrics
rule checkm2:
    input:
        expand(
            "{final_genome_directory}/{sra}_assembly.fasta",
            final_genome_directory=config['directories']['final_genome_directory'],
            sra=SRA_LIST
        ),
    output:
        directory(f"{config['directories']['final_metrics_directory']}/checkm2")
    log:
        err="logs/checkm2/checkm2.err",
        out="logs/checkm2/checkm2.out"
    conda:
        "../envs/checkm2.yml"
    params:
        checkm2_database=config["metrics"]["checkm2_database"],
        final_genome_directory=config["directories"]["final_genome_directory"],
        final_metrics_directory=config["directories"]["final_metrics_directory"]
    resources:
        time="2h",
        partition="short",
        mem_mb=64000
    threads: 64
    shell:
        """
        checkm2 predict -t {threads} \
            --input {input} \
            --allmodels \
            --output-directory {params.final_metrics_directory}/checkm2 \
            --database_path {params.checkm2_database} \
            --force
        """
 

