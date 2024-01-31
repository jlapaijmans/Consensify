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
expect_true(length(test$scaffold2)==60)
file.remove("./test/test.fasta")
# test for extracting a window of the second scaffold
system2("./consensify_c"," -c test/eg_missingness.counts -p test/eg_missingness.pos -s test/scaffold_lengths_window.txt -o test/test.fasta")
test <- ape::read.FASTA("./test/test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
file.remove("./test/test.fasta")
# test for extracting a window of the second scaffold
system2("./consensify_c"," -c test/eg_missingness.counts -p test/eg_missingness.pos -s test/scaffold_lengths_missing_scaffold.txt -o test/test.fasta")
test <- ape::read.FASTA("./test/test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test)==2)
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==60)
file.remove("./test/test.fasta")