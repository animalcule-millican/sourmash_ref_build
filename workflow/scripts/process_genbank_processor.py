#!/usr/bin/env python3
import argparse
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import concurrent.futures
import os
import pandas as pd
import pickle
import taxopy
import multiprocessing

def arg_parser():
    parser = argparse.ArgumentParser(description='Reformat fasta headers to be used with taxonomy assignment in the DADA2 package')
    parser.add_argument('-i', '--input', help='Input directory containing the genbank files to process', required=True)
    parser.add_argument('-o', '--output', help='Output directory for writing fasta files', required=True)
    parser.add_argument('-t', '--taxonomy', help='Path to output taxonomy lineage file', required=True)
    parser.add_argument('-p', '--tax_pickle', help='Path to a previously built pickled tax dict', required=False, default='/work/adina/millican/.tools/taxdb/taxdb.pkl')
    parser.add_argument('-n', '--cpus', help='Number of cpus to use', required=False, default=os.cpu_count(), type=int)
    args = parser.parse_args()
    return args

def genbank_extractor(input_file, output_dir):
    gb_dict = {}
    with open(input_file, 'r') as f:
        record = SeqIO.read(f, "genbank")
        accession = record.dbxrefs[2].split(':')[1]
        taxid = record.features[0].qualifiers['db_xref'][0].split(':')[1]
        rec_id = record.id
        rec_name = record.name
        lineage = ""
        for item in record.annotations["taxonomy"]:
            lineage = lineage + ";" + item
        seq_record = SeqRecord(Seq(record.seq), id=rec_id, name=rec_name, description=f"{record.description} | {lineage}")
        with open(f"{output_dir}/{accession}_{rec_id}.fna", 'w') as outfile:
            SeqIO.write(seq_record, outfile, "fasta")
    gb_dict[accession] = {"accession": accession, "taxid": int(taxid), 'genome_id': rec_id, 'lineage': lineage}
    return gb_dict

def build_tax_db():
    taxdb = taxopy.TaxDb(nodes_dmp="/work/adina/millican/.tools/taxdb/nodes.dmp", names_dmp="/work/adina/millican/.tools/taxdb/names.dmp")
    with open('/work/adina/millican/.tools/taxdb/taxdb.pkl', 'wb') as output:
        pickle.dump(taxdb, output, pickle.HIGHEST_PROTOCOL)
    return(taxdb)

def load_tax_db():
    with open("/work/adina/millican/.tools/taxdb/taxdb.pkl", 'rb') as f:
        taxdb = pickle.load(f)
    return taxdb

def parse_tax_ranks(taxa):
    try:
        domain = taxa.rank_name_dictionary['superkingdom']
    except KeyError:
        domain = "NA"
    try:
        phylum = taxa.rank_name_dictionary['phylum']
    except KeyError:
        phylum = "NA"
    try:
        class_ = taxa.rank_name_dictionary['class']
    except KeyError:
        class_ = "NA"
    try:
        order = taxa.rank_name_dictionary['order']
    except KeyError:
        order = "NA"
    try:
        family = taxa.rank_name_dictionary['family']
    except KeyError:
        family = "NA"
    try:
        genus = taxa.rank_name_dictionary['genus']
    except KeyError:
        genus = "NA"
    try:
        species = taxa.rank_name_dictionary['species']
    except KeyError:
        species = "NA"
    return(domain, phylum, class_, order, family, genus, species)

def get_taxonomy(gb_dict, acc, taxdb, tax_dict, lock):
    taxid = gb_dict[acc]['taxid']
    accession = acc
    taxa = taxopy.Taxon(taxid, taxdb)
    domain, phylum, class_, order, family, genus, species = parse_tax_ranks(taxa)
    with lock:
        tax_dict[accession] = {"ident": accession, "taxid": taxid, "domain": domain, "phylum": phylum, "class": class_, "order": order, "family": family, "genus": genus, "species": species, 'seq': seq_dict[key]['accession']}


def main():
    args = arg_parser()
    if os.path.isfile(args.tax_pickle):
        taxdb = load_tax_db()
    else:
        taxdb = build_tax_db()
    
    # Create a Manager and a Lock for the tax_dict
    manager = multiprocessing.Manager()
    tax_dict = manager.dict()
    lock = manager.Lock()
    
    # Use os.scandir() to get a list of files in the input directory
    files = [entry.path for entry in os.scandir(args.input) if entry.is_file()]
    
    # Create a ProcessPoolExecutor for multiprocessing the processing of each file
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.cpus) as executor:
        # Submit a genbank_extractor task for each file in the directory
        futures = [executor.submit(genbank_extractor, file, args.output) for file in files]
        # Wait for all tasks to complete
        concurrent.futures.wait(futures)
        # Use a dictionary comprehension to update the gb_dict with the output of each task
        gb_dict = {acc: result for future in futures for acc, result in future.result().items()}
    
    # Use another ProcessPoolExecutor to get the taxonomy for each accession
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.cpus) as executor:
        # Submit a get_taxonomy task for each accession in the gb_dict
        futures = [executor.submit(get_taxonomy, gb_dict, acc, taxdb, tax_dict, lock) for acc in gb_dict.keys()]
        # Wait for all tasks to complete
        concurrent.futures.wait(futures)
    
    # Convert the tax_dict to a dataframe and write to file
    df = pd.DataFrame.from_dict(tax_dict, orient='index')
    df.to_csv(args.taxonomy, sep='\t', index=False)

if __name__ == '__main__':
    main()