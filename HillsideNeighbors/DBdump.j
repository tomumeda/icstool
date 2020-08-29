#!/usr/bin/perl
require "subCommon.pl";
require "subDamageReport.pl";

#&TIE(DBrecSpecialNeeds);
$DB="DBrecPets";
$DB="DBrecVisitors";
$DB="DBrecEmergencyEquipment";
$DB="DBrecSpecialNeeds";
$DB="DBSpecialNeeds";
$DB="AddParcelAddress";
$DB="ParcelLonLatByAddress";

$DB="DBAddressOnStreet";

$DB="DBrecAddress";
$DB="MapStreetAddressPIXEmPrep";
$DB="MapStreetAddress";
$DB="MapStreetAddressesEmPrep";
$DB="Images/Selfie";
$DB="ParcelStreetAddresses";
$DB="ParcelLonLatByAddress";
$DB="ParcelAddressByLonLat";
$DB="MapStreetAddressLL";
$DB="Images/Housemates";
$DB="Images/Index";
$DB="Images/Selfie";
$DB="NoParcelAddressLL";
$DB="DBSpecialNeeds";
$DB="ParcelInfoByAddress";
$DB="CedarHillsideUUD";
$DB="Neighbors";
$DB="DBmaster";

&TIE("$DB");
@key=sort keys %{"$DB"};
for(my $i=0;$i<=$#key;$i++)
{ print "========\n";
  #print ">>$key[$i]:\n",${$DB}{$key[$i]},"\n";
  print ">>$key[$i]:\n>",join("\n>",split(/[\t;]/,${$DB}{$key[$i]})),"\n";
}
 






