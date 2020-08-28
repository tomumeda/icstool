#!/usr/bin/perl

$ref=<<___EOR;
Hilgard Ave=2777=	-122.25562807	37.87958284	1392	1140
Le Conte Ave=2634=	-122.25797414	37.87699862	176	2286
Buena Vista Way=2750=	-122.25727989	37.88117325	814	206
Le Roy Ave=1597=	-122.25858214	37.87994496	202	722
Hilgard Ave=2805=	-122.25518845	37.8787627	1486	1576
Virginia St=2701=	-122.25684764	37.8784446	768	1626
La Vereda Rd=1591=	-122.25668856	37.8802276	1018	724
___EOR
print $ref,"\n";
@ref=split(/\n/,$ref);
foreach $r (@ref)
{ ($address,$lon,$lat,$px,$py)=split(/\t+/,$r);
  print "{\"$address\",$lon,$lat,$px,$py},\n";
  $ref{$address}="$lon\t$lat\t$px\t$py";
  push(@refLLPP,"$lon\t$lat\t$px\t$py");
}
die;
for( $i=0;$i<2;$i++)
{ ($lonR[$i],$latR[$i],$pxR[$i],$pyR[$i])=split(/\t/,$refLLPP[$i]);
}
$dlonR=$lonR[1]-$lonR[0];
$dlatR=$latR[1]-$latR[0];
$dpxR=$pxR[1]-$pxR[0];
$dpyR=$pyR[1]-$pyR[0];

open L,"MapStreetAddressLL.txt";
while(<L>)
{ next if($_ !~ /Le Roy Ave=1643=/);
  chop;
  ($address,$lon,$lat)=split(/\t/,$_);
  #print "\ndlong: ",$lon-$lonR[0];
  #print "\ndlat: ",$lat-$latR[0];
  $px=$dpxR*($lon-$lonR[0])/($lonR[1]-$lonR[0])+$pxR[0];
  $py=$dpyR*($lat-$latR[0])/($latR[1]-$latR[0])+$pyR[0];
  print "\n($address	$lon	$lat	>>$px	>>$py)\n";
  print "$dlonR $dlatR $pxR[0] $pyR[0] ::(",
  $dpxR*($lon-$lonR[0])/($lonR[1]-$lonR[0])+$pxR[0]," == ",
  $dpyR*($lat-$latR[0])/($latR[1]-$latR[0])+$pyR[0],")\n";

}

