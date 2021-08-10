#!/bin/bash
#SBATCH -n 1
#SBATCH -p cegs
#SBATCH -e filter_uncorr_%A.e
#SBATCH -J filter_uncorr
#SBATCH --mem=2000
#SBATCH --time=05:00:00

python /home/cmb-07/sn1/kdeweese/scripts/FilterUncorrectabledPEfastq.py -1 $1 -2 $2 -s $3
