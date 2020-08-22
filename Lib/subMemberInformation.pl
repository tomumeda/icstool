#!/usr/bin/perl

require "subCommon.pl";
require "subMemberDB.pl";

sub initialFormData	#	
{ my $tmp,@tmp;
  # $Timestamp=$Timestamp;
  $defaults{"Timestamp"}="$Timestamp";

  $LastName=~s/'/&#39;/g;	# if apostrophies in name

  my @streets=keys %MapStreetAddressesEmPrep;
  if($StreetName ne "(Other)" and $StreetName ne "")
  { $defaults{"StreetName"}=$StreetName;
    $MapStreetAddressesEmPrep{$StreetName}
      =&deleteDuplicatesTab("$MapStreetAddressesEmPrep{$StreetName}\t$StreetAddress");
    @streets=keys %MapStreetAddressesEmPrep;
  }
  else
  { $defaults{"StreetName"}="";
  }

  @streets=&deleteNullItems(@streets);
  push(@streets,"(Other)");
  unshift(@streets,"");
  $values{"StreetName"}= join("\t",@streets);
  $size{"StreetName"}=1;
  $multiple{"StreetName"}="false";

  ############################################
  my @GroupNames=&arrayTXTfile("GroupNames.txt");
  # print "XX GroupNames @GroupNames";
  $values{"GroupAffiliation"}= join("\t",@GroupNames);
  @tmp=split(/,/, $GroupAffiliation); # Incomming values
  @tmp=map {$tmp=&clean_name($_);$tmp} @tmp;
  #	$tmp=join("\t",@tmp);
  $size{"GroupAffiliation"}=5;
  $defaults{"GroupAffiliation"}=join("\t",@tmp);
  $multiple{"GroupAffiliation"}='true';

  #############################################
  $values{"InvolvementLevel"}= join("\t", split(/,/,"Active,NoEmail Active,No Involvement"));
  $defaults{"InvolvementLevel"}="$InvolvementLevel";
  # $defaults{"InvolvementLevel"}="Active";
  $size{"InvolvementLevel"}=1;
  $multiple{"InvolvementLevel"}="false";

  #############################################
  my @skills=split(/,/,
    "FireSuppression,SearchAndRescue,Communications,FirstAid");
  $values{"SkillsForEmergency"}= join("\t",@skills);
  my @tmp=split(/,/, $SkillsForEmergency); # Incomming values
  @tmp=map {my $tmp=&clean_name($_);$tmp} @tmp;
  #	@tmp=join("\t",@tmp);
  $defaults{"SkillsForEmergency"}=join("\t",@tmp);

  #############################################
  @ACAlertSignUp=split(/,/,"No,Yes");
  $values{"ACAlertSignUp"}= join("\t",@ACAlertSignUp);
  $defaults{"ACAlertSignUp"}= $ACAlertSignUp;
};

