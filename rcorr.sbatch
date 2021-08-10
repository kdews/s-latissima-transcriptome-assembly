#!/bin/bash
#SBATCH -N 1
#SBATCH --cpus-per-task 12
#SBATCH -p cegs
#SBATCH -e rcorrect_%A.e
#SBATCH -J rcorrect
#SBATCH --mem=24000
#SBATCH --time=36:00:00

run_rcorrector.pl -od rcorrected -t 12 -1 $1 -2 $2
