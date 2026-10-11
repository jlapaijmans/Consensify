# run tests with
# Rscript ./test_consensify.R
#
# Test data:
# - eg_missingness.counts / eg_missingness.pos: counts of each base (A, C, G, T) and depth
#   for each position with reads, for two scaffolds (scaffold1 and scaffold2). Several positions
#   are deliberately absent (no reads), and depth decreases along scaffold1 (4 reads up to
#   position 30, 3 reads up to 49, 2 reads at 52-55, 1 read at 58), so that we can test the
#   depth filters. The .gz versions contain the same data, compressed.
# - scaffold_lengths.txt: the two scaffolds in the data (scaffold1 of length 60, scaffold2 of length 50)
# - scaffold_lengths_missing_scaffold.txt: as above, but with extra scaffolds that have no reads
#   (scaffold0.5 at the beginning, scaffold1.5 in the middle, scaffold2.1 at the end)
# - eg_single_scaffold.counts / eg_single_scaffold.pos / scaffold_lengths_single_scaffold.txt:
#   only scaffold1 from the files above, mimicking a single-scaffold analysis such as a mitogenome
#
# Default settings of consensify_c (used unless overridden): -min 3, -max 100, -n_matches 2, -n_random_reads 3
#
# Note that ape::read.FASTA returns lower case bases, so missing data is "n"

if(!require("testthat", quietly = TRUE)) install.packages("testthat")
if(!require("ape", quietly = TRUE)) install.packages("ape")


library(testthat)
# remove the old test fasta file if it still exists
if (file.exists("./test.fasta")){
  file.remove("./test.fasta")
}
if (file.exists("./test_gz.fasta")){
  file.remove("./test_gz.fasta")
}

# test with a simple set with full scaffolds, using default settings
test_that("consensify files with all scaffolds present",{
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta -seed 123",
          stdout=TRUE)
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  # both scaffolds are output, with the lengths given in the scaffold file
  expect_true(length(test)==2)
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  expect_true(test$scaffold1[1]=="n") # no reads at position 1 (pos file starts at 2), so padded with N
  expect_true(all(test$scaffold1[4]=="g")) # has 4 G's so should be G
  expect_true(test$scaffold1[49]!="n") # depth 3 (= min) with 3 C's, so it is called
  expect_true(all(test$scaffold1[50:51]=="n")) # missing from the pos file
  expect_true(all(test$scaffold1[52:55]=="n")) # not called as depth =2 (below min of 3)
  expect_true(all(test$scaffold1[56:57]=="n")) # missing
  expect_true(test$scaffold1[58]=="n") # as depth is too low (depth 1)
  expect_true(test$scaffold1[59]=="n") # missing at the end of the scaffold, padded up to length 60
  expect_true(test$scaffold2[50]=="n") # missing at the end of the scaffold, padded up to length 50
  # now repeat with a gz file; with the same seed, output should be identical
  res <- system2("../consensify_c"," -c eg_missingness.counts.gz -p eg_missingness.pos.gz -s scaffold_lengths.txt -o test_gz.fasta -seed 123",
                 stdout = TRUE)
  expect_true(unname(tools::md5sum("test.fasta")) == unname(tools::md5sum("test_gz.fasta")))
  file.remove("./test.fasta")
  file.remove("./test_gz.fasta")
})

# test lowering the minimum depth to 2, so that positions 52-55 of scaffold1 (depth 2) can now be called
test_that("consensify files with min 2 and random reads 3",{
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta -min 2 -max 99 -n_matches 2 -n_random_reads 3 -seed 123",
                 stdout=TRUE)
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(length(test)==2)
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  expect_true(test$scaffold1[1]=="n") # missing
  expect_true(test$scaffold1[49]!="n") # depth 3, all C, so called
  expect_true(all(test$scaffold1[50:51]=="n")) # missing
  expect_true(all(!test$scaffold1[52:55]=="n")) # called as depth =2, and both reads agree (n_matches 2)
  expect_true(all(test$scaffold1[56:57]=="n")) # missing
  expect_true(test$scaffold1[58]=="n") # as depth is too low (depth 1 < min 2)
  expect_true(test$scaffold1[59]=="n") # missing
  expect_true(test$scaffold2[50]=="n") # missing
  # now repeat with a gz file; with the same seed, output should be identical
  res <- system2("../consensify_c"," -c eg_missingness.counts.gz -p eg_missingness.pos.gz -s scaffold_lengths.txt -o test_gz.fasta -min 2 -max 99 -n_matches 2 -n_random_reads 3 -seed 123",
          stdout = TRUE)
  expect_true(unname(tools::md5sum("test.fasta")) == unname(tools::md5sum("test_gz.fasta")))
  file.remove("./test.fasta")
  file.remove("./test_gz.fasta")
})

