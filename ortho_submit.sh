#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=1gb
#SBATCH -t 05:00:00
#SBATCH -n 2
#SBATCH -c 12
#SBATCH -o orthofinder.out


# Help message
if [ $1 = "-h" ] || [ $1 = "--help" ]; then
  printf "Usage: sbatch ortho_submit.sh\n\n\
Requires: OrthoFinder (https://github.com/davidemms/OrthoFinder)\n"
  exit 0
fi

# Load GNU Parallel
module load parallel

# Invoke parallel with jobs=$SLURM_NTASKS and a joblog file
parallel -j $SLURM_NTASKS --joblog orthofinder.joblog \
# srun arguments allocate a single core to the set
# of threads defined by $SLURM_CPUS_PER_TASK
srun --exclusive -N 1 -n $SLURM_CPUS_PER_TASK \
# Run orthofinder in directories starting with "ortho" in workdir
orthofinder -t $SLURM_CPUS_PER_TASK -f {} ::: \
`ls -d ortho*/`

