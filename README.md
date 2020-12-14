# ONT_assembly / Whole Genome Nanopore-Seq assembly

## How do use it 


```
- https://github.com/joacjo/ONT_assembly.git
- Edit config.yaml (i.e. set the directory of Fastq files)  
- Ensure that each genome file in the Fastq file (only PacBio or Nanopore format) directory is named accordingly:
  - `fastqdirectory/yersinia.fastq` or `fastqdirectory/yersinia.sample2.fastq`. Basically, the Sample/Genome identifier needs to be separated from any other information in the file with a dot. 
- Setup the Genome2size as comma-seperated with the Genome identifier (i.e. yersinia)
  - yersinia,3.9m
```
