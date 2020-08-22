#!/usr/bin/perl
#
sub MemberInformation
{ my $q=$_[0];
  require "subMemberInformation.pl";
  #  &setDescriptor;
#######################################################
  $CSVroot="$ICSdir/DB/MasterDB.csv";
  #  &Set_timestr;
  @requiredInputs=();	# from Descriptor file

  my @list=&readCSVdesc("Descriptor");	# Load $CSVroot.Descriptor
  @colNames=();
  for($i=0;$i<=$#list;$i++)
  { my ($label,$text)=split(/\t/,$list[$i]);
    my $red= &COMMENT("(required)");
    $colNames[$i]=$label;
    $text=~s/\(required\)/$red/;
    $descriptor{$label}=$text;
    # print "<br>>>>>descriptor $text";
    if($descriptor{$label}=~m/\(required\)/)
    { push(@requiredInputs,$label);
    }
  }
  #  print ">>>>>@requiredInputs";
#######################################################

  if( ($imagedelete = &FindMatchQ("ImageDelete:",@params)) >-1 )
  { $imagedelete=$params[$imagedelete];
    $action="ImageDelete";
  }

  if($StreetName =~m/"(Other)"/)
  { $StreetName = ${"(Other)StreetName"};
  }
  #	print "<br>StreetName=$StreetName<<<<";
  &var2param($q,'LastName','FirstName','StreetName','StreetAddress','subAddress');
#	input adjustments
  $FindMyName=~s/[\W\d]//g if($FindMyName); #print "FindMyName ==$FindMyName== <br>";
#######################################################
#print "YYY @DBname HHH";
  &TIE( @DBname );
  &TIE("MapStreetAddressesEmPrep");

  @DBkeys=keys %{"DBmaster"};
  # undef %Images;
  &TIE("Images/Index");
  &TIE("Images/Selfie");
  &TIE("Images/Housemates");
  &TIE("Images/Building");

#######################################################
  print &HTMLMemberInfoHeader();
#######################################################
  #  print $q->h2("Member Information");
  print $q->h2(
"<a href='Info/MemberInformation.html'>
<p style='font-size:25px;text-align:center'>Member Information</p> </a> ");

#######################################################
   # print "<br>(000 action=$action>>FindMyName=$FindMyName>>$NameChoice=$NameChoice";
  if( ($action eq "Cancel" 
      or $action eq "Finished" )
      and $usertype ne "SingleUser" ) 
  { goto STARTMENU;
  }

  elsif( $action eq "Downloads")
  { goto DOWNLOAD;
  }

  elsif( $action eq "Submit Info") 
  { goto SUBMITINFO;
  }

  elsif( $LastForm eq "ChooseNameForm" and $FindMyName ) 
  { goto CHOOSENAME;
  }

  elsif( $action eq "Add Images" ) 
  { goto IMAGES_ADD;
  }

  elsif( $action eq "Upload Image" ) 
  { goto IMAGES_UPLOAD;
  }

  elsif( $action eq "ImageDelete" ) 
  { goto IMAGES_DELETE;
  }

  elsif( $action eq "NewName" ) 
  { &undefDBvar;
    goto NEWNAME;
  }

  ######
  elsif( $action eq "View Maps" ) 
  { goto VIEWMAPFORM;
  }

  ######
  elsif( $action =~m/^Map:/ ) 
  { $UserAction=$action;
    &ViewMap($q);
    goto EXIT;
  }

  elsif( $action eq "FindMyName" and $FindMyName ) 
  { goto CHOOSENAME;
  }

  elsif( $usertype eq "SingleUser" and $LastName and $FirstName ) 
  { goto MEMBERINFOFORM;
  }

  elsif( $NameChoice ) 
  { ($LastName,$FirstName)=split(/[\t,]/,$NameChoice);
    goto MEMBERINFOFORM;
  }

  elsif( $action eq "FindMyName" and !$FindMyName ) 
  { goto STARTMENU;
  }

  elsif( $LastForm eq "ChooseNameForm" and $FindMyName ) 
  { goto CHOOSENAME;
  }

  else
  { print &COMMENT("<br>=== MENU ERROR ===<br>");
    goto STARTMENU;
  }
#########################################33
    VIEWMAPFORM:
    &ViewMembershipMapsForm($q);
    goto EXIT;
#######################
  NEWNAME:
    &SetNewNameVars;
    #print "<br>>>>NEWNAME $action, $FirstName,$LastName,$StreetName ";
    &output_form($q);	
    goto EXIT;
#########################################33
  CHOOSENAME:
  # print "<br>YYY CHOOSENAME $FindMyName== YYY";
    &undefDBvar;
    #undef $LastName,$FirstName,$NameChoice;
    undef %possiblenames;
    my %possiblenames;
    %possiblenames=&FindMyName($FindMyName);
    my @possiblenames=keys %possiblenames;
    # print "<br>XX possiblename >>$FindMyName XXX===",keys %possiblenames,"===";
    #
    my $message=&COLOR("orange","Select your name");
    if($#possiblenames<0)
    { $message=&COMMENT("No names in database matches: $FindMyName");
    }
    my $cmd="<table border=1 width=940 cellspacing=0 cellpadding=5>";
    $cmd.=$message;
    for(my $i=0;$i<=$#possiblenames;$i++)
    { 
      my $name=$possiblenames[$i];
      $name=~s/'/&#39;/g;
      # print "<br>>>>NNAME $name";
      $cmd.="<tr>
      <td><input type=submit name=NameChoice value='$name' >
      </td></tr>";
    }
    $cmd.="<tr>
    <td><input type=textfield name=FindMyName placeholder='( Retry )'> 
    <input type=submit name=action value='FindMyName'> 
    </tb> </tr>
    <tr> <td><input type=submit name=action value='Cancel'> </td> </tr>";
    $cmd.="</table></fieldset>";
    print $q->start_form( -name => 'main', -method => 'POST',);
    print $cmd;
    $q->param("LastForm","ChooseNameForm");
    &hiddenParam($q,'LastForm');
    print $q->end_form;
    goto EXIT;

#elsif( $action eq "Cancel" or !$FirstName or !$LastName )
  STARTMENU:
# print "YYY StartMenu YYY";
    print $q->start_form( -name => 'main', -method => 'POST',);

    print &COMMENT("Find your name: ");
    print $q->textfield(-name=>'FindMyName',-size=>20, -placeholder=>'partial name OK') ;
    print $q->submit('action','FindMyName');
    print &COMMENT("<br>If you are not registered, click here: "),
	  $q->submit('action','NewName');
    print "<br>";
    print hr();

    print $q->submit('action','Downloads');
    ###
    
    print hr();
    print $q->submit('action','View Maps');
    print "<br>";

    print $q->end_form;
    goto EXIT;

  SUBMITINFO:
    #print "<br>YYY $action YYY";
    if($StreetName =~ m/\(Other\)/)
    { $StreetName=${"(Other)StreetName"}
    }
    if( ($check=&checkData) eq "ok")
    { #	correct for (Other)StreetName
      #	print "<br>AAA StreetName=$StreetName=",${"(Other)StreetName"};
      #	print "<br>AAA2 StreetName=$StreetName=",join("=",@StreetName);

      $DBrecNumber=${"DBrecName"}{"$LastName\t$FirstName"};
      if($DBrecNumber ge 1)
      { print &COMMENT("<br> $FirstName $LastName -- Updated $DBrecNumber<br>");
      }
      else
      { $DBrecNumber=$#DBkeys+1;
	print &COMMENT("<br> $FirstName $LastName -- Added $DBrecNumber <br>");
      }
      # print "CCC Skills:: $SkillsForEmergency;;@SkillsForEmergency";
      &UpdateDBvariables($DBrecNumber);
      print &COMMENT("!! THANK YOU !!<br>");
      #	
      if( $usertype eq "SingleUser")
      { goto MEMBERINFOFORM;
      }
      #	
      my $cmd="<table border=1 width=940 cellspacing=0 cellpadding=5>";
      $cmd.="<tr>
      <td><input type=textfield name=FindMyName placeholder='( New Name )'> 
      <input type=submit name=action value='FindMyName'> 
      </td> </tr>
      <tr> <td><input type=submit name=action value='Cancel'> 
      </td> </tr>";
      $cmd.="</table></fieldset>";

      print $q->start_form( -name => 'main', -method => 'POST',);
      print $cmd;
      print $q->end_form;
      undef $action;
    }
    else
    { print &COMMENT("<br> Check required fields: "), $check ;
      &output_form($q);	# memberForm
    }
    goto EXIT;

  MEMBERINFOFORM:
    &loadNameData;
    &output_form($q);	# memberForm
    goto EXIT;

  DOWNLOAD:
    &makeCSV;
    ##################
    my $filename="MasterDB.$yyyymmddhhmmss.csv";
    my $cmd=
    "<table>
    <tr>
      <td>
	<a href=DB/Downloads/$filename download> 
	  Member database: $filename (comma-separated-variable spread sheet)
	</a>
      </td> 
    </tr>
      <td>
	<a href=Maps/rooftops.EmPrep.jpg download> 
	EmPrep Rooftop Map (.jpg)
      </td>
    </tr>
    <tb>";
      $cmd.="</table></fieldset>";

    print $q->h3("Available Downloads");
    print hr();
    print $q->start_form( -name => 'main', -method => 'POST',);
    print $cmd;
    print hr();
    print $q->submit('action','Finished');
    print $q->end_form;
    goto EXIT;
#########################################33
  IMAGES_ADD:  
    &loadNameData;
    my $name="$LastName\t$FirstName";
    my $address=&vAddressFromArray($StreetName,$StreetAddress,$subAddress);
    &ImageUpload($q,"$name","$address");
    goto EXIT;
#########################################33
  IMAGES_DELETE:  
  { my $parm=$imagedelete;
    $parm=~s/ImageDelete://;
    my ($type,$name,$ntab)=split(/,/,$parm);
    &ImageDelete($q,"$type","$name","$ntab");
    
    goto MEMBERINFOFORM;
  }
#########################################33
  IMAGES_UPLOAD:  
    &loadNameData;
    #	print ">>>>>>IMAGES_UPLOAD:PARAM:",$q->param;
    $q->delete('action');
    $q->param('action',"Add Images");
    my $address=&vAddressFromArray($StreetName,$StreetAddress,$subAddress);
    my $name="$LastName\t$FirstName";

    	print "<br>IMAGES_UPLOAD>>$ImageCategory=$name=$address";
    &save_image_file($ImageCategory,$name,$address);

    goto EXIT;
#########################################33

  EXIT:
  &output_end($q);
  &UNTIE( @DBname );
}

#############################
sub makeCSV
{
  # $downloadfile="$ICSdir/Download/MasterDB.$yyyymmddhhmmss.csv";
  &TIE( @DBname );
  open L1,"$ICSdir/DB/MasterDB.csv" || die; # for HEADER
  open L3,">$ICSdir/DB/Downloads/MasterDB.$yyyymmddhhmmss.csv";
  # copy first 2 lines HEADER
  for(my $i=0;$i<2;$i++)
  { $_=<L1>;
    print L3 $_;
  }
  my @recn=sort {$a <=> $b} keys %DBmaster ;
  for(my $i=0;$i<=$#recn;$i++)
  { my $rec=$DBmaster{$recn[$i]};
    $rec=~s/\n/; /g;
    my @col=split(/\t/, $rec);
    $#col=$#DBmasterColumnLabels;
    &PrintCol(@col);
  }
  close L3;
}

1;

