#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=2gb
#SBATCH -t 60
#SBATCH -n 2
#SBATCH -J filter_transcriptome
#SBATCH -o %x.out
#SBATCH -e %x.err

# Help message
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]] || [[ -z "$1" ]]; then
  printf "Takes 2 OrthoFinder parent directory names and the \
*nucleic acid* FASTAs that were translated for OrthoFinder as \
input, and outputs a transcriptome assembly filtered strictly \
for orthologs to a species of interest.\n\n\
Usage: sbatch filter_transcriptome.sh \
ortho_collapsed/ ortho_short_genes/ \
collapsed_transcriptome.fa short_genes_from_transcriptome.fa \
name_of_output.fa\n\n\
Requires:   GNU parallel   seqtk\n"
  exit 0
fi

# Load GNU Parallel and create a directory for parallel job logs
module load parallel
if [[ -d dir ]]
then
  mkdir filter-logs
fi

# Extract transcript IDs of orthologs identified by OrthoFinder ($1 and $2)
parallel -j $SLURM_NTASKS --joblog filter-logs/awk.joblog \
"awk -F '\t' '{print \$2}' {}.tsv | tail -n+2 | sed 's/, /\n/g' | \
sed 's/\.p.//g' | sort -u > {}/{}_IDs.txt" ::: $1 $2

# Count number of transcript IDs extracted (from $1 and $2)
num_ids_1=`cat ${1}/${1}_IDs.txt | wc -l`
num_ids_2=`cat ${2}/${2}_IDs.txt | wc -l`

# Verify that each ID text file is not empty; if empty, break
if [ $num_ids_1 = "0" ] || [ $num_ids_2 = "0" ]
then
  printf "No orthologs found! Check OrthoFinder results, \
${1}_IDs.txt and ${2}_IDs.txt.\n" 1>&2
  exit 1
fi

# Report number of orthologs found in collapsed transcriptome and
# in transcripts shorter than collapse threshold length
printf "Found $num_ids_1 orthologs in the first transcriptome.\n"
printf "Found $num_ids_2 orthologs in the second transcriptome.\n"

# Subsample orthologs from transcript FASTAs with seqtk
parallel -j $SLURM_NTASKS --joblog filter-logs/seqtk.joblog --link \
"seqtk subseq {1} {2}/{2}_IDs.txt > {2}.fa" ::: $3 $4 ::: $1 $2

# Count number of sequences in each new FASTA ($3 and $4)
num_seqs_1=`grep -c ">" ${1}.fa`
num_seqs_2=`grep -c ">" ${2}.fa`

# Verify that number of sequences in FASTAs is equal to ortholog IDs; if not, break
if [ $num_ids_1 != $num_seqs_1 ] || [ $num_ids_2 != $num_seqs_2 ]
then
  printf "Subsampling error! Check to make sure ${1}_IDs.txt | ${1}.fa \
and ${2}_IDs.txt | ${2}.fa have matching sequence identifiers, and \
that ${1}_IDs.txt and ${2}_IDs.txt contain no duplicate sequence IDs.\n\
# of:\tIDs\tsequences\n\
1st\t$num_ids_1\t$num_seqs_1\n\
2nd\t$num_ids_2\t$num_seqs_2\n" 1>&2
  exit 1
fi

# Concatenate orthologs into a new transcriptome assembly FASTA ($5)
cat ${1}.fa >> $5
cat ${2}.fa >> $5

# Count total number of ortholog sequences added to new transcriptome assembly
num_total_seqs=`grep -c ">" $5`

# Verify that the total number of ortholog sequences in new transcriptome FASTA is equal
# to the sum of 
if [ $((num_total_seqs)) = $((num_seqs_1 + num_seqs_2)) ]
then
  printf "Transcriptome has been successfully filtered for orthologs!\n"
  exit 0
else
  printf "Error contcatenating! Something's not adding up...\n\
num_total_seqs =/= num_collapsed_seqs + num_collapsed_seqs\n\
$num_total_seqs =/= $num_seqs_1 + $num_seqs_2 \n" 1>&2
  exit 1
fi

