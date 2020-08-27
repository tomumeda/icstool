#!/usr/bin/perl
# .CSV can have elements of the form "xxxxx \n yyyy"
# which cause problems reading with perl because the read stops at \n. 
# This routine for this situation 
# and appends the next line until an even number of "s are found.
# There double quotes "" are interpreted as single ".
use strict;
require "subUtility.pl";
use FileHandle;
my $csv="contacts";
#############################################3
my $file_csv="data/$csv.csv";
my $file_csv_new="data/$csv.new.csv";
my ($line,$n,@c, $cnt);
$cnt=0;

my $L=FileHandle->new;
my $Lout=FileHandle->new;
open $Lout,">$file_csv_new" ;
open $L,"$file_csv" || die "Can't open $file_csv";
while($line=&readCSVline($L))
{ 
  #	$n=@c=$line=~/\"/g;
  #	print ">>$n: $line\n";
  my @rec=&STRG4String($line);
  #	print "\n\nXXX >>>",join(":",@rec);
  &printCSV($Lout,@rec);
}
