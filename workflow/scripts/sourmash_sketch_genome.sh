#!/bin/bash
source /home/glbrc.org/millican/.bashrc
mamba activate sourmash
### Functions
# check if directory exists, if not create it
create_dir()
{
    if [ ! -d $OUT ]; then
        mkdir -p $OUT
    fi

    if [ ! -d $OUT/k21 ]; then
        mkdir -p $OUT/k21
    fi

    if [ ! -d $OUT/k31 ]; then
        mkdir -p $OUT/k31
    fi

    if [ ! -d $OUT/k51 ]; then
        mkdir -p $OUT/k51
    fi
}
# function to sketch genomes, for sketching in parallel
sourmash_sketch()
{
    NAME=$(basename -s _genomic.fna.gz $1)
    sketch_name=$(echo ${NAME:0:15})
    sourmash sketch dna -p k=21,scaled=1000 $1 -o $OUT/k21/${NAME}-k21.sig.gz --name $sketch_name
    sourmash sketch dna -p k=31,scaled=1000 $1 -o $OUT/k31/${NAME}-k31.sig.gz --name $sketch_name
    sourmash sketch dna -p k=51,scaled=1000 $1 -o $OUT/k51/${NAME}-k51.sig.gz --name $sketch_name
}
### Variables
# set up variables
export OUT=/mnt/bigdata/linuxhome/millican/ref_db/sourDB/signatures/$1
export GENOME=/home/glbrc.org/millican/ref_db/sourDB/genomes/$1
export genome_file="/home/glbrc.org/millican/ref_db/sourDB/genomes/$1/${1}_genomes.txt"
# export sourmash_sketch function to be used in parallel command
export -f sourmash_sketch
### Main
# create output directory
create_dir
# create list of genomes to feed into parallel command 
find $GENOME/ -name "*.fna.gz" > $genome_file
# execute sourmash_sketch function in parallel, feed input from $genome_file to avoid Argument list too long error
parallel -j 32 -a $genome_file sourmash_sketch 