#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=8gb
#SBATCH -t 100:00:00
#SBATCH -c 12
#SBATCH -o mcsc.out

path_to_mcsc=/home1/kdeweese/bin/MCSC_Decontamination

sh $path_to_mcsc/MCSC_Decontamination.sh
