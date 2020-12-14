#!/bin/python
import os   

configfile: 'config.yaml'

THREADS=8


### Load Genome IDS
FASTQDIRECTORY = "ontfastq"
GENOMEIDS = []
GENOME2PATH = dict()
for (dirpath, dirnames, filenames) in os.walk(FASTQDIRECTORY):
    for f in filenames:
        ID = f.split('.')[0] 
        GENOMEIDS.append(ID)
        GENOME2PATH[ID] = os.path.join(FASTQDIRECTORY,f)

### MAP ID to Size - User needs to supple a comma-separated file with the Genome-ID used in the fastq files and their approximate size.
### i.e. ecoli,4.6m
ID2SIZE = dict()
with open('id2size','r') as infile:
    for line in infile:
        ID,size = line.strip().split(',')
        ID2SIZE[ID] = size

print(GENOMEIDS)
print(ID2SIZE)



rule target: 
    input:
        expand("01_canu/{ID}/ONT.assembly.done", ID=GENOMEIDS)


rule canu_assembly_pipeline:
    input:
        ONTFASTQ = "ontfastq/{ID}.fastq.gz",
    output:
        ONTASSEMBLY = directory( os.path.join('01_canu','{ID}') ),
        donefile = "01_canu/{ID}/ONT.assembly.done"
    params:
        SIZE = lambda wildcards: ID2SIZE[wildcards.ID]
    wildcard_constraints:
        ID = '\w+'
    threads: THREADS
    envmodules:
        "jre/1.8.0-openjdk",
        "perl/5.24.0",
        "canu/2.0",
        "gnuplot/5.0.6"
    shell:
        """
        canu -p ONT -d {output.ONTASSEMBLY} genomeSize={params.SIZE} -nanopore {input.ONTFASTQ}\
        masterThreads {THREADS} corMhapSensitivity=high useGrid=false

        echo "Done" > {output.donefile}
        """