#!/usr/bin/perl
# makes different files from ParcelInfoByAddress.db and ParcelStreetAddresses.db
use lib ("/Users/Tom/Sites/ICSTool/Lib", "/home/tom/Sites/ICSTool/Lib");

use DB_File; 
require "subCommon.pl";
#do "vAddress.pl";
$HOME=$ENV{HOME};
$Lists="Lists";

tie(%parcelInfo,"DB_File","./DB/ParcelInfoByAddress.db",O_RDWR,0666,$DB_BTREE);
tie(%ParcelStreetAddresses,"DB_File","./DB/ParcelStreetAddresses.db",O_RDWR,0666,$DB_BTREE);
@s=keys %ParcelStreetAddresses;
##########################################################
#goto NEXT;
##########################################################
# select by ParcelMapInfo.txt LL boundaries
# produces ../$Lists/MapStreetAddressLL.txt  MapStreetAddresses.db MapStreetAddressLL.db
#NEXT:
$mapInfoFile="$Lists/ParcelMapInfo.txt";
&ParmValueArray( &arrayTXTfile($mapInfoFile) );
print "$MapLowerLeftCoordXRef $MapUpperRightCoordXRef $MapLowerLeftCoordYRef $MapUpperRightCoordYRef\n";

open L,">$Lists/MapStreetAddressLL.txt";
foreach $s (@s)
{ map 
  { $add=&vAddressFromArray($s,$_);
    @p=split("\t",$parcelInfo{$add});
    if( $MapLowerLeftCoordXRef<$p[6] and $p[6]<$MapUpperRightCoordXRef 
      and $MapLowerLeftCoordYRef<$p[7] and $p[7]<$MapUpperRightCoordYRef
  ) { print L "$add\t$p[6]\t$p[7]\n"; };
}
  split( "\t",$ParcelStreetAddresses{$s} ) ;
}
close L;

#######################################
# ADD extra non-parcel addresses
if( -e "noLLaddresses.parcelAdd.txt" )
{ system "noLLaddresses.parcelAdd.j >> $Lists/MapStreetAddressLL.txt";
}
#######################################

unlink("./DB/MapStreetAddresses.db");
unlink("./DB/MapStreetAddressLL.db");
tie(%StreetAddresses,"DB_File","./DB/MapStreetAddresses.db",O_RDWR|O_CREAT,0666,$DB_BTREE);
tie(%StreetAddressLL,"DB_File","./DB/MapStreetAddressLL.db",O_RDWR|O_CREAT,0666,$DB_BTREE);
open L,"$Lists/MapStreetAddressLL.txt";
while(<L>)
{ chop;
  ($StreetAddress,$lat,$long) = split(/\t/,$_);
  ($street,$address)=&vAddress2Array($StreetAddress);

##
  my $dxpix=
    int($MapLowerLeftPxXRef+
      ($MapUpperRightPxXRef-$MapLowerLeftPxXRef)*($lat-$MapLowerLeftCoordXRef) 
      / ( $MapUpperRightCoordXRef - $MapLowerLeftCoordXRef));
  my $dypix=
    int($MapLowerLeftPxYRef+
      ( $MapUpperRightPxYRef - $MapLowerLeftPxYRef)*($long-$MapLowerLeftCoordYRef) 
      / ( $MapUpperRightCoordYRef - $MapLowerLeftCoordYRef));
##

  $StreetAddresses{$street}.="$address\t";
  $StreetAddressLL{"$StreetAddress"}="$lat\t$long\t$dxpix\t$dypix";
}
foreach $s ( keys %StreetAddresses )
{ print "$s ", $StreetAddresses{$s},"\n";
}
exit;

##########################################################
# NEW prototype routines
NEXT:
sub MatchStreetNames
{ my $partialstreetname=@_[0];
  tie(%StreetAddresses,"DB_File","./DB/MapStreetAddresses.db",O_RDWR,0666,$DB_BTREE);
  my @names=keys %StreetAddresses;
  my @matches,$name;
  $partialstreetname=~s/\s+//g;
  foreach $name (@names)
  { my $test=$name;
    $test=~s/\s//g;
    if( $test =~ /$partialstreetname/i )
    { push @matches,$name;
    }
  }
  return sort @matches;
}
print join("\n",@s = &MatchStreetNames("euc"));
foreach $s  (@s)
{
  print "$s\n";
  print join(", ",$StreetAddresses{$s}),"\n";
}
exit;

##########################################################
sub testStreetAddresses
{ my $street=@_[0];
  return $ParcelStreetAddresses{$street};
}
$street="Ridge Rd";
print "\n$street addresses\n",join(", ",split(/\t/,&testStreetAddresses($street)));
exit;

##########################################################
# check if neighborhood address are parcel addresses
NEXT:
@street=map { $_=~ s/AddressesOn\///;$_;} <AddressesOn/*>;
foreach $street (@street)
{ open L,"AddressesOn/$street";
  while(<L>)
  { chop;
    $address=&vAddressString($street,$_);
    if( ! $parcelInfo{$address} )
    { print "$address\n";
    }
  }
}
##########################################################
NEXT:
