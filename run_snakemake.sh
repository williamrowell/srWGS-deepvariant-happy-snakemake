#!/bin/bash
#SBATCH -p compute
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task 4
#SBATCH -o cluster_logs/slurm-%x-%j-%N.out

umask 002

# execute snakemake
snakemake --reason \
    --rerun-incomplete \
    --keep-going \
    --printshellcmds \
    --local-cores 4 \
    --jobs 500 \
    --max-jobs-per-second 1 \
    --use-singularity --singularity-args '--nv ' \
    --latency-wait 120 \
    --cluster-config workflow/cluster.yaml \
    --cluster "sbatch --partition={cluster.partition} \
                      --cpus-per-task={cluster.cpus} \
                      --output={cluster.out} {cluster.extra} " \
    --snakefile workflow/Snakefile

#     --use-conda --conda-frontend mamba \