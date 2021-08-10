#!/bin/bash
#SBATCH --partition=cegs 
#SBATCH --time=300:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=10gb

# Help message
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]] \
|| [[ -z $1 ]]; then
  printf "Usage: sbatch trinity_submit.sbatch \
<samples_file> <output_directory>\n\n\
Requires Trinity. (http://trinityrnaseq.github.io)\n\
Note: See documentation for <samples_file> format \
from Trinity docs.\n\n"
  exit 0
fi


# Define global variables from input
samples_file=$1
outdir=$2

# Load Trinity
source ~/bin/anaconda3/etc/profile.d/conda.sh
conda activate trinity
Trinity --version
if [[ $? -ne 0 ]]
then
  printf "Error - check Trinity installation.\n\n"
else
  printf "Trinity loaded successfully.\n\n"
fi

Trinity --output $outdir --seqType fq --CPU 12 \
--samples_file $samples_file --max_memory 50G
