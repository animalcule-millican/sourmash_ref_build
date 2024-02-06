# Building a reference database for sourmash
- a snakemake workflow to download reference genomes from ncbi for:
    - bacteria
    - archaea
    - fungi
    - plant
    - protozoa
    - viral
- the workflow then creates sketches for all references and builds taxonomy/lineage files.
- This collection of references is for search metagenomic reads and bins and classifying the taxonomy. 