# test for missing scaffolds at beginning middle and end, with filling (default behaviour)
test_that("consensify files with missing scaffolds",{
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta",
          stdout = TRUE)
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  # all 5 scaffolds in the scaffold file are output; the 3 without reads are filled with Ns
  expect_true(length(test)==5)
  expect_true(length(test$scaffold0.5)==30) # empty scaffold, with the length given in the scaffold file
  expect_true(length(test$scaffold1)==60)
  expect_true(length(test$scaffold2)==50)
  file.remove("./test.fasta")
})


# test for missing scaffolds at beginning middle and end, without filling
test_that("consensify files with missing scaffolds, leaving them empty",{
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta -no_empty_scaffold",
          stdout = TRUE)
test <- ape::read.FASTA("./test.fasta")
test <- as.character(test) ## cast it to character for easier testing
# with -no_empty_scaffold, only the 2 scaffolds with reads are output
expect_true(length(test)==2)
expect_true(length(test$scaffold1)==60)
expect_true(length(test$scaffold2)==50)
file.remove("./test.fasta")
})

# test for proportional reads: with -n_random_reads -1 all reads are used, and
# -n_matches <1 is the fraction of reads that must agree (strictly more than that fraction)
test_that("consensify files with proportional read calling (all reads sampled)",{
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta -n_random_reads -1 -n_matches 0.75",
                 stdout = TRUE)
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(all(test$scaffold1[2]=="n")) # has 2 G and 2 T so should be N
  expect_true(all(test$scaffold1[3]=="n")) # has 3 T and 1 A (75%, not >75%) so should be N
  expect_true(all(test$scaffold1[4]=="g")) # has 4 G so should be G
  # lower the threshold to 50%
  res <- system2("../consensify_c"," -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths_missing_scaffold.txt -o test.fasta -n_random_reads -1 -n_matches 0.5",
                 stdout = TRUE)
  test <- ape::read.FASTA("./test.fasta")
  test <- as.character(test) ## cast it to character for easier testing
  expect_true(all(test$scaffold1[3]=="t")) # has 3 T and 1 A (75% > 50%) so should now be T
  file.remove("./test.fasta")
})


#test we raise an error (exit code 1) if an option is not recognised
test_that("catch incorrect option",{
  err_code <- system2("../consensify_c",
                      " -c eg_missingness.counts.gz -p eg_missingness.pos.gz -s scaffold_lengths_missing_scaffold.txt -o test.fasta -wrong_option",
                      stderr = FALSE, stdout = FALSE)
  expect_true(err_code==1)
})

# test renaming of a single scaffold (e.g. a mitogenome, where we want the fasta
# header to be the sample name rather than the name of the reference sequence)
test_that("rename a single scaffold",{
  # we use all reads (-n_random_reads -1), so there is no random sampling and the
  # two runs below are deterministic and directly comparable
  # first run without renaming...
  res <- system2("../consensify_c"," -c eg_single_scaffold.counts -p eg_single_scaffold.pos -s scaffold_lengths_single_scaffold.txt -o test.fasta -n_random_reads -1 -n_matches 0.75",
                 stdout = TRUE)
  # ...then with the scaffold renamed to sample1
  res <- system2("../consensify_c"," -c eg_single_scaffold.counts -p eg_single_scaffold.pos -s scaffold_lengths_single_scaffold.txt -o test_renamed.fasta -n_random_reads -1 -n_matches 0.75 -rename_scaffold sample1",
                 stdout = TRUE)
  test <- as.character(ape::read.FASTA("./test.fasta"))
  test_renamed <- as.character(ape::read.FASTA("./test_renamed.fasta"))
  expect_true(names(test)=="scaffold1") # without renaming, we get the reference name
  expect_true(length(test_renamed)==1) # still a single sequence...
  expect_true(names(test_renamed)=="sample1") # ...but now named after the sample
  expect_true(length(test_renamed$sample1)==60) # length from the scaffold file is unchanged
  expect_true(all(test_renamed$sample1==test$scaffold1)) # renaming must not change the sequence itself
  file.remove("./test.fasta")
  file.remove("./test_renamed.fasta")
})

# test we raise an error if -rename_scaffold is used incorrectly
test_that("catch incorrect use of rename_scaffold",{
  # renaming only makes sense for a single scaffold; scaffold_lengths.txt has two,
  # so we expect exit code 1
  err_code <- system2("../consensify_c",
                      " -c eg_missingness.counts -p eg_missingness.pos -s scaffold_lengths.txt -o test.fasta -rename_scaffold sample1",
                      stderr = FALSE, stdout = FALSE)
  expect_true(err_code==1)
  # the check is done before the output file is opened, so no fasta should have been created
  expect_false(file.exists("./test.fasta"))
  # -rename_scaffold without a name should also give exit code 1
  err_code <- system2("../consensify_c",
                      " -c eg_single_scaffold.counts -p eg_single_scaffold.pos -s scaffold_lengths_single_scaffold.txt -o test.fasta -rename_scaffold",
                      stderr = FALSE, stdout = FALSE)
  expect_true(err_code==1)
})
