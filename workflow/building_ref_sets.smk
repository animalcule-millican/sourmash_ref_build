rule get_reports:
    input:
        taxa = "{taxa}",
        database = "{database}"
    output:
        "assembly_reports/{taxa}-{database}_assembly_summary.pkl"
    threads: 1
    resources:
        mem_mb = 4000
    shell:
        """
        scripts/pickle_assembly_reports.py {input.taxa} {output} {input.database}
        """

rule get_ncbi_files:
    input:
        "{refdir}/pkl/{taxa}-{database}_assembly_summary.pkl"
    output:
        "{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl"
    params:
        ref = config["reference_file_path"]
    threads: 6
    resources:
        mem_mb = 18000
    shell:
        """
        scripts/get_ftp_files.py {input} {params.ref} {output} 
        """

rule fetch_gtdb:
    output:
        "{refdir}/tmp/gtdb_genome_name_list.txt"
    params:
        refdir = config["reference_directory"]
    threads: 3
    resources:
        mem_mb=8000
    shell:
        """
        scripts/get_gtdb.sh {params.refdir}
        """

rule parse_gtdb_taxonomy:
    input:
        "{refdir}/tmp/gtdb_genome_name_list.txt"
    output:
        "{refdir}/taxonomy/bacteria_gtdb_taxonomy.csv",
        "{refdir}/taxonomy/archaea_gtdb_taxonomy.csv"
    threads: 1
    resources:
        mem_mb=4000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/parse_gtdb_metadata.py {input} {output}
        """

rule parse_ncbi_taxonomy:
    input:
        "{refdir}/pkl/{taxa}-{database}_assembly_summary.pkl"
    output:
        "{refdir}/taxonomy/{taxa}-{database}_ncbi_taxonomy.csv"
    threads: 1
    resources:
        mem_mb = 8000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/parse_ncbi_taxonomy_taxidTools.py {input} {output}
        """

rule join_taxonomy:
    input:
        expand("{refdir}/taxonomy/{taxa}_gtdb_taxonomy.csv", refdir = config["reference_directory"], taxa = config["taxa"]),
        expand("{refdir}/taxonomy/{taxa}-{database}_ncbi_taxonomy.csv", refdir = config["reference_directory"], taxa = config["taxa"], database = config["database"]),
    output:
        "{refdir}/taxonomy/reference_taxonomy.csv"
    params:
        refdir = config["reference_directory"]
    threads: 1
    resources:
        mem_mb=1000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/join-taxonomy.py {params.refdir} {input}
        """

rule genome_list: # checked: worked 2023-12-18 used refdir as arg for script
    input:
        expand("{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl", taxa = config["taxa"], database = config["database"], refdir = config["reference_directory"]),
        "{refdir}/tmp/gtdb_genomes.tar.gz".format(refdir=config["reference_directory"])
    output:
        expand("{refdir}/sketch_file/genome_info_{index}.csv", index = config["index"], refdir = config["reference_directory"])
    params:
        refdir = config["reference_directory"]
    threads: 1
    resources:
        mem_mb=1000
    conda:
        "prepare-reference"
    shell:
        """
        scripts/genome-list.py {params.refdir}
        """

rule split_ref_genomes:
    input:
        expand("{refdir}/tmp/gtdb_genome_name_list.txt", refdir = config["reference_directory"]),
        expand("{refdir}/pkl/ncbi_{taxa}-{database}_genome_info.pkl", refdir = config["reference_directory"], taxa = config["taxa"], database = config["database"])
    output:
        genome_list = "{refdir}/genome_files.txt",
        genome_file = expand("{{refdir}}/genome_files/genome_file.{index}", index=config["index"])
    shell:
        """
        find {wildcards.refdir}/genome -maxdepth 1 -name '*.fna.gz' > {wildcards.refdir}/genome_files.txt
        split -l $((($(wc -l < {wildcards.refdir}/genome_files.txt | awk '{{print $1}}')+49)/50)) {wildcards.refdir}/genome_files.txt {wildcards.refdir}/genome_files/genome_file.
        """

rule sketch_refs:
    input:
        genome_list = "{refdir}/sketch_file/genome_info_{index}.csv"
    output:
        "{refdir}/sketch/ref_sketch_{index}.zip"
    conda:
        "branchwater"
    threads: 12
    resources:
        mem_mb=30000
    shell:
        """
        sourmash scripts manysketch -p k=21,scaled=1000,abund -c {threads} -o {output} {input.genome_list}
        """
