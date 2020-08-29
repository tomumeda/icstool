#!/usr/bin/perl
# makes DB/MapStreetAddressesEmPrep.db and DB/MapStreetAddressLLEmPrep.db
# DB/MapStreetAddressPIXEmPrep.db
use lib ("/Users/Tom/Sites/ICSTool/Lib", "/home/tom/Sites/ICSTool/Lib");

use DB_File;
require "subCommon.pl";
# require "vAddress.pl";
$HOME=$ENV{HOME};
$Lists="Lists";
#
unlink("./DB/MapStreetAddressesEmPrep.db");
unlink("./DB/MapStreetAddressLLEmPrep.db");
unlink("./DB/MapStreetAddressPIXEmPrep.db");
tie(%StreetAddresses,"DB_File","./DB/MapStreetAddressesEmPrep.db",O_RDWR|O_CREAT,0666,$DB_BTREE);
tie(%StreetAddressLL,"DB_File","./DB/MapStreetAddressLLEmPrep.db",O_RDWR|O_CREAT,0666,$DB_BTREE);
tie(%StreetAddressPIX,"DB_File","./DB/MapStreetAddressPIXEmPrep.db",O_RDWR|O_CREAT,0666,$DB_BTREE);


open L,"$Lists/MapStreetAddressLLEmPrep.txt";
while(<L>)
{ chop;
  ($StreetAddress,$lat,$long,$px,$py) = split(/\t/,$_);
  ($street,$address)=&vAddress2Array($StreetAddress);
  $StreetAddresses{$street}.="$address\t";
  $StreetAddressLL{"$StreetAddress"}="$lat\t$long\t$px\t$py";
  $StreetAddressPIX{"$StreetAddress"}="$px\t$py";
}

# ADD noParcelAddress data for pixel 
$NoParcelAddressLL="NoParcelAddressLL";
&TIE($NoParcelAddressLL);
foreach $s ( keys %NoParcelAddressLL )
{ ($lon,$lat,$parceladdress,$offset)=split(/\t/,$NoParcelAddressLL{$s});
  @offset=split(/\s/,$offset);
  @pixXY=split(/\t/,$StreetAddressPIX{$parceladdress});
  $pixXY[0]+=$offset[0]*6;
  $pixXY[1]+=$offset[1]*6;
  $StreetAddressPIX{$s}="$pixXY[0]\t$pixXY[1]";

  print "Adding $s (@pixXY,$parceladdress)\n";
}
foreach $s ( sort keys %StreetAddressPIX )
{ print "$s ", $StreetAddressPIX{$s},"\n";
}

exit;

