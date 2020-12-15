# ONT_assembly / Whole Genome Nanopore-Seq assembly

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


## Wish list 

Inspiration from here:
https://bpa-csiro-workshops.github.io/intro-ngs-manuals/modules/btp-module-denovo-canu/denovo_canu/ 

- Add a module to the Flow with Circularise 
- A mapping module of Paired-end Reads as well for 