sub memberForm
{ my $q=$_[0];
  &initialFormData;
  #print $q->h3("Member Information Form");
  print <<___EOR;
  <table width=100%>
  <tr> 
  <th id="head" colspan="3"> Member Information Form </th>
  </tr> 
  <tr> 
  <th width="20%" font-size:"150%" color="red" > Label  </td>
  <th width="40%"> Information  </td>
  <th width="40%"> Description  </td>
  </tr> 
___EOR

  my @list=&readCSVdesc("FormData");

  for(my $i=0;$i<=$#list;$i++)
  { $_=$list[$i];
    ($label,$type,$parameters)=split("\t",$_);
    # print "<br>($label,$type,$parameters)";

    if($type eq "date")
    { print $q->Tr
      ( $q->td ("$label:"),
	$q->td ( $q->textfield("$label","${$label}",20,20)),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "number")
    { print $q->Tr
      ( $q->td ("$label:"),
	$q->td ( "<input type=number name=$label value=${$label} >"),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "email")
    { print $q->Tr
      ( $q->td ("$label:"),
        $q->td( "<input type=textfield name=$label placeholder=your\@email.address value='${$label}' > "
	),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "textfield")
    { print $q->Tr
      ( $q->td ("$label:"),
        $q->td("<input type=textfield name='$label' value='${$label}'"),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "textarea")
    { print $q->Tr
      ( $q->td ("$label:"),
	$q->td ( $q->textarea("$label","${$label}",04,50)),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "radio_group")
    { my @values=split(/\t/,$values{$label});
      print $q->Tr
      ( $q->td("$label:"),
	$q->td
	( $q->radio_group
	  ( "$label",
	    [split(/\t/,$values{$label})],
	    [split(/\t/,$defaults{$label})],
	    $columns{$label}
	  )
	),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "checkbox_group")
    { my @values=split(/\t/,$values{$label});
      my @default=split(/\t/,$defaults{$label});
      @other=&deleteElements($values{$label},@default);
      my $other=join("; ",@other);
      @default=&deleteElements( join("\t",@other) , @default);
      @default=map {&string_NoBlank($_)} @default; # names have no spaces
      my $i;
      @default=map { 
	if(($i=&MemberQlc(@values,$_)) ge 0) 
	{ $tmp=$values[$i] }
	else
	{ $tmp=$_ };$tmp
      } @default;
      print $q->Tr
      ( $q->td("$label:"),
	$q->td
	( $q->checkbox_group
	  ( -name=>"$label",
	    -values=>[@values],
	    -default=>[@default],
	    -linebreak=>1
	  ),
          "<br><input type=textfield name=$label placeholder='(Other)' 
	    value='$other' -size=100> " 
	),
	$q->td("<small>".$descriptor{$label})
      );
    }

    if($type eq "scrolling_list")
    { my @values=split(/\t/,$values{$label});
      my @other=split(/\t/,$defaults{$label});
      @other=&deleteElements($values{$label},@other);
      my $other=join(";",@other);
      my @default=split(/\t/,$defaults{$label});
      print $q->Tr
      ( $q->td("$label:"),
	$q->td (
	  &scrolling_list ( "$label", [@values], [@default],
	    $size{$label},
	    $multiple{$label}
	  )
	),
	$q->td("<small>".$descriptor{$label})
      );
      if($values{$label}=~m/\(Other\)/)
      { print $q->Tr
	( $q->td ("(Other)$label:"),
	  $q->td ( $q->textfield("(Other)$label","$other",40,80)),
	  # $q->td("<small>".$descriptor{$label})
	);
      }
    }

    if($type eq "popup_menu")
    { my @values=split(/\t/,$values{$label});
      my @other=split(/\t/,$defaults{$label});
      @other=&deleteElements($values{$label},@other);
      my $other=join(";",@other);
      my $default=$defaults{$label};
      print $q->Tr
      ( $q->td("$label:"),
	$q->td ( &popup_menu ( "$label", [@values], "$default" ) ),
	$q->td("<small>".$descriptor{$label})
      );
      if($values{$label}=~m/\(Other\)/)
      { print $q->Tr
	( $q->td ("(Other)$label:"),
	  $q->td ( $q->textfield("(Other)$label","$other",40,80)),
	  # $q->td("<small>".$descriptor{$label})
	);
      }
    }

    if($type eq "tel")
    { print $q->Tr(
	$q->td("$label "),
	$q->td(
	  " <input type=tel name=$label
	    placeholder=format[123-456-7890]
	    value='${$label}'
	    pattern=[0-9]{3}[-]{0,1}[0-9]{3}[-]{0,1}[0-9]{4} size=15> "
	),
	$q->td("<small>".$descriptor{$label})
      )
    }
  }
  print <<___EOR;
  </table>
___EOR
  $q->param("LastForm","memberForm");
  &hiddenParam($q,'LastForm');
};

# Outputs a footer line and end html tags
sub output_end 
{ my ($q) = @_;
  print $q->end_html;
}

#######################################################333

# Outputs a web form
sub output_form 
{
  my ($q) = @_;
  print $q->start_multipart_form( -name => 'main', -method => 'POST');
  #####################################
  &memberForm($q);
  #####################################
  print $q->Tr(
     $q->td($q->submit(-name=>'action', -value=>'Submit Info')),
     $q->td($q->submit(-name=>'action', -value=>'Cancel'))
  );

  #&TIE("Images");	#	? Is this needed
  my $Name="$LastName\t$FirstName";
  print $q->hr;
  print $q->h3("Images for: $Name");
  foreach my $type (
    "Selfie",
    "Housemates",
    "Building"
  ) 
  {
    print "<br>
    <h5> $type </h5> 
    <br>
    <table> <tr>";
    my $ntab=${"Images/$type"}{"$Name"};
    my @ntab=split(/\t/,$ntab);
    for(my $n=0;$n<=$#ntab;$n++)
    { 
      my $image=${"Images/Index"}{$ntab[$n]};
      open Ltxt,"$ICSdir/DB/Images/Descriptor/$ntab[$n].txt";
      my $imageDescriptor=<Ltxt>;
      print <<___EOR;
      <td>
      <img src="$image" alt="$type" width="100" />
      <br>$imageDescriptor
      <br>

      <input type='submit'  
        value='ImageDelete' 
        name='ImageDelete:$type,$Name,$ntab[$n]'
	</input>

      </td>
___EOR
    }
    print "</tr>";
    print "</table>";
  }
  print $q->submit(-name=>'action', -value=>'Add Images');
  print "Add Images";
			#
  print $q->hr;
  print $q->h3("Downloads");
  print $q->submit(-name=>'action', -value=>'Downloads'), "Downloads Available" ;
  print $q->hr;
  print $q->submit(-name=>'action', -value=>'View Maps'), "View Maps" ;
  print $q->hr;
  print $q->end_form;
};

sub readCSVdesc
{ my $file=$_[0];
  my @items=();
  open L,"$CSVroot.$file" || die;
  while(<L>)
  { chop;
    next if(/^\s*$/);	# no blank line
    next if(/^#/ );	# no comment lines
    push @items,$_;
  }
  close L;
  #print "<br>>>>readCVSdescrip",join("<br>",@items);
  return @items;
};

sub FindMyName
{ my $search=@_[0];
  my @search=split(/[\s,;]/,$search);
  undef %foundnames;
  my $i,%foundnames;
  my @name=keys %DBrecName;
  # print "<br>>>>> name, @name";
  for($i=0;$i<=$#name;$i++)
  { if( &AllMatchQ($name[$i],@search)==1 )
    { $foundnames{$name[$i]}=$DBrecName{$name[$i]} ;
    }
  }
  return(%foundnames);
}

sub  SetNewNameVars
{ for(my $i=0;$i<=$#colNames;$i++)
   { ${$colNames[$i]}="";
     undef ${$colNames[$i]};
     undef @{$colNames[$i]};
   }
   &undefDBvar;
   #	DEFAULTS
   #	$DivisionBlock="";
   #	$InactiveMember="No";
   $ACAlertSignUp="No";
   $defaults{"StreetName"}="";
}

sub loadNameData
{ 
  $DBrecNumber=${"DBrecName"}{"$LastName\t$FirstName"};
  #print "<br>>>>$DBrecNumber; $LastName\t$FirstName";

  if(defined($DBrecNumber) and $DBrecNumber>=0 
  )
  { 
    &SetDBrecVars($DBrecNumber);
    @SkillsForEmergency=split(/,/,$SkillsForEmergency);
    @SkillsForEmergency=map {$tmp=&clean_name($_);$tmp} @SkillsForEmergency;
    @GroupAffiliation=split(/,/,$GroupAffiliation);
  }
  else
  { &SetNewNameVars;
  }
########################################
  #	Make into standard format
  $HomePhone=~s/^[^\d]*(\d{3})[^\d]*(\d{3})[^\d]*(\d{4})(\d*)$/$1-$2-$3/;
  $CellPhone=~s/^[^\d]*(\d{3})[^\d]*(\d{3})[^\d]*(\d{4})(\d*)$/$1-$2-$3/;
}

sub undefDBvar
{ for(my $i=0;$i<$#DBmasterColumnLabels;$i++)
  { my $var=$DBmasterColumnLabels[$i]; #TEST print "<br>undef $var>>${$var}\n";
    undef ${$var};
    undef @{$var};
  }
}

sub undefList
{ my $list=@_[0];
  my @list=split(/,/,$list);
  for(my $i=0;$i<=$#list;$i++)
  { my $var=$list[$i]; #TEST 
    # print "<br>undef $var>>${$var}\n";
    undef ${$var};
  }
}

sub checkData
{ my $missing="";
  #	print ">>>> @requiredInputs";
  foreach my $name (@requiredInputs)
  { # print "NNN $name ${$name} NNN";
    if( "${$name}" eq "")
    { $missing.=" $name";
    }
  }
  if($missing ne "") { return("$missing"); }
  else { return("ok"); }
}

sub UpdateDBvariables
{ my ($dbrecno)=@_;
  undef @col;
  my @col=();
  $Timestamp=$timestamp;
  for($i=0;$i<=$#DBmasterColumnLabels;$i++)
  { #DB format adjust
    $SkillsForEmergency=join(",",@SkillsForEmergency);	
    $GroupAffiliation=join(",",@GroupAffiliation);	
    #DB format adjust
    $col[ $DBcol{$DBmasterColumnLabels[$i]} ]=${$DBmasterColumnLabels[$i]};
    # print "<br>DDD UpdateDB=$DBmasterColumnLabels[$i]=${$DBmasterColumnLabels[$i]}<br>@{$DBmasterColumnLabels[$i]}";
  }
  my $dbrec=join("\t",@col);
# @DBname=&MakeArray("DBmaster, DBrecName, DBrecAddress, DBrecSkills, DBSpecialNeeds, DBAddressOnStreet, DBrecEmergencyEquipment, DBcontactInfo, DBrecPets, DBrecVisitors");
  ${"DBmaster"}{$dbrecno}=$dbrec; # add complete record to masterDB
  ${"DBrecName"}{"$LastName\t$FirstName"}=$dbrecno;
  #
  # add to pointer DBs into DBmasster by following keys
  #if($InactiveMember!~/yes/i)
  { 
    &MergeKeyValue("DBrecAddress","$StreetName=$StreetAddress=$subAddress",$dbrecno); 
    &MergeKeyValue("DBAddressOnStreet","$StreetName",$StreetAddress); 
    &MergeKeyValue("DBrecSkills","$SkillsForEmergency",$dbrecno);
    &MergeKeyValue("DBrecEmergencyEquipment","$EmergencyEquipment",$dbrecno); 
    &MergeKeyValue("DBrecSpecialNeeds","$SpecialNeeds",$dbrecno); 
    &MergeKeyValue("DBrecPets","$Pets",$dbrecno); 
    &MergeKeyValue("DBrecVisitors","$Visitors",$dbrecno); 

    # add contact info for StreetName=StreetAddress=subAddress
    my $str="";
    if($HomePhone) { $str.="HomePhone:$HomePhone\n"; }
    if($CellPhone) { $str.="CellPhone:$CellPhone\n"; }
    if($EmailAddress) { $str.="EmailAddress:$EmailAddress\n"; }
    if($str ne "")
    { $str="($LastName,$FirstName)\n$str";
      &MergeKeyValue("DBcontactInfo","$StreetName=$StreetAddress=$subAddress",$str);
    }
    # add Special consideration for StreetName=StreetAddress=subAddress
    my $name="FirstLastName:$FirstName:$LastName\t";
    $str="";
    if($SpecialNeeds) { $str.="SpecialNeeds:$SpecialNeeds\t"; }
    if($Pets) { $str.="Pets:$Pets\t"; }
    if($Visitors) { $str.="Visitors:$Visitors\t"; }
    if($str ne "")
    { &MergeKeyValue("DBSpecialNeeds","$StreetName=$StreetAddress=$subAddress","$name$str");
    }
  }
}

##################################################3
# return an array of people at vAddress input
sub RecsForAddress
{ my ($vAddress)=@_;
#  my ($streetname,$streetaddress,$subaddress)=&vAddress2Array($vAddress);
#my @foundIndex=();
  my @foundRec=();
  my @recn=sort {$a <=> $b} keys %DBmaster;

  # print "<br> ====== recn: @recn : $vAddress == ",%{"DBmaster"};

  for($i=0;$i<=$#recn;$i++)
  { my $rec=$DBmaster{ $recn[$i] };

    my @col=split(/\t/, $rec);
    my $DBstreet=$col[$DBcol{StreetName}];
    my $DBaddress=$col[$DBcol{StreetAddress}];
    my $DBsubaddress=$col[$DBcol{subAddress}];
    my $DBinvolvement=$col[$DBcol{InvolvementLevel}];

    my $DBvAddress=&vAddressFromArray($DBstreet,$DBaddress,$DBsubaddress);
    #if( "$streetname $streetaddress $subaddress" eq "$DBstreet $DBaddress $DBsubaddress" )
    if( $DBvAddress eq $vAddress and $DBinvolvement =~ m/Active/ )
    { #push(@foundIndex,$recn[$i]); 
      push(@foundRec,$rec); 
    }
  }
  return @foundRec;
}

sub WhoIsAtAddress
{ my $vAddress=$_[0];
  # print "<br> WhoIsAt vAddress:$vAddress";
  my @recn=&RecsForAddress($vAddress);
  # print "<br>RECN: @recn";

  my @names=();
  for(my $i=0;$i<=$#recn;$i++)
  { #my $rec=$DBmaster{ $recn[$i] };
    my @col=split(/\t/, $recn[$i]);
    my $firstname=$col[$DBcol{FirstName}];
    my $lastname=$col[$DBcol{LastName}];
    my $out="$lastname\t$firstname";
    push @names,$out;
  }
  @names;
}


1;
