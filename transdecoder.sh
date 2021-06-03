#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem=5gb
#SBATCH -t 01:00:00
#SBATCH -o transdec.out

assembly=$1

TransDecoder.LongOrfs -O filtering/transdec -t ${assembly}
TransDecoder.Predict -O filtering/transdec --no_refine_starts -t ${assembly}

