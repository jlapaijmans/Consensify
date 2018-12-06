#!/bin/sh

### This script extracts informative positions from aligned genomes (multi-fasta)
# Hacked together by Johanna Paijmans 14.11.2018

#### required software: 
# snp-sites (Page et al 2016) 	https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5320690/
# samtools (Li et al 2009)  		https://www.ncbi.nlm.nih.gov/pubmed/19505943

### USAGE: ./alignment_reductor.sh $1 $2 $3
# $1		scaffolds.txt 		scaffold names, without ">")		e.g.--- ls *.fa | cut -d'.' -f1 > fastanames.txt
# $2		fastanames.txt 	basenames fasta files)			e.g.--- cat sample.fa | grep ">" | sed s/">"/""/g > scaffolds.txt ---OR e.g.--- cat sample.fa.fai | awk '{print $1}' > scaffolds.txt
# $3		output.fa 		output file name

### variables
samtools=samtools-v0.1.19
snpsites=snp-sites

### preamble: 
# 
# faidx for each invidual
for i in $(cat $2); do $samtools faidx $i.fa; done;
# make necessary directory
mkdir reductor_scaffolds/

### the script
#1. extract individual scaffolds from each invididual (we found that snp-sites doesn't work for massive alignments, so we do it per scaffold)
for scaf in $(cat $1);
   do
   for ind in $(cat $2 | cut -d'.' -f1);
      #2. concatenate together (1 file per scaffold)
      do 
      $samtools faidx $ind.fa $scaf >> reductor_scaffolds/$scaf.concat.fa;
   done;
   #3. run snp-sites for each scaffold
   $snpsites reductor_scaffolds/$scaf.concat.fa -c > reductor_scaffolds/$scaf.concat.SNPonly.fa;
   #3a. safety removal of appended file
   rm reductor_scaffolds/$scaf.concat.fa;
done;
#4. paste each scaffold in SNPonly file together (result is 1 ind per fasta entry) & give sensible names from fasta_names.txt
paste -d'\0' reductor_scaffolds/*.concat.SNPonly.fa | (while read l; do read l;echo $l; done) | paste $2 - | awk '{print ">"$1"\n"$2}' > $3 

#5. clean up the intermediate files
rm -r ./reductor_scaffolds/

### REPORTS
echo -e "ReDuCToR is done\n\
Reduced sequence length = "$(awk 'FNR==2 {print length($0)}' $3)


### NOTES AND BUGS AND TODOS
# sequences need to be on a single line (no line break every 60bp)
# add help message
# change basenames.txt to filenames.txt? (for userfriendlyness)
# change scaffolds.txt to scaffold_lengths.txt? (as that's what consensify wants, for userfriendlyness)
