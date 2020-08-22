#!/usr/bin/perl
require "subUtility.pl";
require "subCommon.pl";
require "subMaps.pl";
no lib "$ICSdir"; # needs to be preset
use lib "/Users/Tom/Sites/EMPREP/ICSTool/PL"; # this seems to be needed explicitly on OSX

undef @mapParmList;
undef %MapTitle;

$DB= "CedarHillsideUUD";
$DBlatName="latitude,N,19,8";
$DBlonName="longitude,N,19,8";
&TIE($DB);
%DBcol=&DBHeaderCol( $DB );

#########
&MapParmList("MapCedarHillsideUUD.available");
$xShowMap="Lists/MapCedarHillsideUUD.txt";
#########
## require => cached routines unchanged until apache restart
&initialization;
print $q->header();
# here's a stylesheet incorporated directly into the page
print $q->start_html(-title=>'UUD Map', -style=>{ -src=>'MemberInformation.css' ,-code=>$newStyle });
###########################################################################
&xShowMap($xShowMap);
###########################################################################
print $q->end_html;
exit(1);
#############

sub xShowMap
{ my($mapParmsfile)=@_;
  undef $MapFile;
  undef $MapParameters;
  #print "<br>:DB--->>mapParmsfile $mapParmsfile>>\n";
  #print "<br>:DB--->>MapFixedSymbols ",join(" ",keys %MapFixedSymbols),">>\n";
  &ParmValueArray( &arrayTXTfile($mapParmsfile) );
  #
  # initial call to set MapDimX MapDimY
  ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)=&xAddress2Pixel($address,$MapParameters);
  #################################
  undef $svgOut;
  my $svgOut="";
  #################################
  undef @addresses; my @addresses;
  undef %display; my %display;

  # #########################
  my @colors=();
  my @categories=();
  if($SymbolType eq "BoxSymbol")
  { @colors=@BoxColor;
    @categories=@BoxName;
  }
  elsif($SymbolType eq "CircleSymbol")
  { @colors=@BoxColor;
    @categories=@BoxName;
  }
  #########################
  { 
    %display=%{$DB};
    @addresses=keys %display;
    for(my $i=0; $i <= $#addresses; $i++)
    { # print "\n---$#addresses: $i >> $addresses[$i]";
      $display{ $addresses[$i] }=~s/\t/\n/g;
    }
  }

  #################################
  print $q->h3($MapTitle),hr();
  $svgOut.=&MapInitSVG;
  $svgOut.=$MapFixedSymbols{$mapParmsfile};

  #################################
  my @notOnMap=();
  my @maplocations; $#maplocations=-1;
  $svgOut.=&showTargetAddress;
  foreach my $address (sort @addresses)
  { next if(&vAddressQ($address) ne 1);
    
    my $addressParcel=&ParcelvAddress($address);
    my ($markerX,$markerY,$MapDimX,$MapDimY) 
        =&xAddress2Pixel($addressParcel,$MapParameters);
	#
	# print "\n<br>DB:--->> MapParameters $MapParameters  " ; 
    next if($markerX !~ /\d/); # NO pix data
    if( $markerX<0 or $markerY<0 or $markerX>$MapDimX or $markerY>$MapDimY) 
    { # print "\n<br>DB:--->> addressParcel $addressParcel : $markerX, $markerY, $MapDimX, $MapDimY" ; 
      push @notOnMap,$address;
      next;
    }
    ######################################
    # get report at address
    my @report=split(/\n/,$display{$address});
    @report=&deleteNullItems(@report);
    # print "<br> >>report @report";
    ######################################
    my $listrec=&FindMatchQ("VOTE",@report) ;
    my $list=$report[$listrec];
    # print "<br>>>>VOTE $listrec: $list";
    @report=join("\n",&deleteArrayIndex($listrec,@report));
    # print "\n<br>>report>> @report";

     #my $class="class=\"svg-blink\"";
    my $class=$SVGClass;
    my $output="no";
    ##################################################
    # 00 01 marker position label 
    # 10 11
    my @markerBd=($markerX-$subMarkerSize-2,$markerY-$subMarkerSize-2);
    my @markerXs=(
      $markerX-$subMarkerSize,
      $markerX-$subMarkerSize,
      $markerX,
      $markerX);
    my @markerYs=(
      $markerY-$subMarkerSize,
      $markerY,
      $markerY-$subMarkerSize,
      $markerY);
    ##################################################
    # ALL CLEAR
    if($list=~m/allclear/) 
    { $svgOut.=<<___EOR;
      <circle id="$address" cx="$markerX" cy="$markerY" 
    r="10" stroke="black" stroke-width="1" fill="cyan" opacity="1."/>
___EOR
    }
    ###################################################
    #print "<br>--categories-->@categories";
    #print "<br>--list-->$list";
    #print "<br>-----SymbolType:$SymbolType";
    ###################################################
    for(my $i=0;$i<=$#categories;$i++)
    { if($list=~m/$categories[$i]/)
      { push(@maplocations,$address);

	if($SymbolType =~ m/BoxSymbol/ )
	{ $svgOut.=<<___EOR;
<rect $class x="$markerXs[$i]" y="$markerYs[$i]" 
width="$subMarkerSize" height="$subMarkerSize" stroke="black" stroke-width="1" fill="$colors[$i]" />
<rect $class id="$address\n@report" x="$markerBd[0]" y="$markerBd[1]" 
width="$MarkerBoarderSize" height="$MarkerBoarderSize" stroke="red" stroke-width="2" fill-opacity="0.0" />
___EOR
	} 
	elsif($SymbolType =~ m/CircleSymbol/ )
	{ $svgOut.=<<___EOR;
<circle $class cx="$markerXs[$i]" cy="$markerYs[$i]" 
r="$subMarkerSize" stroke="black" stroke-width="1" fill="$colors[$i]" id="$address\n@report"/>
___EOR
	}
      }
    }
  }

  print <<___EOR;
$svgOut
<\g>
<\svg>
___EOR

#############
  if($#maplocations>-1)
  { # print "<br>",&COLOR("Red","Locations ON map:");
    foreach my $address ( sort @maplocations )
    { #print "\n<br>",$q->submit("ShowReportFor",$address); 
      # print "\n<br>",$q->submit("action","MapShowReportFor=$address"); 
    }
    #print hr();
  }
  if($#notOnMap>-1)
  { print "<br>",&COLOR("Red","Locations OFF map with reports:");
    foreach my $address ( sort @notOnMap )
    { #print $q->submit("ShowReportFor",$address); 
      my @list=split(/\n/, $display{$address}); 
      @list=&deleteNullItems(@list);
      print "<br>\n",join("<br>\n",@list);
      print hr();
    }
  }
}

############################################
sub xAddress2Pixel
{ my ($address,$LLpixelInfoFile)=@_;
  if( ! $MapFile )
  { &ParmValueArray( &arrayTXTfile($LLpixelInfoFile) );
  }
  if( ! %{$MapAddressLonLat})
  { &TIE("$MapAddressLonLat");
  }
  if( $MapExtraAddressLonLat and ! %{$MapExtraAddressLonLat} )
  { &TIE("$MapExtraAddressLonLat");
  }
  $address=&ParcelvAddress($address); # CHK address format
  # print "<br>DB:: MapAddressLonLat $MapAddressLonLat";
  # print "<br>DB:: MapExtraAddressLonLat $MapExtraAddressLonLat";
  my $data;

  ###################################
  # ADD DB ADDRESS
  my $DBrec=${$DB}{ $address };
  my @DBrec= split(/\t/,$DBrec);

  #print "XXXX DBrec @DBrec  <<$DBlatName:  $DBcol{ $DBlatName } \n";
  #print ">>",keys %DBcol;
  my $lat = $DBrec[ $DBcol{ $DBlatName } ];
  my $lon = $DBrec[ $DBcol{ $DBlonName } ];
  if( 30 < $lat and $lat < 40 and  -123 < $lon and $lon < -121)
  { 
    # print "\n==DBlatlon $address  $lat $lon ";
    my ($dxpix,$dypix,$MapXdim,$MapYdim)=&MapLatLongPxLocation($lat,$lon,$LLpixelInfoFile);
    # print "\n==DBdxpix $lat $lon: $dxpix,$dypix ,$MapXdim,$MapYdim ";
    return ($dxpix,$dypix,$MapXdim,$MapYdim);
  }

###################################
  elsif( $data=${$MapAddressLonLat}{   $address  } )
  { my ($lon,$lat) =split(/\t/,$data);
    #print "==MapAddressLonLat: $address $data ==";
    my ($dxpix,$dypix,$MapXdim,$MapYdim)=&MapLatLongPxLocation($lat,$lon,$LLpixelInfoFile);
    return ($dxpix,$dypix,$MapXdim,$MapYdim);
  }
###################################
  elsif( $data=${$MapExtraAddressLonLat}{   $address  } )
  { my ($lon,$lat) =split(/\t/,$data);
    #print "==MapExtraAddressLonLat: $address $data ==";
    my ($dxpix,$dypix,$MapXdim,$MapYdim)=&MapLatLongPxLocation($lat,$lon,$LLpixelInfoFile);
    return ($dxpix,$dypix,$MapXdim,$MapYdim);
  }
  else
  { return (-1,-1,$MapXdim,$MapYdim); # address not found return
  }
}

#############################MAP
sub MapParmList
{ #undef @mapParmList; #uncomment reload TEST
  my ($mapsAvailable)=@_;
  ## print ">>$mapsAvailable";
  if($#mapParmList<0)
  { undef %MapFixedSymbols;
    @mapParmList=&arrayTXTfile("Lists/$mapsAvailable.txt");
    foreach my $parmfile (@mapParmList)
    { 
      # print "<br>:DB parmfile---> $parmfile";
      my @mapParm=&arrayTXTfile($parmfile);
      my $title=&FindFirstElement("MapTitle=",@mapParm);
      if( $title eq "" ) { print "\nMAP MapTitle NOT FOUND in >>$parmfile>>";}
      $title=~s/^MapTitle=//;
      $title=~s/<br>/ /g;
      $MapTitle{$parmfile}=$title;
      $MapTitle2ParmFile{$title}=$parmfile;
      my $fixedsymbols=&FindFirstElement("MapFixedSymbols=",@mapParm);
      if( $fixedsymbols ne "" ) 
      { $fixedsymbols=~s/^MapFixedSymbols=//;
	######### ? ADD variable replacement code
	$MapFixedSymbols{$parmfile}=join("\n",&arrayTXTfile($fixedsymbols));
      }
    }
  }
}

sub MapLatLongPxLocation
{ my ($lat,$long,$LLpixelInfoFile)=@_;
  if( ! $MapFile ) { &ParmValueArray( &arrayTXTfile($LLpixelInfoFile) ); }
  { my $LLx=$long;
    my $LLy=$lat; #longitude,latitude data
    my $dxpix=
      int($MapLowerLeftPxXRef+
	($MapUpperRightPxXRef-$MapLowerLeftPxXRef)
	*($LLx-$MapLowerLeftCoordXRef) 
	/ ( $MapUpperRightCoordXRef - $MapLowerLeftCoordXRef));
    my $dypix=
      int($MapLowerLeftPxYRef+
	( $MapUpperRightPxYRef-$MapLowerLeftPxYRef)
	*($LLy-$MapLowerLeftCoordYRef) 
	/ ( $MapUpperRightCoordYRef - $MapLowerLeftCoordYRef));
    return ($dxpix,$dypix,$MapXdim,$MapYdim);
  }
}

sub MapSymbol
{ my ($markerOffsetX,$markerOffsetY,$type)=@_;
  my $color,$width,$diameter;
  if($type =~ /^focus/ )
  { $color="red"; $width=3; $diameter=7;
  }
  elsif($type =~ /^general(.*)/ )
  { $color="blue"; $width=3; $diameter=4;
    my @parms=split(/:/,$1); shift @parms;
    my $icolor=&FindPattern(@parms,"color=");
    if($icolor>=0)
    { my ($dum,$newcolor)=split(/=/,$parms[$icolor]);
      $color=$newcolor;
    }
  }
  elsif($type =~ /^mylocation/ )
  { $color="orange"; $width=4; $diameter=5;
  }
    print <<___EOR;
var ctx = c.getContext("2d");
ctx.strokeStyle = '$color';  
ctx.lineWidth = $width;  
ctx.beginPath();
ctx.arc( $markerOffsetX, $markerOffsetY, $diameter, 0, 2*Math.PI );
ctx.stroke();
___EOR
}

#########################################MAP
sub MapInitSVG
{ my $out;
  $out=<<___EOR;
  <script>
  function buttonClick(evt) { alert(evt.target.id); }
  </script>
  <style>
  g.button:hover {opacity:0.5;}
  </style>
  <svg height="$MapDimY" width="$MapDimX">
  <rect x="0" y="0" height="$MapDimY" width="$MapDimX" style="fill: #999999"/>
  <image id="map-image" x="0" y="$MapYOffset" height="$MapDimY" width="$MapDimX" xlink:href="$MapFile" />
  <g class="button" cursor="pointer" onmouseup="buttonClick(evt)" >
  <g class="map-legend" > 
___EOR
  $out
}

# add target Map:Location
sub showTargetAddress
{ undef $targetaddress;
  my ($dum,$dum1,$targetaddress)=split(/:/,$UserAction,3);
  if($targetaddress)
  { my $address=&ParcelvAddress($targetaddress);
    my ($markerX,$markerY,$MapDimX,$MapDimY) =
     &xAddress2Pixel($address,$MapParameters);
    next if($markerX !~ /\d/);
    my $mess="";
    if( $markerX<0 or $markerY<0 or $markerX>$MapDimX or $markerY>$MapDimY)
    { $mess="(OUTSIDE MAP)";
    }; 
    my $markerY=$MapYOffset+$markerY;
    my $out=<<___EOR;
<circle cx="540" cy="60" r="$LegendMarkerSize" stroke="black" stroke-width="1" fill="orange" opacity="1."/>
<text x="560" y="70" font-size="$LegendTextSize"> $targetaddress$mess</text>
<circle id="$targetaddress" cx="$markerX" cy="$markerY" 
r="$MapSymbolMarkerSize" stroke="black" stroke-width="1" fill="orange" opacity="1."/>
___EOR
     $out
   }
}


# returns %column {$name} -> column# from $DBname of "Header" key
sub DBHeaderCol
{ my ($DBname)=@_;
  my $headRec=${ $DBname }{ "Header" };
  my @header=split(/\t/,$headRec);
  my %col;
  my $col=0;
  map { $col{ $_ }=$col++ } @header;
  return %col;
}

1;
