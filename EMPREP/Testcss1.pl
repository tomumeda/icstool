#!/usr/bin/perl
use CGI qw/:standard :html3/;
use URI::Escape;
use Fcntl;
use DB_File;
use POSIX qw(strftime);
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;

use lib "/Users/Tom/Sites/EMPREP/ICSTool/PL";

do "subCommon.pl";
do "subICSWEBTool.pl";
do "subDamageReport.pl";

&initialization;

#here's a stylesheet incorporated directly into the page
my @addresses=&DamageReportAddresses();
print header();
print start_html(-title=>'SVG test', -style=>{ -src=>'ICSTool.css' ,-code=>$newStyle });
{ my ($dum,$dum1,$address)=split(/:/,$UserAction,3);
  if(!$address){ $address="Le Roy AveXX=1643" } #DUMMY to make code work
  my ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)
    = &MapAddressPxLocation($address,"Lists/ParcelMapInfo.txt","MapStreetAddressLL");
  { print $q->h3("Map of Reported Locations @addresses"),hr;
  }
}
my $Yoffset=60;
my $svgYSize=$MapDimY+$Yoffset;
my $imageYRef=$Yoffset;
print <<___EOR;
<html xmlns="http://www.w3.org/1999/xhtml">
<body>
<form>
<input hidden id="myLongitude" type="text" name="myLongitude">
<input hidden id="myLatitude" type="text" name="myLatitude">
<input type="submit" name="action" value="Home">
</form>

<script> 
function geoFindMe() {
 var output = document.getElementById("out");
 if (!navigator.geolocation){
output.innerHTML = "<p>Geolocation is not supported by your browser</p>";
return;
}
function success(position) { 
  var latitude  = position.coords.latitude;
  var longitude = position.coords.longitude;
  output.innerHTML = '<p>Latitude is ' + latitude + '° <br>Longitude is ' + longitude + '°</p>';
  var img = new Image();
  img.src = "http://maps.googleapis.com/maps/api/staticmap?center=" + latitude + "," + longitude + "&zoom=13&size=300x300&sensor=false";
  output.appendChild(img);
};
function error() {
  output.innerHTML = "Unable to retrieve your location";
};

output.innerHTML = "<p>Locating…</p>";
navigator.geolocation.getCurrentPosition(success, error);
}
</script> 

<p><button onclick="geoFindMe()">Show my location</button></p>
<div id="out"></div>
___EOR

print $q->h4("myLatitude"),hr;
print <<___EOR;
<input type="button" value="Click Me!" onClick="alert('This is an alert!')">
___EOR

print end_html;
