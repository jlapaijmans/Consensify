# run tests with
# Rscript ./test.consensify.R

library(testthat)
# remove the old test fasta file if it still exists
if (file.exists("./test/test.fasta")){
  file.remove("./test/test.fasta")
}
# test with a simple set with full scaffolds
system2("./consensify_c"," -c test/eg_missingness.counts -p test/eg_missingness.pos -s test/scaffold_lengths.txt -o test/test.fasta")
test <- ape::read.FASTA("./test/test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
expect_true(test$scaffold1[1]=="n")
expect_true(test$scaffold1[49]!="n")
expect_true(all(test$scaffold1[50:51]=="n"))
expect_true(all(test$scaffold1[52:55]!="n")) # called as depth =2
expect_true(test$scaffold1[58]=="n") # as depth is too low
expect_true(test$scaffold1[59]=="n")
expect_true(test$scaffold2[50]=="n")

# test for missing scaffolds at beginning middle and end, without filling
system2("./consensify_c"," -c test/eg_missingness.counts -p test/eg_missingness.pos -s test/scaffold_lengths_missing_scaffold.txt -o test/test.fasta")
test <- ape::read.FASTA("./test/test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test)==2)
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
file.remove("./test/test.fasta")


# test for missing scaffolds at beginning middle and end, without filling
system2("./consensify_c"," -c test/eg_missingness.counts -p test/eg_missingness.pos -s test/scaffold_lengths_missing_scaffold.txt -o test/test.fasta -no_empty_scaffold")
test <- ape::read.FASTA("./test/test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test)==5)
expect_true(length(test$scaffold0.5)==30)
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
file.remove("./test/test.fasta")
