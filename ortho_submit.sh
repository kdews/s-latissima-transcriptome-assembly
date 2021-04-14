#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=1gb
#SBATCH -t 05:00:00
#SBATCH -n 2
#SBATCH -c 12
#SBATCH -o orthofinder.out

module load parallel

parallel -j $SLURM_NTASKS --joblog orthofinder.joblog orthofinder -t $SLURM_CPUS_PER_TASK -f {} ::: `ls -d ortho*/`

