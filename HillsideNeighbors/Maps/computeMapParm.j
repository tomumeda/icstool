#!/usr/bin/perl
#
# creates hillside.neighborhood.txt
$file="hillside.neighborhood";
$fileJPG="$file.jpg";
$fileJGW="$file.jgw";

$head=`file $fileJPG`;
@head= split(/,/,$head);
@nxy=split(/x/,$head[-2]);
#print "@nxy\n";

open L,$fileJGW;
@var=split(/,/,"dx,rx,ry,dy,x0,y0");
$i=0;
while(<L>)
{ $_=~ s/\r//; chop;
  #print;
  ${ $var[$i++] }=$_;
}
$Lx=$x0;
$Rx=$x0 + $nxy[0]*$dx;
$Uy=$y0;
$Ly=$y0 + $nxy[1]*$dy;
open L,">$file.txt";
print L
"
MapFile=Maps/$fileJPG
MapLowerLeftCoordXRef=$Lx
MapLowerLeftCoordYRef=$Ly
MapUpperRightCoordXRef=$Rx
MapUpperRightCoordYRef=$Uy

MapLowerLeftPxXRef=1
MapLowerLeftPxYRef=$nxy[1]
MapUpperRightPxYRef=1
MapUpperRightPxXRef=$nxy[0]
MapXdim=$nxy[0]px
MapYdim=$nxy[1]px
MapDimX=$nxy[0]
MapDimY=$nxy[1]
";


