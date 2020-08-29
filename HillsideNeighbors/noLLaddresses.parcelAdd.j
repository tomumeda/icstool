#!/usr/bin/perl
use lib ("/Users/Tom/Sites/ICSTool/Lib", "/home/tom/Sites/ICSTool/Lib");

require "subCommon.pl";
&initialization;

###########################################################################
$DBrecAddress="DBrecAddress";
&TIE($DBrecAddress);
$DBparcelAddress="MapStreetAddressLL";
&TIE($DBparcelAddress);

$DBNoParcelAddressLL="NoParcelAddressLL";
unlink "./DB/$DBNoParcelAddressLL.db";
&TIE($DBNoParcelAddressLL);

open L,"<Maps/noLLaddresses.parcelAdd.txt";
while(<L>)
{ $add=$_;
  # print "$add\n";
  if($add =~ m/PARCEL\(([^\)]*)\)/ )
  { $key=$1;
    # GET offset in LATLON field
    print "\n\n$add key:$key \n";
    $add =~ m/LATLON\(([^\)]*)\)/ ;
    $offset=$1;
    @offset=split(/\s/,$offset);$#offset=1;
    print ">>offset @offset \n";

    @add=split(/=/,$add);$#add=1;
    $add=join("=",@add)."=";
    #print "$add  $key >> ";
    my @key=split(/=/,$key); $#key=1;
    $key=join("=",@key)."=";
    $newLL=${$DBparcelAddress}{$key};
    print "=> $newLL >> ";
    @newLL=split(/\t/,$newLL); $#newLL=1;
    # ADD LATLON offset
    $newLL[0]+=$offset[0]*.00003;
    $newLL[1]+=$offset[1]*.00003;
    $newLL=join("\t",@newLL);
    #print "$add\t$newLL\n";
    ${$DBNoParcelAddressLL}{$add}="$newLL[0]\t$newLL[1]\t$key\t$offset";
  }
}
