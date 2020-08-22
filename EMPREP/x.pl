
sub xShowMap
{ my($mapParmsfile)=@_;
  undef $MapFile;
  undef $MapParameters;
  print "<br>xShowMap:DB--->>mapParmsfile $mapParmsfile>>\n";
  # print "<br>:DB--->>MapFixedSymbols ",join(" ",keys %MapFixedSymbols),">>\n";
  &ParmValueArray( &arrayTXTfile($mapParmsfile) );
  #
  # initial call to set MapDimX MapDimY
  ($markerOffsetX,$markerOffsetY,$MapDimX,$MapDimY)=&Address2Pixel($address,$MapParameters);
  #################################
  undef $svgOut;
  my $svgOut="";
  #################################
  undef @addresses; my @addresses;
  undef %display; my %display;

  # print "<br>DDD>> DisplayType:$DisplayType ";
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

  if($DisplayType eq "DamageStatus")
  { @addresses=&DamageReportAddresses();
    %display=&DamagesForGraphicsPopUp;
  }
  elsif($DisplayType eq "MapCedarHillsideUUD.survey")
  { my $DB= "CedarHillsideUUD";
    &TIE($DB);
    %display=%{$DB};
    @addresses=keys %display;
    for(my $i=0; $i <= $#addresses; $i++)
    { #print "\n---$#addresses: $i >> $addresses[$i]";
      $display{$addresses[$i]}=~s/\t/\n/g;
    }
  }
  elsif($DisplayType eq "MyNeighbors")
  { &TIE("Neighbors");
    my $vAddress="$StreetName=$StreetAddress=$subAddress";
    my $neighbors=$Neighbors{$vAddress};
     print "<br>---Neighbor--->>$vAddress";
     # print "NNN>>$neighbors";
    my @addressesLL=split(/;/,$neighbors);
    @addresses=map {my @a=split(/\t/,$_);$a[0]} @addressesLL;
    #	print "NNN>>@addresses";
    my @LL=map { my @a=split(/\t/,$_);"$a[1]\t$a[2]" } @addressesLL;
    my @LLref=split(/\t/,$LL[0]);
    # print "<br> REF>>@LLref";
    for(my $i=0;$i<=$#addressesLL;$i++)
    { 
      my @LLadd=split(/\t/,$LL[$i]);
      my $dd= sqrt( ($LLadd[0]- $LLref[0])**2+
       	(($LLadd[1]- $LLref[1])/cos(37/180*3.14159))**2 );
      # print "<br>>>@LLadd >> $dd >>@names";
      
      if($dd lt .0008) # distance from ref
      { # print "<br>>>$addresses[$i]";
	my @names=&WhoIsAtAddress($addresses[$i]); 
	if($i==0)
	{ $display{$addresses[$i]}= "Home:".join(", ",@names);
	}
	elsif($#names ge 0)
	{ $display{$addresses[$i]}= "MyNeighbor:".join(", ",@names);
	}
	else
	{ $display{$addresses[$i]}= "NoData:ReachOut";
	}
	$display{$addresses[$i]}=~s/\t/; /g;
	# print "<br>>> $display{$addresses[$i]}";
      }
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
  { # print "\n <br>--->>$address";
    my $addressParcel=&ParcelvAddress($address);
      my ($markerX,$markerY,$MapDimX,$MapDimY) 
        =&Address2Pixel($addressParcel,$MapParameters);
	#print "\n<br>DB:--->> addressParcel $addressParcel : $markerX, $markerY, $MapDimX, $MapDimY" ; 
	#	print "\n<br>DB:--->> MapParameters $MapParameters  " ; 
    next if($markerX !~ /\d/); # NO pix data
    if( $markerX<0 or $markerY<0 or $markerX>$MapDimX or $markerY>$MapDimY) 
    { push @notOnMap,$address;
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
<circle $class cx="$markerX" cy="$markerY" 
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

