# run tests with
# Rscript ./test_consensify.R

if(!require("testthat")) install.packages("testthat")
if(!require("ape")) install.packages("ape")


library(testthat)
# remove the old test fasta file if it still exists
if (file.exists("./test.fasta")){
  file.remove("./test.fasta")
  file.remove("./test_gz.fasta")
}
# test with a simple set with full scaffolds
test_that("consensify files with all scaffolds present",{
  system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta -seed 123")
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(length(test)==2)
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  expect_true(test$scaffold1[1]=="n")
  expect_true(test$scaffold1[49]!="n")
  expect_true(all(test$scaffold1[50:51]=="n"))
  expect_true(all(test$scaffold1[52:55]=="n")) # not called as depth =2
  expect_true(all(test$scaffold1[56:57]=="n")) # missing
  expect_true(test$scaffold1[58]=="n") # as depth is too low
  expect_true(test$scaffold1[59]=="n")
  expect_true(test$scaffold2[50]=="n")
  # now repeat with a gz file
  system2("../consensify_c"," -c eg_missingness.counts.gz -p eg_missingness.pos.gz -s scaffold_lengths.txt -o test_gz.fasta -seed 123")
  tools::md5sum("test.fasta") == tools::md5sum("test_gz.fasta")
  file.remove("./test.fasta")
  file.remove("./test_gz.fasta")
})

# test with a simple set with full scaffolds
test_that("consensify files with min 2 and random reads 3",{
  system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta -min 2 -max 99 -n_matches 2 -n_random_reads 3 -seed 123")
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(length(test)==2)
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  expect_true(test$scaffold1[1]=="n")
  expect_true(test$scaffold1[49]!="n")
  expect_true(all(test$scaffold1[50:51]=="n"))
  expect_true(all(!test$scaffold1[52:55]=="n")) # called as depth =2
  expect_true(all(test$scaffold1[56:57]=="n")) # missing
  expect_true(test$scaffold1[58]=="n") # as depth is too low
  expect_true(test$scaffold1[59]=="n")
  expect_true(test$scaffold2[50]=="n")
  system2("../consensify_c"," -c eg_missingness.counts.gz -p eg_missingness.pos.gz -s scaffold_lengths.txt -o test_gz.fasta -min 2 -max 99 -n_matches 2 -n_random_reads 3 -seed 123")
  tools::md5sum("test.fasta") == tools::md5sum("test_gz.fasta")
  file.remove("./test.fasta")
  file.remove("./test_gz.fasta")
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
