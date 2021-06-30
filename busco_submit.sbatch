#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=10gb
#SBATCH -t 10:00:00
#SBATCH -n 2
#SBATCH -c 12
#SBATCH -o busco.out

# Help message
if [ $1 = "-h" ] || [ $1 = "--help" ]; then
  printf "Runs BUSCO on transcriptome assembly using \n\
eukaryota_odb10 and stramenopiles_odb10 lineages.\n\
Usage: sbatch busco_submit.sh assembly\n\n\
Requires: BUSCO (https://busco.ezlab.org)\n"
  exit 0
fi

# Define variables
# Type of assembly
mode=transcriptome
# Path to BUSCO lineages and lineage names
download_path=/project/noujdine_61/common_resources/busco_lineages
L1=eukaryota_odb10
L2=stramenopiles_odb10
# Input assembly
assembly=$1
assembly_no_ext=`echo "$assembly" | sed 's/\..*//g'`
# Output directory name
out1=${assembly_no_ext}_busco_${L1}
out2=${assembly_no_ext}_busco_${L2}

# Load GNU Parallel
module load parallel
# Load BUSCO
source activate busco

# Invoke parallel with jobs=$SLURM_NTASKS and a joblog file
parallel -j $SLURM_NTASKS --joblog busco.joblog --link \
# srun arguments allocate a single core to the set
# of threads defined by $SLURM_CPUS_PER_TASK
srun --exclusive -N 1 -n $SLURM_CPUS_PER_TASK \
"busco --offline -t $SLURM_CPUS_PER_TASK -m $mode \
-l {1} --download_path $download_path -i $assembly \
-o {2}" ::: $L1 $L2 ::: $out1 $out2

if [[ $? -ne 0]]
then
  printf "Error running BUSCO. See above messages.\n"
else
  printf "\nBUSCO runs completed, find outputs in the directories:\n$out1\n$out2\n"
fi

