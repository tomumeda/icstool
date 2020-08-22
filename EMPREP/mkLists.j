#!/usr/bin/perl
do "subCommon.pl";
# creates data files from
# >>MessageRecipients.d
# >>PersonnelRoles.txt
open L,"Lists/Organization.txt";
while(<L>)
{ next if(/^#/); 
  chop;
  s/(\<.*\>)//; #remove attribute field
  $attributes=$1;
  $key=&clean_name($_);
  push(@line,$key);
  push(@attributes,($key,$attributes));
}
open L,">MessageRecipients.d";
print L join("\n",("All",@line,"Unassigned\n"));
open L,">PersonnelRoles.txt";
print L join("\n",(@line,"Unassigned","Unavailable\n"));
