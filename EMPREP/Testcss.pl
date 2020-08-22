#!/usr/bin/perl
use CGI qw/:standard :html3/;
use URI::Escape;
use Fcntl;
use DB_File;
use POSIX qw(strftime);
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;

no lib "$ICSdir"; # needs to be preset
#use lib "$ICSdir"; # does not work in OSX
use lib "/Users/Tom/Sites/EMPREP/ICSTool/PL"; # this seems to be needed explicitly on OSX
## require => cached routines unchanged until apache restart

do "subCommon.pl";
do "subICSWEBTool.pl";
do "subDamageReport.pl";

&initialization;

#here's a stylesheet incorporated directly into the page

#my @addresses=&DamageReportAddresses();
print header();
print start_html(-title=>'SVG test', -style=>{ -src=>'ICSTool.css' ,-code=>$newStyle });

{ my ($dum,$dum1,$address)=split(/:/,$UserAction,3);
  if(!$address)
  { $address="Le Roy Ave=1643" } #DUMMY to make code work
  my ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)
    = &MapAddressPxLocation($address,"Lists/ParcelMapInfo.txt","MapStreetAddressLL");
  { print $q->h3("Map of Reported Locations@addresses"),hr;
  }
}
my $Yoffset=60;
my $svgYSize=$MapDimY+$Yoffset;
my $imageYRef=$Yoffset;

###SVG
print <<___EOR;
<form>
<input hidden id="myLongitude" type="text" name="myLongitude">
<input hidden id="myLatitude" type="text" name="myLatitude">
<input type="submit" name="action" value="Home">
</form>

<script>
function buttonClick(evt) { alert(evt.target.id); }
</script>

<script>
function getLocation()
{ var output = document.getElementById("out");
  if ( ! navigator.geolocation )
  { output.innerHTML = "<p>Geolocation is not supported by your browser</p>";
   return;
  }
  navigator.geolocation.getCurrentPosition(showPosition); 
function showPosition(position) 
{ var myLongitude = position.coords.longtitude ;
  var myLatitude = position.coords.lattitude ;
  var x = document.getElementById("myLongitude");
  x.value = myLongitude ;
  var x = document.getElementById("myLatitude");
  x.value = myLatitude ;
  var pxY  = $Yoffset + $MapLowerLeftPxYRef + ( $MapUpperRightPxYRef - $MapLowerLeftPxYRef) * ( position.coords.latitude - $MapLowerLeftCoordYRef )/( $MapUpperRightCoordYRef - $MapLowerLeftCoordYRef); 
  var pxX  = $MapLowerLeftPxXRef + ( $MapUpperRightPxXRef - $MapLowerLeftPxXRef) * (position.coords.longitude - $MapLowerLeftCoordXRef) / ( $MapUpperRightCoordXRef - $MapLowerLeftCoordXRef); 
  var yourLocation = document.getElementById("YourLocation");
  yourLocation.setAttribute("cx",pxX);
  yourLocation.setAttribute("cy",pxY);
}
}
</script>

<style>
g.button:hover {opacity:0.5;}
#b1.button:hover {opacity:0.1;}
</style>

<svg height="$svgYSize" width="$MapDimX">
<rect x="0" y="0" height="$MapDimY" width="$MapDimX" style="fill: #999999"/>
<image id="mapimage" x="0" y="$imageYRef" height="$MapDimY" width="$MapDimX" xlink:href="$MapFile" />
<g class="legend" />
<circle cx="20" cy="010" r="5" stroke="black" stroke-width="1" fill="red" />
<text x="30" y="15" font-size="20"> TEXT1 </text>
<circle cx="20" cy="30" r="5" stroke="black" stroke-width="1" fill="orange" />
<text x="30" y="35" font-size="20"> TEXT2 </text>
<circle cx="220" cy="010" r="5" stroke="black" stroke-width="1" fill="red" />
<text x="230" y="15" font-size="20"> TEXT1 </text>
<circle cx="220" cy="30" r="5" stroke="black" stroke-width="1" fill="orange" />
<text x="230" y="35" font-size="20"> TEXT2 </text>
</g>

___EOR
# Your position
 my ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY) =
  &MapLatLongPxLocation(
    $q->param("myLatitude"),$q->param("myLongitude"),"Lists/ParcelMapInfo.txt");
  if($markerOffsetX =~ /\d/)
  {
  my $markerY=$markerOffsetY+$Yoffset;
print <<___EOR; 
var  pxY  = $Yoffset + $MapLowerLeftPxYRef + ( $MapUpperRightPxYRef - $MapLowerLeftPxYRef) * ( position.coords.latitude - $MapLowerLeftCoordYRef )/( $MapUpperRightCoordYRef - $MapLowerLeftCoordYRef); 
var  pxX  = $MapLowerLeftPxXRef + ( $MapUpperRightPxXRef - $MapLowerLeftPxXRef) * (position.coords.longitude - $MapLowerLeftCoordXRef) / ( $MapUpperRightCoordXRef - $MapLowerLeftCoordXRef); 

<g class="button" cursor="pointer" onmouseup="buttonClick(evt)" >
<circle id="YourLocation" cx=pxX cy=pxY
r="10" stroke="black" stroke-width="1" fill="orange" opacity=".5" />
___EOR
  }
my @addresses=&DamageReportAddresses();
for(my $i=0; $i<=$#addresses; $i++) 
{ my ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY) =
  &MapAddressPxLocation($addresses[$i],"Lists/ParcelMapInfo.txt","MapStreetAddressLL");
  next if($markerOffsetX !~ /\d/);
  my $markerY=$markerOffsetY+$Yoffset;
   print <<___EOR;
<g class="button" cursor="pointer" onmouseup="buttonClick(evt)" >
<circle id="$addresses[$i]" cx="$markerOffsetX" cy="$markerY" 
r="5" stroke="black" stroke-width="1" fill="red" />
</g>
___EOR
}
print <<___EOR;
</svg>

<script>
getLocation();
</script>
<div id="out"></div>
___EOR

print $q->h4($q->param("myLatitude")),hr;

print end_html;
