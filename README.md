# Consensify


<!-- badges: start -->
[![conda-single-platform](https://github.com/jlapaijmans/Consensify/actions/workflows/test_cpp.yml/badge.svg)](https://github.com/jlapaijmans/Consensify/actions/workflows/test_cpp.yml)
<!-- badges: end -->


Documentation for Consensify v2

*The manuscript accompanying this source is published in Genes 2020: https://www.mdpi.com/2073-4425/11/1/50*

Axel Barlow, Johanna L. A. Paijmans, Andrea Manica

emails: axel.barlow.ab@gmail.com, paijmans.jla@gmail.com

## Version log

### Version 2

#### consensify_c v2.4.0

First official release of `consensify_c`. 
Also, `consensify_c` is now also available to install using conda: 
https://bioconda.github.io/recipes/consensify/README.html

#### consensify_c v2.3.9001

`consensify_c` can now take compressed .pos and .counts input files directly from `angsd`

#### consensify_c v2

Andrea Manica recoded consensify in C++, and also expanded the custom input options. In addition to `-min` minimum covierage and `-max` maximum coverage, we now also have `-n_matches` specifying how many bases need to match for acccepting abase and `-n_random_reads` the number of reads are randomly sampled from the read stack. The manual below is updated to reflect the new version.

## Introduction
Consensify is a method for generating a consensus pseudohaploid genome sequence with greatly reduced error rates compared to standard pseudohaploidisation. The method is described in full and tested in the associated publication (Barlow et al. 2018). Briefly, in the C version of the method the user specifies `min`, `-max`, `-n_matches`, `-n_random_reads`. If a position has less than `min` or more than `max` coverage, the position is called as an N. If a position passes the coverage filters, `-n_random_reads` are sampled. If at least `-n_matches` of bases match, that position is called. If no bases (or not enough bases) match, the position is called as N.

An example is shown below. The table summarises a read stack by the number of bases observed in columns (totA, totC, totG, totT) at each position of the reference genome (represented by sequential rows). 

    totA	totC	totG	totT
    0	0	1	2
    0	0	2	0
    1	0	0	1
    4	0	0	0
    0	4	1	0

For filters `-min 2 -max 99 -n_matches 2 -n_random_reads 3`, the Consensify sequence for this example would be TGNAC.

## Installing Consensify

### using conda

make sure you have bioconda channel set up:

`conda config --add channels bioconda`

and create a specific environment should you want to:

`conda create --name myenvname`

activate using: 

`conda activate myenvname`

then you can install consensify using:

`conda install consensify`

you can now run consensify using `consensify_c`

### compile from source

If you want to compile consenseify from source: clone this repo, navigate to it and compile consensify using:

```
g++ consensify_c.cpp -o consensify_c -lz
```


## Input data
Consensify takes 3 files as input. Small example files are included with the Consensify distribution, in the “test” directory:

`test/eg_missingness.counts.gz` – a file containing the base counts at each position of the reference genome (formatted as shown in the table above)

`test/eg_missingness.pos.gz` – a file containing a 3 column table: scaffold name, position, read depth

`test/scaffold_lengths_missingness.txt` – file containing a 3 column table: scaffold name, start, end. Requires header "name	start	end"

The .counts and .pos files can be generated from a standard bam file using the -doCounts function in `angsd` (Korneliussen et al. 2014), or using any method chosen by the user. angsd is especially convenient since it runs fast and allows a very wide range of useful filters to be applied: e.g. minimum map and base quality, exclusion of transitions, exclusion of specific scaffolds, and the option to exclude a specified number of terminal nucleotides from each read. An example angsd command to generate the input files would be:

`angsd -doCounts 1 -minQ 30 -minMapQ 30 -dumpCounts 3 -rf scaffolds_over_1MB.txt -i in.bam -out out`

This command would exclude bases with map and base quality < 30, and only collect base counts for large scaffolds > 1MB (-rf function, see angsd documentation). Your input bam is "in.bam" (-i option) and your output .pos and .counts files will have the prefix "out" (-out option). -doCounts reports the frequency of bases, and -dumpCounts  3 reports the sum occurrence of each base. 



## Running Consensify
Consensify is a C++ script which should run on any **UNIX** system. Windows is untested and unsupported, but may be possible. 

To run Consensify, enter:

`consensify_c`

This should return an error message, as you've given no input. To see the inputs requuired, type

`consensify_c -h`

which will return

```
consensify_c v2.4.0
Available options:

-p filename(with path) of the positions file (required)
-c filename(with path) of the counts file (required)
-s filename(with path) of the scaffold file (required)
-o filename(with path) of the output fasta (required
-min minimum coverage for which positions should be called (defaults to 3)
-max maximum coverage for which positions should be called (defaults to 100)
-n_matches number of matches required to call a position (defaults to 2)
-n_random_reads number of random reads used; note that fewer reads might be used if a position has depth<n_random_reads (defaults to 3)
-seed seed for the random number generator (if not set, random device is used to initialise the Marsenne-Twister)
-v if set, verbose output to stout
-no_empty_scaffold if set, empty scaffolds in the counts file are NOT printed in the fasta output
-h a list of available options (note that other options will be ignored)

example usage: consensify_c -c eg.counts -p eg.pos -o eg.fasta


```

To run Consensify on the example dataset, enter the following:

```
consensify_c -c test/eg_missingness.counts.gz -p test/eg_missingness.pos.gz -s test/scaffold_lengths_missing_scaffold.txt -o test/test.fasta
```

A message like this should  be printed to the screen

```
consensify_c v2.4.0
all done
```

The finished Consensify sequence in fasta format is example.fa, and should look similar to this:

```
>scaffold0.5
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
>scaffold1
NTTGANCNACNGAANNAGTTNNCCTNGGNANAACANCGCANTNCTNTTCNNGAGTNNNNN
>scaffold1.5
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
>scaffold2
TCNACNANAGGGNTTACNANCTNGATNNTGGANNAGGNCANCNTAATNGN
>scaffold2.1
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
```


The .lengths file for `consensify_c` has to be created by the user. See the example scaffold_lengths.txt in the example directory. It's a 3-column tab delimited text file containing scaffold names, and their start and end position. The column headers have to be "name  start   end". A suggested approach for generated this file is to use “samtools faidx reference.fasta”, and then extracting the first and second column from the resulting .fai file (e.g. awk ‘{print $1, $2}’ reference.fasta.fai). Note that the scaffold name should only include that preceding the first whitespace " " delimiter. The order of scaffolds should match that in the reference used for mapping. If you have excluded any scaffolds from your `angsd` analysis, they should also be excluded from the .lengths file. 

The default behaviour is that any empty scaffolds (where no reads were mapped/passed filters) are printed as an 'empty' scaffolds, made up of Ns. If you do not want this, you can use the `-no_empty_scaffold` flag which will result in no empty scaffolds in the fasta output.

We strongly recommend that you carefully examine this example file alongside the input eg.counts file to understand the behaviour of the method. You may also wish to test different parametrs such as min/max depth cut offs, the number of reads sampled, number of matches. It is also useful to replicate analyses to see variability in the finished sequence due to random base sampling.


## Computational requirements

We have not run extensive testing of the new C++ version of consensify, so although it is of course a lot faster than the old Perl version, we don't know how much faster or how much RAM it needs. You have been warned - we are not responsible for killing your computer ;) 


## Using Consensify for your own research
We hope that Consensify is useful for your research. If you make use of it, then please remember to cite the original paper. If you use angsd to generate the input files, then you must also cite that publication and it is helpful to describe any filters used in detail, since these are likely to affect the resulting Consensify sequences. If you would like ideas on what to do with your Consensify sequences, then you may wish to consult the accompanying “tipsntricks.md” document for instructions on how to produce a multiple sequence alignment, calculate distance matrices, compute phylogenies, do population clustering analyses, and the D statistic test of admixture.

Finally if you like Consensify, if you need help, or if you have ideas on how Consensify could be made better, then please get in touch with us. We are always happy to talk about science and to discuss new and cool methods for evolutionary research :) 


## References
* Barlow A, Hartmann S, Gonzales J, Hofreiter M, Paijmans JLA (2018) Consensify: a method for generating pseudohaploid genome sequences from palaeogenomic datasets with reduced error rates.  BioRxiv ...

* Korneliussen TS, Albrechtsen A, Nielsen R (2014) ANGSD : Analysis of Next Generation Sequencing Data. BMC Bioinformatics 15: 356.


