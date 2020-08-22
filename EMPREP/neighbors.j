#!/usr/bin/perl
require "subCommon.pl";

$DB="ParcelAddressByLonLat";
&TIE("$DB");
$DBaddress="MapStreetAddressLL";
&TIE("$DBaddress");
$DBneighbors="Neighbors";
&TIE("$DBneighbors");

@lonlat=sort keys %{"$DB"};
@addresses=sort keys %{"$DBaddress"};

for(my $iaddresses=0;$iaddresses<=$#addresses;$iaddresses++)
{ my $address=$addresses[$iaddresses]; 
  my ($lon,$lat,$other)=split(/\t/,${"$DBaddress"}{$address});
  my $lonlatref=join("\t",($lon,$lat));
  my $addressValue=join("\t",($address,$lonlatref));
  #print "\n>>$addressValue";

  my $value=$addressValue.";" ;
  for(my $i=0;$i<=$#lonlat;$i++)
  { $lonlat=$lonlat[$i];
    my $newvalue= join("\t",(${"$DB"}{$lonlat},$lonlat));
    if(&distll($lonlat,$lonlatref)<.0020
	and $newvalue ne $addressValue
    )
    { 
      $value.=$newvalue.";" ;
      #print "$lonlat,$lonlatref,",cos(37/180 *3.14159);
      #die;
    }
  }
  print "\n\n$address >> $value";
  ${"$DBneighbors"}{$address}=$value;
}

sub distll	#LATLON distance in degrees
{ my ($ll1,$ll2)=@_;
  my ($lon1,$lat1)=split(/\t/,$ll1);
  my ($lon2,$lat2)=split(/\t/,$ll2);
  my $dlon=($lon1-$lon2);
  my $dlat=($lat1-$lat2)/cos(37/180 *3.14159);
  my $dist=sqrt( $dlat*$dlat+$dlon*$dlon);
}
 
