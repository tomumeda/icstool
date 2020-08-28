#!/usr/bin/perl
# make xRoles.d
# from OrganizationChart.txt
$file="OrganizationChart.txt";
open(L,"$file");
while(<L>)
{ #chop;
  next if(/^#/);     # comment
  $_=~s/#.*$//;       #trailing comment
  $_=~s/[\s]*$//;     #trailing space including \n
  #$_=~s/^[\s]*//;   	#leading space 
  next if(/^$/);     #null line
  push @line,$_; 
}
#default output 
print "Unassigned\tLEVEL.X\tMultiPerson\t-\n";
for(my $i=0; $i<=$#line; $i++)
{ $line[$i]=~/^(\t*)(.*) <(.*)>/;
  $level[$i]=length($1);
  next if($level[$i] eq 0);
  $name=$2;
  $others=$3;
  $others=~/OrgTable\[(.*)\]/;
  $orgtable=$1;
  $others=~/Attributes\[(.*)\]/;
  $attributes=$1;
  #if($level[$i]-$higherlevel eq 1){ $sup=
  print "$name\tLEVEL.$level[$i]\t$attributes\n";
}
print "Unavailable\tLEVEL.X\tMultiPerson,SelfAssign\t-\n";
