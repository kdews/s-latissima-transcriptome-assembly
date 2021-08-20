#!/bin/bash

## READS + QC
# Download raw reads from ENA with wget
# See https://ena-docs.readthedocs.io/en/latest/retrieval/file-download.html#using-wget
# Accessions file must list all samples in the format:
# CONDITION	SAMPLE_ID	SRR/ERR_ID
accessions_file=accessions_file.txt
for acc in `awk '{print $3}' $accessions_file`
do
  prefix=`echo ${acc:0:6}`
  # Should 100% just change this to fasterq-dump ok??
  wget -np -nH -r -p -e robots=off --cut-dir 2 \
--regex-type pcre --accept-regex "${acc}.*\..*q\.gz" \
https://ftp.sra.ebi.ac.uk/vol1/fastq/${prefix}/${acc}
done


## TRANSCRIPTOME ASSEMBLY


