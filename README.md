# ONT_assembly 

Whole Genome Nanopore-Seq or PacBio assembly

## How do use it 

### Prepare file paths
```
- cd <where-do-you-wanna-go?>
- git clone https://github.com/joacjo/ONT_assembly.git
- Edit config.yaml (i.e. set the directory of Fastq files)  
- Ensure that each genome file in the Fastq file (only PacBio or Nanopore format) directory is named accordingly:
  - `fastqdirectory/yersinia.fastq` or `fastqdirectory/yersinia.sample2.fastq`. Basically, the Sample/Genome identifier needs to be separated from any other information in the file with a dot. 
- Setup the id2size as comma-seperated with the Genome identifier (i.e. yersinia)
 
$cat id2size
yersinia,3.9m
ecoli,3.8m 

etc. 
```

### Run the Snakemake Pipeline

```
$ snakemake -s Snakefile -j --use-conda --use-envmodules
```

### Noteworthy output files from Assembly
```
01_canu/*/ONT.contigs.fasta
01_canu/*/ONT.contigs.layout.tigInfo 
01_canu/*/ONT.correctedReads.fasta.gz
```


## Wish list 

Inspiration from here:
https://bpa-csiro-workshops.github.io/intro-ngs-manuals/modules/btp-module-denovo-canu/denovo_canu/ 
- Hybrid assembly and Plasmid assembly with Flye https://github.com/fenderglass/Flye 
- Add a module to the Flow with the Circlator feature for polishing Circular Genomes  (https://github.com/sanger-pathogens/circlator) 
- An integrative assembly module with Paired-end Reads for bolishing long read assemblies 

Circlator Notes:
The input is a genome assembly in FASTA format and corrected PacBio or nanopore reads in FASTA or FASTQ format. Circlator will attempt to identify each circular sequence and output a linearised version of it. It does this by assembling all reads that map to contig ends and comparing the resulting contigs with the input assembly.

The input assembly must not be too fragmented. Although Circlator will join contigs together, whenever it can identify contigs that can be unambiguously joined, its main aim is to circularize the core genome and plasmids. 
