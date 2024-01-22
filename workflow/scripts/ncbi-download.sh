#!/bin/bash
# script to download genomes from NCBI

# set up environment
sys_root="$(echo ~)"
source $sys_root/.bashrc
mamba activate ncbi-download
# set up variables
OUTPUT=$sys_root/sourmash_ref_build/data/genomes/$5
if [ ! -d "$OUTPUT" ]; then
    mkdir -p $OUTPUT
fi
# download genomes
ncbi-genome-download --formats $3 --assembly-levels all --section $4 --retries 10 --output-folder $2 --parallel $OMP_NUM_THREADS $5

if [[ "$3" == "assembly-report" ]]; then
    
    find $2 -name "*.txt" > $1
    
fi

if [[ "$3" == "fasta" ]]; then
    
    find $2 -name "*.fna.gz" > $1
    
fi