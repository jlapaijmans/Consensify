# Consensify

Documentation for Consensify v2

*The manuscript accompanying this source is available on BioRxiv: https://www.biorxiv.org/content/early/2018/12/18/498915?rss=1*

Axel Barlow, Johanna L. A. Paijmans, Andrea Manica

Updtaed: January 2024

emails: axel.barlow.ab@gmail.com, paijmans.jla@gmail.com

## Version log

### Version 2

Andrea Manica recoded consensify in C++, and also expanded the custom input options. In addition to `-min` minimum covierage and `-max` maximum coverage, we now also have `-n_matches` specifying how many bases need to match for acccepting abase and `-n_random_reads` the number of reads are randomly sampled from the read stack. The manual below is updated to reflect the new version.

## Introduction
Consensify is a method for generating a consensus pseudohaploid genome sequence with greatly reduced error rates compared to standard pseudohaploidisation. The method is described in full and tested in the associated publication (Barlow et al. 2018). Briefly, for each position of the reference genome, three bases are selected from the read stack at random. If two or three out of three reads agree, then that base is retained. If only two reads are present, but they agree, then that base is also retained. In either case, if no two reads agree, then an N is entered for that position. If coverage is < 2, or above a maximum depth specified by the user, then an N is entered for that position. An example is shown below. The table summarises a read stack by the number of bases observed in columns (totA, totC, totG, totT) at each position of the reference genome (represented by sequential rows). The Consensify sequence for this read stack would be TGNAC.

    totA	totC	totG	totT
    0	0	1	2
    0	0	2	0
    1	0	0	1
    4	0	0	0
    0	4	1	0

## Compiling Consensify

After cloning this repo, navigate to it and compile consensify using

```
g++ consensify_c.cpp -o consensify_c -std=c++11
```


## Input data
Consensify takes 3 files as input. Small example files are included with the Consensify distribution, in the “examples” directory:

`examples/eg_missingness.counts` – a file containing the base counts at each position of the reference genome (formatted as shown in the table above)

`examples/eg_missingness.pos` – a file containing a 3 column table: scaffold name, position, read depth

`examples/scaffold_lengths_missingness.txt` – file containing a 3 column table: scaffold name, start, end

The .counts and .pos files can be generated from a standard bam file using the -doCounts function in angsd (Korneliussen et al. 2014), or using any method chosen by the user. angsd is especially convenient since it runs fast and allows a very wide range of useful filters to be applied: e.g. minimum map and base quality, exclusion of transitions, exclusion of specific scaffolds, and the option to exclude a specified number of terminal nucleotides from each read. An example angsd command to generate the input files would be:

`angsd -doCounts 1 -minQ 30 -minMapQ 30 -dumpCounts 3 -rf scaffolds_over_1MB.txt -i in.bam -out out`

This command would exclude bases with map and base quality < 30, and only collect base counts for large scaffolds > 1MB (-rf function, see angsd documentation). Your input bam is "in.bam" (-i option) and your output .pos and .counts files will have the prefix "out" (-out option). -doCounts reports the frequency of bases, and -dumpCounts  3 reports the sum occurrence of each base. 

The .lengths file has to be created by the user. See the example scaffold_lengths.txt in the example directory. It's a simple 2-column tab delimited text file containing scaffold names and their length in nucleotides, respectively. A suggested approach for generated this file is to use “samtools faidx reference.fasta”, and then extracting the first and second column from the resulting .fai file (e.g. awk ‘{print $1, $2}’ reference.fasta.fai). Note that the scaffold name should only include that preceding the first whitespace " " delimiter. The order of scaffolds should match that in the reference used for mapping. If you have excluded any scaffolds from your angsd analysis, they should also be excluded from the .lengths file. 


## Running Consensify
Consensify is a perl script which should run on any **UNIX** system. Windows is untested and unsupported, but may be possible. We have tested it on **Scientific Linux v6** and **Ubuntu** LTS versions 2014-2022.

To run Consensify, cd to the directory containing the executable and enter:

`./consensify_c`

This should return an error message, as you've given no input. To see the inputs requuired, type

`./consensify_c -h`

which will return

```
welcome to consensify_c v2
Available options:

-p filename(with path) of the positions file (required)
-c filename(with path) of the counts file (required)
-o filename(with path) of the output fasta (required
-min minimum coverage for which positions should be called (defaults to 2)
-max maximum coverage for which positions should be called (defaults to 100)
-n_matches number of matches required to call a position (defaults to 2)
-n_random_reads number of random reads used (note that fewer reads might be used if a position has depth<n_random_reads (defaults to 3)
-v verbose output to stout
-h a list of available options (note that other options will be ignored)
example usage: consensify_c -c eg.counts -p eg.pos -o eg.fasta
```

To run Consensify on the example dataset, enter the following:

 `consensify_c -c examples/eg_missingness.counts -p examples/eg_missingness.pos -s examples/scaffold_lengths_missingness.txt -o missing.fasta`

A message like this should  be printed to the screen

```
welcome to consensify_c v2
eg_missingness.counts
all done
```

The finished Consensify sequence in fasta format is example.fa, and should look similar to this:

```
>scaffold1
TTGACACGAAAGTTCCTGGAAACACGCATCTTTCGAGTN
>scaffold2
ACACAAGGGTTACACTGATTGGAAGGCACTAATGTGCGAGTG
```

We strongly recommend that you carefully examine this example file alongside the input eg.counts file to understand the behaviour of the method. You may also wish to test different min/max depth cut offs, the number of reads sampled, number of matches. It is also useful to replicate analyses to see variability in the finished sequence due to random base sampling.


## Computational requirements

We have not run extensive testing of the new C++ version of consensify, so although it is of course a lot faster than the old Perl version, we don't know how much faster or how much RAM it needs. You have been warned - we are not responsible for killing your computer ;) 

The .pos and .counts files output by angsd are compressed (.gz), and must be uncompressed prior to computation with Consensify. The combined uncompressed size of these files can be around 40Gb. During the Consensify analysis, an intermediate file of equivalent size is generated. After computation, this file is automatically deleted, and the input .pos and .counts files can be compressed or deleted. The finished Consensify fasta will be around the size of the reference genome assembly, i.e. ~2.5 Gb for a mammal. If the computation terminates prematurely, then the intermediate file may not be deleted, and you may wish to delete it manually. 


## Using Consensify for your own research
We hope that Consensify is useful for your research. If you make use of it, then please remember to cite the original paper. If you use angsd to generate the input files, then you must also cite that publication and it is helpful to describe any filters used in detail, since these are likely to affect the resulting Consensify sequences. If you would like ideas on what to do with your Consensify sequences, then you may wish to consult the accompanying “tipsntricks.md” document for instructions on how to produce a multiple sequence alignment, calculate distance matrices, compute phylogenies, do population clustering analyses, and the D statistic test of admixture.

Finally if you like Consensify, if you need help, or if you have ideas on how Consensify could be made better, then please get in touch with us. We are always happy to talk about science and to discuss new and cool methods for evolutionary research :) 


## References
* Barlow A, Hartmann S, Gonzales J, Hofreiter M, Paijmans JLA (2018) Consensify: a method for generating pseudohaploid genome sequences from palaeogenomic datasets with reduced error rates.  BioRxiv ...

* Korneliussen TS, Albrechtsen A, Nielsen R (2014) ANGSD : Analysis of Next Generation Sequencing Data. BMC Bioinformatics 15: 356.


