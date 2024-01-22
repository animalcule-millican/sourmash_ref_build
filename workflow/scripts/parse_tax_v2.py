#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import os
import pandas as pd
import taxopy

def build_sour_tax(gen_dict, taxdb):
    tax_dict = {}
    for key in gen_dict.keys():
        try:
            dat_dict = taxopy.Taxon(gen_dict[key], taxdb).rank_name_dictionary
        except taxopy.exceptions.TaxidError:
            os.system(f"mv /home/glbrc.org/millican/ref_db/sourDB/signatures/*/k*/{key}.*.sig.gz /home/glbrc.org/millican/ref_db/sourDB/junk-sigs")
            continue
        superkingdom, phylum, taxclass, order, family, genus, species, strain = taxonomy(dat_dict)
        tax_dict[key] = {'ident': key, 'taxid': gen_dict[key], "superkingdom": superkingdom, "phylum": phylum, "class": taxclass, "order": order, "family": family, "genus": genus, "species": species, "strain": strain}
        #try:
        #    tax_dict[key] = {'ident': key, 'taxid': gen_dict[key], "superkingdom": dat_dict['kingdom'], "phylum": dat_dict['phylum'], "class": dat_dict['class'], "order": dat_dict['class'], "family": dat_dict['family'], "genus": dat_dict['genus'], "species": dat_dict['species']}
        #except KeyError:
        #   print(dat_dict)
            #tax_dict[key] = {'ident': key, 'taxid': gen_dict[key], "superkingdom": dat_dict['superkingdom'], "phylum": dat_dict['phylum'], "class": dat_dict['class'], "order": dat_dict['class'], "family": 'unknown', "genus": dat_dict['genus'], "species": dat_dict['species']}
    return tax_dict

def taxonomy(dat_dict):
    try:
        superkingdom = dat_dict['kingdom']
    except KeyError:
        superkingdom = 'Unclassified'
    try:   
        phylum = dat_dict['phylum']
    except KeyError:
        phylum = 'Unclassified'
    try:
        taxclass = dat_dict['class']
    except KeyError:
        taxclass = 'Unclassified'
    try:
        order = dat_dict['class']
    except KeyError:
        order = 'Unclassified'
    try:  
        family = dat_dict['family']
    except KeyError:
        family = 'Unclassified'
    try:
        genus = dat_dict['genus']
    except KeyError:
        genus = 'Unclassified'
    try:
        species = dat_dict['species']
    except KeyError:
        species = 'Unclassified'
    try:
        strain = dat_dict['strain'] 
    except KeyError:
        strain = 'Unclassified'
    return superkingdom, phylum, taxclass, order, family, genus, species, strain

def parse_reports(input_dir):
    parsed_dict = {}
    files = [os.path.join(input_dir, file_name) for file_name in os.listdir(input_dir)]
    for file_name in files:
        taxid = None
        genbank = None
        with open(file_name, 'r') as f:
            for line in f:
                if line.find('# Taxid:') != -1:
                    taxid = line.split(': ')[1].strip()
                if line.find('# GenBank assembly accession:') != -1:
                    genbank = line.split(': ')[1].strip()
                if taxid and genbank:
                    parsed_dict[genbank] = int(taxid)
                    # Reset for next potential pair within the same file
                    taxid = None
                    genbank = None
                    break
    return parsed_dict

def build_tax_db(taxdir):
    taxdb = taxopy.TaxDb(nodes_dmp=f"{taxdir}/nodes.dmp", names_dmp=f"{taxdir}/names.dmp", merged_dmp=f"{taxdir}/merged.dmp")
    return taxdb

def arg_parser():
    parser = argparse.ArgumentParser(description='Process files to remove headers and prefixes before file names.')
    parser.add_argument('-i', '--input', required=True, help='Input directory containing the files.')
    parser.add_argument('-o', '--output', required=True, help='Output file for processed assembly reports.')
    parser.add_argument('-d', '--taxdir', required=False, help='Directory containing taxdmp files.', default="/home/glbrc.org/millican/ref_db/taxdmp")
    args = parser.parse_args()
    return args

def main():
    args = arg_parser()
    taxdb = build_tax_db(args.taxdir)
    report_dict = parse_reports(args.input)
    taxonomy = build_sour_tax(report_dict, taxdb)
    df = pd.DataFrame.from_dict(taxonomy, orient='index')
    df.to_csv(args.output, sep=',', index=False)

if __name__ == '__main__':
    main()

