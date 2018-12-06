#!/usr/bin/perl -w

use strict;
use List::Util 'shuffle';

my $depthsFile = $ARGV[0];
my $countsFile = $ARGV[1];
my $seqLenFile = $ARGV[2];
my $outputFile = $ARGV[3];
my $k          = $ARGV[4];


# arguments ok?
my $arrSize = @ARGV; 
unless ($arrSize ==5) {
    print "\nERROR: script needs five arguments, in this order: 
    name (and location) of .pos file
    name (and location) of .counts file
    name (and location) of sequence IDs and lengths
    name of output file
    depth threshold for exclusion \n\n";
    exit;
}

print "running script  
      depthsFile: $depthsFile
      countsFile: $countsFile
      seqLenFile: $seqLenFile
      outputFile: $outputFile
      k         : $k         \n\n"; 


my @chars = ('0'..'9', 'A'..'F');
my $len = 8;
my $merged;
while($len--){ 
    $merged .= $chars[rand @chars];
}
$merged .= ".txt";


system "paste $depthsFile $countsFile  > $merged"; 
my %data; 
open  (INFILE, $merged) or die $!;   
while (my $line = <INFILE>) {
    next if $line =~ /^chr\t/;
    chomp($line);
    $line =~ s/ //g;
    my @lineArr = split("\t", $line); 
    if ($lineArr[2] >= 2 &&  $lineArr[2] <= $k ) {
        my $key = $lineArr[0] . "_" . $lineArr[1]; 
        my $val = $lineArr[2] . "_" . $lineArr[3] . "_" . $lineArr[4] . "_" . $lineArr[5] . "_" . $lineArr[6] ;
        $data{$key} = $val; 
    }
    
}
print "hash is done! \n"; 

my $total = 0;
open  (OUT, ">$outputFile") or die $!;   
open  (IN, "$seqLenFile") or die $!;   
print "processing \n"; 
while (my $line = <IN>) {
    chomp($line); 
    $line =~ s/ //g;
    my ($seqID, $seqLen) = split /\t/, $line;   
    print "   ...$seqID\n"; 
    print OUT ">$seqID\n"; 
    for (my $i = 1; $i < $seqLen+1; $i++) {
        
        my $id = $seqID . "_" . $i;
        if (exists $data{$id}) {
            $total++; 
            my ($depth, $a, $c, $g, $t) = split /_/, $data{$id}; 
            my @as = ("A") x $a; 
            my @cs = ("C") x $c; 
            my @gs = ("G") x $g; 
            my @ts = ("T") x $t; 
            my @bases = (@as, @cs, @gs, @ts); 
            
            if ($depth == 2) {
                undef my %saw;
                my @uniq = grep(!$saw{$_}++, @bases);   
                my $hwMny = @uniq; 
                if ($hwMny == 1) {
                    print OUT "$uniq[0]"; 
                } else {
                    print OUT "N"; 
                }               
            } else {
                # select 3 random
                my $range = @bases;
                my @shuff_indx = shuffle(0..$range-1);          
                my @pick_indx = @shuff_indx[ 0 .. 2 ];   
                my @random3; 
                foreach my $r (@pick_indx) {
                    push @random3, $bases[$r]; 
                }
                
                # make consensus
                my $cons = "N"; 
                my %count;
                $count{$_}++ foreach @random3;
                while (my ($key, $value) = each(%count)) {
                    if ($value >= 2) {
                        $cons = $key;
                    }
                }
                print OUT "$cons"; 
            }
        } else { 
            print OUT "N"; 
        }
    }
    print OUT "\n"; 
}
print "\n all done! output is in file $outputFile\n"; 
print "positions processed: $total\n"; 
system "rm $merged"; 

