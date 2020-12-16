#!/bin/python
import os   

configfile: 'config.yaml'

THREADS=20


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
        expand("01_canu/{ID}/ONT.assembly.done", ID=GENOMEIDS),
        expand("01_flye/{ID}", ID=GENOMEIDS),
        expand("02_prokka/{ID}", I=GENOMEIDS),
        "03_pacbio_metagenomes_flye",
        "04_metaflye_referenceblast/reference_metaflye.m6"


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
        "tools",
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
        
rule flye_assembly_pipeline:
    input:
        ONTFASTQ = "ontfastq/{ID}.fastq.gz",
    output:
        ONTASSEMBLY = directory( os.path.join('01_flye','{ID}') ),
    params:
        SIZE = lambda wildcards: ID2SIZE[wildcards.ID]
    wildcard_constraints:
        ID = '\w+'
    threads: THREADS
    conda:
        "envs/flye.yaml"
    shell:
        """
        flye --nano-raw {input.ONTFASTQ} --out-dir {output.ONTASSEMBLY} \
        -g {params.SIZE} \
        -t {threads} \
        -i 1 \
        --plasmids
        bash scripts/splitfasta.sh {output.ONTASSEMBLY}/assembly.fasta {output.ONTASSEMBLY}/individual_contigs
        """


### Trying to assemble the PacBio sequenced complex metagenome sample
rule metaflye_assembly_pipeline:
    input:
        PACBIOFASTQ = "pacbiofastq/Pacbio_reads.fq.gz"
    output:
        ONTASSEMBLY = directory( "03_pacbio_metagenomes_flye" ),
    threads: THREADS
    conda:
        "envs/flye.yaml"
    shell:
        """
        flye --pacbio-raw {input.PACBIOFASTQ} --out-dir {output.ONTASSEMBLY} \
        --meta \
        -t {threads} \
        -i 1 \
        --plasmids

        bash scripts/splitfasta.sh {output.ONTASSEMBLY}/assembly.fasta {output.ONTASSEMBLY}/individual_contigs
        """



rule evalute_metaflye_assembly:
    input:
        reference_genomes = "reference_genomes/all_reference_genomes.fna",
        metaflye_assembly = "03_pacbio_metagenomes_flye/assembly.fasta"
    threads: THREADS
    output:
        blastfile = "04_metaflye_referenceblast/reference_metaflye.m6"
    params: 
        BLAST_PARAMS = "-task megablast -evalue 0.001 -perc_identity 75 -max_target_seqs 15 -max_hsps 1"
    envmodules:
        "tools",
        "perl/5.24.0",
        "ncbi-blast/2.8.1+"
    shell:
        """
        makeblastdb -in {input.reference_genomes} -dbtype nucl
        blastn {params.BLAST_PARAMS} \
            -db {input.reference_genomes} \
            -query {input.metaflye_assembly} \
            -out {output.blastfile} \
            -outfmt '6 std qlen slen' -num_threads {threads}
        """



        
### Assembly Polishing 

### Match Genome IDs to Short-read sequence files for Assembly polishing


rule align_paf:
	#Align short reads to a fasta (draft assembly), storing the result in .paf format.
	input:
		draft_assembly = '',
        FQ1 = ,
		FQ2 = 
	output:
		"{ID}.paired-reads.paf"
	threads: THREADS
	conda:
        "envs/minimap2.yaml"
	shell:
		"minimap2 -t {threads} -x sr {input} > {output}"


### Polish circular assembblies 
rule circlator:
    input:
        canu_assembly = "01_canu/{ID}/ONT.contigs.fasta",
        flye_assembly = "01_flye/{ID}/assembly.fasta",
        canu_corrected_reads = "01_canu/{ID}/ONT.correctedReads.fasta.gz"
    output:
        canu_circ_out = "02_circ_canu/{ID}",
        flye_circ_out = "02_circ_flye/{ID}"
    wildcard_constraints:
        ID = '\w+'
    threads: THREADS
    conda:
        "envs/circlator.yaml"
    log:
        "log/circlator/{ID}"
    shell:
        """
        circlator all {input.canu_assembly} {input.canu_corrected_reads} {output.canu_circ_out}
        #circlator all {input.flye_assembly} {input.canu_corrected_reads} {output.flye_circ_out}
        """

#### Genome annotation
rule run_prokka:
    input:
        contigs = "01_flye/{ID}/assembly.fasta"
    output:
        prokkaout = directory( "02_prokka/{ID}" )
    params:
        genomeid = "{ID}"
    wildcard_constraints:
        ID = '\w+'
    threads: THREADS
    conda:
        "envs/prokka.yaml"
    shell:
        """
        prokka --outdir {output.prokkaout} --prefix {params.genomeid} {input.contigs}
        """

rule interproscan_annotation:
    input:
        proteins = ""
    output:
        interproout = directory("")
    wildcard_constraints:
        ID = '\w+'
    threads: THREADS
    envmodules:
        "tools",
        "anaconda3/4.4.0",
        "perl/5.24.0",
        "java/1.8.0-openjdk",
        "interproscan/5.36-75.0"
    shell:
    """
    interproscan.sh -goterms -pa -f tsv -appl Pfam,TIGRFAM --cpu {threads} \
	-i {input.proteins} \
	-b {output.interproout}
    """