#!/bin/bash
source /home/glbrc.org/millican/.bashrc
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/genbank-2022.03/genbank-2022.03-${1}-k21.zip
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/genbank-2022.03/genbank-2022.03-${1}-k31.zip
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/genbank-2022.03/genbank-2022.03-${1}-k51.zip
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/genbank-2022.03/genbank-2022.03-${1}.lineages.csv.gz

viral
archaea
protozoa
fungi
bacteria 

https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs207/gtdb-rs207.genomic.k21.zip
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs207/gtdb-rs207.genomic.k31.zip
https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs207/gtdb-rs207.genomic.k51.zip

https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs207/gtdb-rs207.taxonomy.with-strain.csv.gz


SKETCHES=/mnt/bigdata/linuxhome/millican/ref_db/sourDB/sketches_${1}.txt
ls /mnt/bigdata/linuxhome/millican/ref_db/sourDB/sigs/*/$1/*.sig.gz >> $SKETCHES
sourmash index genbank-${1}.sbt.zip --from-file $SKETCHES



ref=/mnt/bigdata/linuxhome/millican/ref_db/sourmash
$ref/genbank-2022.03-viral-k21.zip
$ref/genbank-2022.03-archaea-k21.zip
$ref/genbank-2022.03-protozoa-k21.zip
$ref/genbank-2022.03-fungi-k21.zip
$ref/genbank-2022.03-bacteria-k21.zip

$(ls $ref/references/plant/*.sig.gz)

# first 15
sourmash_ref_build/data/genomes/plant/*.fna.gz

#!/bin/bash
source /home/glbrc.org/millican/.bashrc
mamba activate sourmash
export DIR=/home/glbrc.org/millican/sourmash_ref_build/data
export REF=/mnt/bigdata/linuxhome/millican/ref_db/sourDB
export OUT=/mnt/bigdata/linuxhome/millican/ref_db/sourDB/sigs/$1
sourmash_sketch()
{
    NAME=$(basename -s .fna.gz $1)
    sketch_name=$(echo ${NAME:0:15})
    sourmash sketch dna -p k=21,scaled=500 $1 -o $OUT/${NAME}-k21.sig.gz --name $sketch_name
    sourmash sketch dna -p k=31,scaled=500 $1 -o $OUT/${NAME}-k31.sig.gz --name $sketch_name
    sourmash sketch dna -p k=51,scaled=500 $1 -o $OUT/${NAME}-k51.sig.gz --name $sketch_name
}

export -f sourmash_sketch

parallel -j 8 sourmash_sketch ::: $(ls /home/glbrc.org/millican/sourmash_ref_build/data/genomes/$1/*.fna.gz)