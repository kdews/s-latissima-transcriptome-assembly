#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=8gb
#SBATCH -t 100:00:00
#SBATCH -c 12
#SBATCH -o mcsc_order.out

path_to_mcsc=/home1/kdeweese/bin/MCSC_Decontamination

source activate mcsc
module load ghostscript
# $1 is .ini file for MCSC
sh $path_to_mcsc/MCSC_decontamination.sh $1

