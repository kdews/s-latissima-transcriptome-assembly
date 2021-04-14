#!/bin/bash
#SBATCH -p cegs
#SBATCH --mem-per-cpu=2gb
#SBATCH -t 60
#SBATCH -n 2
#SBATCH -o filter-transcriptome.out
#SBATCH -e filter-transcriptome.err
#SBATCH -J filter-transcriptome

# Help message
if [ $1 = "-h" ] || [ $1 = "--help" ]; then
  printf "Usage: sbatch filter-transcriptome.sh \
ortho_collapsed/OrthoFinder/Results*/Orthologues/*trinity*/*.tsv \
ortho_short_genes/OrthoFinder/Results*/Orthologues/*trinity*/*.tsv \
collapsed_transcriptome.fa short_genes_from_transcriptome.fa name_of_output.fa\n\n\
Requires: seqtk\n"
  exit 0
fi

module load parallel
mkdir filter-logs

# Extract transcript IDs of orthologs identified by OrthoFinder ($1 and $2)
#parallel -j $SLURM_NTASKS --joblog awk.joblog ::: \
# "awk -F '\t' '{print \$2}' $1 | tail -n+1 | sed 's/, /\n/g' | \
# sed 's/\.p.//g' | sort -u > collapsed_ortholog_IDs.txt" \
# "awk -F '\t' '{print \$2}' $2 | tail -n+1 | sed 's/, /\n/g' | \
# sed 's/\.p.//g' | sort -u > short_ortholog_IDs.txt"
parallel -j $SLURM_NTASKS --joblog filter-logs/awk.joblog --link \
"awk -F '\t' '{print \$2}' {1} | tail -n+1 | sed 's/, /\n/g' | \
sed 's/\.p.//g' | sort -u > {2}_ortholog_IDs.txt" ::: \
ortho_collapsed.tsv ortho_short_genes.tsv :::+ collapsed short


# Count number of transcript IDs extracted (from $1 and $2)
num_collapsed_ids=`cat collapsed_ortholog_IDs.txt | wc -l`
num_short_ids=`cat short_ortholog_IDs.txt | wc -l`

# Verify that each ID text file is not empty; if empty, break
if [ $num_collapsed_ids = "0" ] || [ $num_short_ids = "0" ]
then
  printf "No orthologs found! Check OrthoFinder results.\n" 1>&2
  exit 1
fi

# Report number of orthologs found in collapsed transcriptome and
# in transcripts shorter than collapse threshold length
printf "Found $num_collapsed_ids orthologs in collapsed SuperTranscriptome.\n"
printf "Found $num_short_ids orthologs in SuperTranscripts shorter \
than the collapse threshold length.\n"

# Subsample orthologs from transcript FASTAs with seqtk
parallel -j $SLURM_NTASKS --joblog filter-logs/seqtk.joblog ::: \
"seqtk subseq $3 collapsed_ortholog_IDs.txt > collapsed_orthologs.fa" \
"seqtk subseq $4 short_ortholog_IDs.txt > short_orthologs.fa"

# Count number of sequences in each new FASTA ($3 and $4)
num_collapsed_seqs=`grep -c ">" collapsed_orthologs.fa`
num_short_seqs=`grep -c ">" short_orthologs.fa`

# Verify that number of sequences in FASTAs is equal to ortholog IDs; if not, break
if [ $num_collapsed_ids != $num_collapsed_seqs ] || [ $num_short_ids != $num_short_seqs ]
then
  printf "Subsampling error! Check to make sure ortholog ID text files and input FASTAs \
have matching sequence identifiers.\n" 1>&2
  exit 1
fi

# Concatenate orthologs into a new transcriptome assembly FASTA ($5)
parallel -j $SLURM_NTASKS --joblog filter-logs/concatenate.joblog ::: \
"cat collapsed_orthologs.fa >> $5" "cat short_orthologs.fa >> $5"

# Count total number of ortholog sequences added to new transcriptome assembly
num_total_seqs=`grep -c '>' $5`

# Verify that the total number of ortholog sequences in new transcriptome FASTA is equal
# to the sum of 
if [ $((num_total_seqs)) = $((num_collapsed_seqs + num_short_seqs)) ]
then
  printf "Transcriptome has been successfully filtered for orthologs!\n"
  exit 0
else
  printf "Error contcatenating! Something's not adding up...\n\
num_total_seqs =/= num_collapsed_seqs + num_collapsed_seqs\n\
$num_total_seqs =/= $num_collapsed_seqs + $num_collapsed_seqs \n" 1>&2
  exit 1
fi

