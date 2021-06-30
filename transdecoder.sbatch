#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem=5gb
#SBATCH -t 01:00:00
#SBATCH -o transdec.out

# Help message
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]]; then
  printf "Usage: sbatch transdecoder_submit.sh out_dir assembly\n\n\
Requires: TransDecoder \
(https://transdecoder.github.io/)\n"
  exit 0
fi

# Define positional variables
outdir=$1
assembly=$2

source activate transdec

TransDecoder.LongOrfs -O $outdir -t $assembly
TransDecoder.Predict -O $outdir --no_refine_starts -t $assembly

