# run tests with
# Rscript ./test_consensify.R

library(testthat)
# remove the old test fasta file if it still exists
if (file.exists("./test.fasta")){
  file.remove("./test.fasta")
}
# test with a simple set with full scaffolds
test_that("consensify files with all scaffolds present",{
  system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta")
  test <- ape::read.FASTA("./test.fasta")
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
  file.remove("./test.fasta")
})

# test for missing scaffolds at beginning middle and end, without filling
test_that("consensify files with missing scaffolds",{
  system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta")
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(length(test)==5)
  expect_true(length(test$scaffold0.5)==30)
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  file.remove("./test.fasta")
})


# test for missing scaffolds at beginning middle and end, without filling
test_that("consensify files with missing scaffolds, leaving them empty",{
  system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta -no_empty_scaffold")
test <- ape::read.FASTA("./test.fasta")
test <- as.character(test) ## cast it to character for easier testing
expect_true(length(test)==2)
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
file.remove("./test.fasta")
})


#test we raise an error
test_that("catch incorrect option",{
  err_code <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta -wrong_option")
expect_true(err_code==1)
})