#!/bin/bash
#SBATCH --job-name=snakemake_run
#SBATCH -p medium
#SBATCH --mem=100gb
#SBATCH -N 1
#SBATCH -n 48
#SBATCH -t 48:00:00
#SBATCH -o "logs/slurm/out/stdout.%j.%N"
#SBATCH -e "logs/slurm/err/stderr.%j.%N"
#SBATCH --mail-user=paul.villanueva@usda.gov
#SBATCH --mail-type=BEGIN,END,FAIL

cd /project/fsepru/paul.villanueva/repos/snakemake-genome-assembly-practice
source /home/${USER}/.bashrc
source activate snakemake


date
time snakemake --use-conda --profile slurm -p
date
