#!/bin/bash
source /home/glbrc.org/millican/.bashrc
mamba activate sourmash
mamba install rust maturin pytest pandas pip

cd $CONDA_PREFIX

git clone https://github.com/sourmash-bio/pyo3_branchwater.git

cd pyo3_branchwater

pip install -e .


PYTHONPATH=$CONDA_PREFIX/lib/python3.9/site-packages:/home/glbrc.org/millican/mambaforge/lib/python3.1/site-packagees:/home/glbrc.org/millican/mambaforge/lib/python3.11/site-packagees: