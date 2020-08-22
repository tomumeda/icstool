#!/usr/bin/perl
# makes list of member households:  sstreet addresses
require "subCommon.pl";
require "subMemberDB.pl";
require "subMaps.pl";
&initialization;
#############################
&TIE( @DBname );
$mapParmsfile="Lists/MapSpecialNeeds.Rooftop.txt";
&ParmValueArray( &arrayTXTfile($mapParmsfile) );

$address="Le Roy Ave=1643=";
$addressParcel=&ParcelvAddress($address);
($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)=&Address2Pixel($addressParcel,$MapParameters);

#die "XXXX $addressParcel ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)";

open L1,"|sort -u >memberStreetAddressList.txt";
open L2,"|sort -u >Lists/memberStreetAddressPIXlocation.txt";

@recn=sort {$a <=> $b} keys %DBmaster ;
for($i=0;$i<=$#recn;$i++)
{ $rec=$DBmaster{ $recn[$i] };
  @col=split(/\t/, $rec); 
  $StreetName=$col[$DBcol{"StreetName"}];
  $StreetAddress=$col[$DBcol{"StreetAddress"}];
  $subAddress=$col[$DBcol{"subAddress"}];
  $vAddress=join($vAddressDelim,($StreetName,$StreetAddress,$subAddress));
  $addressParcel=&ParcelvAddress($vAddress);

  @valp=($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)=&Address2Pixel($addressParcel,$MapParameters);

  ($xp,$yp,$d,$d)=@valp;
  next if($yp eq "");
  print L1 "$addressParcel\t$xp\t$yp\n";
  print L2 "<circle cx='$xp' cy='$yp' r='5' fill='yellow' stroke='black' id='$vAddress'/>\n";

}

#<circle cx="590" cy="20" r="10" fill="cyan" stroke="black" id="$vAddress"/>
