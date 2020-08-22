#!/usr/bin/perl
require "subCommon.pl";
&initialization;

###########################################################################
# lists addresses with no parcel address
# Prints out PARCEL() LATLON() to be filled in later
# run ?.j to make corrected LATLON file
# Produces noLLaddresses.txt to be editted and moved to Maps/ for processing.
###########################################################################
$DBrecAddress="DBrecAddress";
&TIE($DBrecAddress);
$DBparcelAddress="MapStreetAddressLLEmPrep";
&TIE($DBparcelAddress);
open L,"|sort>noLLaddresses.txt";

while (my ($key,$val) = each %{$DBrecAddress}) 
{ my @key=split(/=/,$key); $#key=1;
  $key=join("=",@key)."=";
  my $valp=${$DBparcelAddress}{$key};
  if(!$valp)
  { $valp="PARCEL() LATLON()"
  }

  print L "$key :: $valp \n";
}
while (my ($key,$val) = each %{$DBparcelAddress}) 
{ #print "$key :: $val \n";
}

