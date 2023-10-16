#!/bin/bash
#SBATCH --job-name=snakemake_run
#SBATCH -p medium
#SBATCH --mem=100gb
#SBATCH -N 1
#SBATCH -n 32
#SBATCH -t 72:00:00
#SBATCH -o "logs/slurm/out/stdout.%j.%N"
#SBATCH -e "logs/slurm/err/stderr.%j.%N"
#SBATCH --mail-user=paul.villanueva@usda.gov
#SBATCH --mail-type=BEGIN,END,FAIL

cd /project/fsepru/paul.villanueva/repos/snakemake-genome-assembly-practice

date
time snakemake --use-conda --profile slurm
date
