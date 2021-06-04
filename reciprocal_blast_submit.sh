#!/bin/bash

# Help message
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]]; then
  printf "A ready-made reciprocal BLAST recipe, just for you.\n\n\
Usage: bash reciprocal_blast_submit.sh molecule_type query1 query2 [db1 db2]\n\
(where molecule_type = 'prot' or 'nucl')\n\n\
First, checks for existence of BLAST databases built from each query \n\
or given as input, and creates databases if necessary. Then, runs \n\
reciprocal BLASTs (using either blastn or blastp depending on \
molecule_type).\n\n\
Requires: NCBI command-line BLAST \
(https://www.ncbi.nlm.nih.gov/books/NBK52640/)\n"
  exit 0
fi

# Path to scripts (stable)
scripts=/home1/kdeweese/scripts
# Name of conda environment with BLAST installed
blast_env=blast

# Define positional arguments
# Data molecule type
molecule_type=$1
# Input filenames
query1=$2
query2=$3
# If no database names given, parse from query filenames
if [[ -z "$4" ]]
then
  db1=`echo $query1 | sed 's/\..*//g'`
else
  db1=$4
fi
if [[ -z "$5" ]]
then
  db2=`echo $query2 | sed 's/\..*//g'`
else
  db2=$5
fi

# Create BLAST databases, if needed
source activate $blast_env
printf "Checking for BLAST databases...\n"
blastdbcmd -info -db $db1
if [[ $? -ne 0 ]]
then
  printf "\nCreating BLAST database $db1 from ${query1}."
  db1=`echo $query1 | sed 's/\..*//g'`
  makeblastdb -in $query1 -out $db1 -dbtype $molecule_type -parse_seqids
else
  printf "Using BLAST database $db1.\n\n"
fi
blastdbcmd -info -db $db2
if [[ $? -ne 0 ]]
then
  printf "\nCreating BLAST database $db2 from ${query2}."
  db2=`echo $query2 | sed 's/\..*//g'`
  makeblastdb -in $query2 -out $db2 -dbtype $molecule_type -parse_seqids
else
  printf "Using BLAST database $db2.\n\n"
fi

# Submit BLAST alignment jobs to SLURM
# only if blast_submit.sh output doesn't already exist
if [[ -f ${db1}_vs_${db2}.${molecule_type}.blast.tab ]]
then
  printf "Skipping BLAST of ${db1}_vs_${db2} (output exists). \n\
Remove ${db1}_vs_${db2}.${molecule_type}.blast.tab to rerun BLAST.\n"
else
  sbatch -J ${db1}_vs_${db2} -o blast_submit_${db1}_vs_${db2}.${molecule_type}.out \
  ${scripts}/blast_scripts/blast_submit.sh $molecule_type $query1 $db2
fi

if [[ -f ${db2}_vs_${db1}.${molecule_type}.blast.tab ]]
then
  printf "Skipping BLAST of ${db2}_vs_${db1} (output exists). \n\
Remove ${db2}_vs_${db1}.${molecule_type}.blast.tab to rerun BLAST.\n"
else
  sbatch -J ${db2}_vs_${db1} -o blast_submit_${db2}_vs_${db1}.${molecule_type}.out \
  ${scripts}/blast_scripts/blast_submit.sh $molecule_type $query2 $db1
fi


