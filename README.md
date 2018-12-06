# Consensify

DOCUMENTATION FOR Consensify v0.1

Axel Barlow and Johanna L. A. Paijmans, December 2018

emails: axel.barlow.ab@gmail.com, paijmans.jla@gmail.com


## INTRODUCTION
Consensify is a method for generating a consensus pseudohaploid genome sequence with greatly reduced error rates compared to standard pseudohaploidisation. The method is described in full and tested in the associated publication (Barlow et al. 2018). Briefly, for each position of the reference genome, three bases are selected from the read stack at random. If two or three out of three reads agree, then that base is retained. If only two reads are present, but they agree, then that base is also retained. In either case, if no two reads agree, then an N is entered for that position. If coverage is < 2, or above a maximum depth specified by the user, then an N is entered for that position. An example is shown below. The table summarises a read stack by the number of bases observed in columns (totA, totC, totG, totT) at each position of the reference genome (represented by sequential rows). The Consensify sequence for this read stack would be TGNAC.

totA	totC	totG	totT

0	0	1	2
0	0	2	0
1	0	0	1
4	0	0	0
0	4	1	0


## INPUT DATA
Consensify takes 3 files as input. Small example files are included with the Consensify distribution, in the “examples” directory:

eg.counts – a file containing the base counts at each position of the reference genome (formatted as shown in the table above)

eg.pos – a file containing a 3 column table: scaffold name, position, read depth

scaffold_lengths.txt – file containing a 2 column table: scaffold name, length

The .counts and .pos files can be generated from a standard bam file using the -doCounts function in angsd (Korneliussen et al. 2014), or using any method chosen by the user. angsd is especially convenient since it runs fast and allows a very wide range of useful filters to be applied: e.g. minimum map and base quality, exclusion of transitions, exclusion of specific scaffolds, and the option to exclude a specified number of terminal nucleotides from each read. An example angsd command to generate the input files would be:

angsd -doCounts 1 -minQ 30 -minMapQ 30 -dumpCounts 3 -rf scaffolds_over_1MB.txt -i in.bam -out out

This command would exclude bases with map and base quality < 30, and only collect base counts for large scaffolds > 1MB (-rf function, see angsd documentation). Your input bam is "in.bam" (-i option) and your output .pos and .counts files will have the prefix "out" (-out option). -doCounts reports the frequency of bases, and -dumpCounts  3 reports the sum occurrence of each base. 

The .lengths file has to be created by the user. See the example scaffold_lengths.txt in the example directory. It's a simple 2-column tab delimited text file containing scaffold names and their length in nucleotides, respectively. A suggested approach for generated this file is to use “samtools faidx reference.fasta”, and then extracting the first and second column from the resulting .fai file (e.g. awk ‘{print $1, $2}’ reference.fasta.fai). Note that the scaffold name should only include that preceding the first whitespace " " delimiter. The order of scaffolds should match that in the reference used for mapping. If you have excluded any scaffolds from your angsd analysis, they should also be excluded from the .lengths file. 


## RUNNING Consensify
Consensify is a perl script which should run on any UNIX system. Windows is untested and unsupported, but may be possible. We have tested it on Scientific Linux v6 and Ubuntu versions 14.04 and 16.04. 

To run Consensify, cd to the directory containing the script and enter:

perl Consensify.pl

This should return the following error message, which describes the 5 arguments required to run Consensify:

ERROR: script needs five arguments, in this order:
    name (and location) of .pos file
    name (and location) of .counts file
    name (and location) of sequence IDs and lengths
    name of output file
    depth threshold for exclusion

To run Consensify on the example dataset with a maximum read depth filter of 5 (i.e. only consider positions covered by 5 reads or fewer), enter the following:

perl makeHaploid_05.pl ./examples/eg.pos ./examples/eg.counts ./examples/scaffold_lengths.txt example.fa 5

A message like this should  be printed to the screen (you can also direct it to an output file using > if you wish to save this information):

running script  
      depthsFile: ./examples/eg.pos
      countsFile: ./examples/eg.counts
      seqLenFile: ./examples/scaffold_lengths.txt
      outputFile: example.fa
      k         : 5         

hash is done! 
processing 
   ...scaffold1
   ...scaffold2

 all done! output is in file example.fa
positions processed: 115

The last line is the number of called bases successfully written to the Consensify pseudohaploid sequence. Note the exact number may vary between runs due the the random sampling of reads. The finished Consensify sequence in fasta format is example.fa, and should look similar to this:

>scaffold1
NTTGATCAACGGAACAAGTTACCCTAGGGATAACAGCGCAATCCTATTCAAGAGTNNNNN
>scaffold2
TCGACAATAGGGTTTACGACCTCGATGTTGGATCAGGACATCCTAATGGTGCAGCAGCTG

We strongly recommend that you carefully examine this example file alongside the input eg.counts file to understand the behaviour of the method. You may also wish to test different maximum depth cut offs and also change the base counts in the eg.counts file to test specific situations relevant to your own data. It is also useful to replicate analyses to see variability in the finished sequence due to random base sampling.


## COMPUTATIONAL REQUIREMENTS
Consensify runs on a single processor. On a system running Scientific Linux and with 16Gb RAM per CPU, we are generally able to compute a Consensify pseudohaploid sequence for a medium (~10x) coverage mammalian genome dataset in less than one day. Note that computational time increases asymptotically with sequencing coverage, since more positions are covered by > 2 reads.

The .pos and .counts files output by angsd are compressed (.gz), and must be uncompressed prior to computation with Consensify. The combined uncompressed size of these files can be around 40Gb. During the Consensify analysis, an intermediate file of equivalent size is generated. After computation, this file is automatically deleted, and the input .pos and .counts files can be compressed or deleted. The finished Consensify fasta will be around the size of the reference genome assembly, i.e. ~2.5 Gb for a mammal. If the computation terminates prematurely, then the intermediate file may not be deleted, and you may wish to delete it manually. Keep in mind that for the described computation at some stage >80Gb for disk space is being used. Thus, if you have a 1TB hard drive and run 12 such analysis simultaneously, you run the risk of running out of space. You have been warned - we are not responsible for killing your computer ;) 


## USING CONSENSIFY FOR YOUR OWN RESEARCH
We hope that Consensify is useful for your research. If you make use of it, then please remember to cite the original paper. If you use angsd to generate the input files, then you must also cite that publication and it is helpful to describe any filters used in detail, since these are likely to affect the resulting Consensify sequences. If you would like ideas on what to do with your Consensify sequences, then you may wish to consult the accompanying “tipsntricks.md” document for instructions on how to produce a multiple sequence alignment, calculate distance matrices, compute phylogenies, do population clustering analyses, and the D statistic test of admixture.

Finally if you like Consensify, if you need help, or if you have ideas on how Consensify could be made better, then please get in touch with us. We are always happy to talk about science and to discuss new and cool methods for evolutionary research :) 


## REFERENCES
Barlow A, Hartmann S, Gonzales J, Hofreiter M, Paijmans JLA (2018) Consensify: a method for generating pseudohaploid genome sequences from palaeogenomic datasets with reduced error rates.  BioRxiv ...

Korneliussen TS, Albrechtsen A, Nielsen R (2014) ANGSD : Analysis of Next Generation Sequencing Data. BMC Bioinformatics 15: 356.
