#!/bin/bash
source /home/glbrc.org/millican/.bashrc
mamba activate sourmash
source random_directory.sh
#ls /home/glbrc.org/millican/projects/oil/data/sourmash/samples/sketch/WT_TR_GHRAS_03.sig.gz > $TMPDIR/query-list.txt
#ls /home/glbrc.org/millican/projects/oil/data/sourmash/samples/sketch/*.sig.gz > query-list.txt
find /home/glbrc.org/millican/ref_db/sourDB/signatures/plant/k31 -name "*.sig" > $TMPDIR/ref-lists.txt

sourmash_gather()
{
    IN=/home/glbrc.org/millican/projects/oil/data/sourmash/samples/sketch/WT_TR_GHRAS_03.sig.gz
    NAME=$(basename -s .sig.gz $1)
    sourmash gather $IN $1 -o $TMPDIR/${NAME}.csv
}

export -f sourmash_gather

parallel --jobs 16 -a $TMPDIR/ref-lists.txt sourmash_gather

csvtk concat $TMPDIR/*.csv > $TMPDIR/WT_TR_GHRAS_03.gathered.csv

#rm -r $TMPDIR
