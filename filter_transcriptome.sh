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
Requires:   GNU parallel   seqtk   cd-hit-auxtools\n"
  exit 0
fi

# Header of output
printf "filter_transcriptome.sh by Kelly DeWeese\n\
Github: https://github.com/kellywithsword\n\n"

# Define positional arguments
ortho_collapsed=$1
ortho_short_genes=$2
collapsed_transcriptome=$3
short_genes_from_transcriptome=$4
output=$5
temp_output=${5}.temp

# Load conda
source ~/bin/anaconda3/etc/profile.d/conda.sh

# Load GNU Parallel and create a directory for parallel job logs
module load parallel
# Create directory for logs (if not already exists)
[[ -d filter-logs ]] || mkdir filter-logs

# Extract transcript IDs of orthologs identified by OrthoFinder
# ($ortho_collapsed and $ortho_short_genes)
parallel -j $SLURM_NTASKS --joblog filter-logs/awk.joblog \
"awk -F '\t' '{print \$2}' {}.tsv | tail -n+2 | sed 's/, /\n/g' | \
sed 's/\.p.*//g' | sort -u > {}/{}_IDs.txt" ::: $ortho_collapsed $ortho_short_genes

# Count number of transcript IDs extracted (from $ortho_collapsed and $ortho_short_genes)
num_ids_1=`cat ${ortho_collapsed}/${ortho_collapsed}_IDs.txt | wc -l`
num_ids_2=`cat ${ortho_short_genes}/${ortho_short_genes}_IDs.txt | wc -l`

# Verify that each ID text file is not empty; if empty, break
if [ $num_ids_1 = "0" ] || [ $num_ids_2 = "0" ]
then
  printf "No orthologs found! Check OrthoFinder results, \
${ortho_collapsed}_IDs.txt and ${ortho_short_genes}_IDs.txt.\n" 1>&2
  exit 1
fi

# Report number of orthologs found in collapsed transcriptome and
# in transcripts shorter than collapse threshold length
printf "Found $num_ids_1 orthologs in the first transcriptome.\n"
printf "Found $num_ids_2 orthologs in the second transcriptome.\n"

# Subsample orthologs from transcript FASTAs with seqtk
conda activate seqtk
parallel -j $SLURM_NTASKS --joblog filter-logs/seqtk.joblog --link \
"seqtk subseq {1} {2}/{2}_IDs.txt > {2}.fa" ::: $collapsed_transcriptome $short_genes_from_transcriptome ::: $ortho_collapsed $ortho_short_genes

# Count number of sequences in each new FASTA ($3 and $4)
num_seqs_1=`grep -c ">" ${ortho_collapsed}.fa`
num_seqs_2=`grep -c ">" ${ortho_short_genes}.fa`

# Verify that number of sequences in FASTAs is equal to ortholog IDs; if not, break
if [ $num_ids_1 != $num_seqs_1 ] || [ $num_ids_2 != $num_seqs_2 ]
then
  printf "\nSubsampling error! Check to make sure ${ortho_collapsed}_IDs.txt | ${ortho_collapsed}.fa \
and ${ortho_short_genes}_IDs.txt | ${ortho_short_genes}.fa have matching sequence identifiers, and \
that ${ortho_collapsed}_IDs.txt and ${ortho_short_genes}_IDs.txt contain no duplicate sequence IDs.\n\
# of:\tIDs\tsequences\n\
1st\t$num_ids_1\t$num_seqs_1\n\
2nd\t$num_ids_2\t$num_seqs_2\n" 1>&2
  exit 1
fi

# Concatenate orthologs into a new transcriptome assembly FASTA ($temp_output)
cat ${ortho_collapsed}.fa > $temp_output
cat ${ortho_short_genes}.fa >> $temp_output

# Count total number of ortholog sequences added to new transcriptome assembly
num_total_seqs=`grep -c ">" $temp_output`

# Verify that the total number of ortholog sequences in new transcriptome FASTA is equal
# to the sum of sequences in 
if [ $((num_total_seqs)) = $((num_seqs_1 + num_seqs_2)) ]
then
  printf "\nTranscriptome has been successfully filtered for orthologs!\n"
else
  printf "\nError contcatenating! Something's not adding up...\n\
num_total_seqs =/= num_collapsed_seqs + num_collapsed_seqs\n\
$num_total_seqs =/= $num_seqs_1 + $num_seqs_2 \n" 1>&2
  exit 1
fi

# Remove duplicated transcripts (transcripts exactly equal to chosen transcript clustering length) with cd-hit
printf "\nRemoving duplicate transcripts...\n\
CD-HIT-DUP output:\n"
conda activate cd-hit
cd-hit-dup -i $temp_output -o $output

printf "\nAll duplicate transcripts have been removed.\n"

# Delete temporary files
rm $temp_output
rm $output*.clstr
