#!/usr/bin/perl
# require "subCommon.pl";
# use CGI qw/:standard/;
# use CGI::Carp qw/fatalsToBrowser/;
# INITIALIZATION
# @Factions=('SelectStreet'); #function actions ONLY ONE
# 

@damageassessmentParm=(); #global variable
my @damagechoice=&arrayTXTfile("Lists/DamageChoices.txt");
&DEBUG("damagechoice: @damagechoice ");
my @list;
for(my $i=0;$i<=$#damagechoice;$i++)
{ my $data=$damagechoice[$i];
  my ($damage,$choices,$multiple)=split(/:/,$data);
  @choice=split(/,/,$choices);
  $assessment=$damage."Assessment";
  push (@damageassessmentParm,$assessment);
  push (@damageassessmentChoices,$choices);
  push (@damageassessmentMultiple,$multiple);
  if($multiple =~ /multiple/)
  { push(@list,"\@$assessment");
  }
  else
  { push(@list,"$assessment");
  }
}
$damageassessmentParmlist=join(",",@list);
&DEBUG("damageassessmentParmlist: $damageassessmentParmlist ");
################################################################

sub DamageReportForm
{ my $q=@_[0];
  my $DamageAddress = $q->param("DamageAddress" );
  if($DamageAddress and $action eq "SelectReportedAddress")
  { $q->param("vAddress",$DamageAddress);
  }
  $q->param("LastAction","$UserAction");
  $q->param("LastForm","DamageReportForm");
 
  &DEBUG("DamageReportForm0: ",&inputAddress($q));
  $vAddress=$q->param('vAddress');
  ######################################
  # NewStreet NewAddress update
  my $street = $q->param("SelectStreet" );
  my $address = $q->param("SelectAddress" );
  my $subaddress = $q->param("SelectSubAddress" );
  my $DamageAddress = $q->param("DamageAddress" );
  if($DamageAddress and $action eq "SelectReportedAddress")
  { ($street,$address,$subaddress)=&vAddress2Array($DamageAddress);
    my $vAddress = $DamageAddress;
    $q->param("vAddress",$vAddress);
    $q->param("SelectStreet",$street);
    $q->param("SelectAddress",$address);
    $q->param("SelectSubAddress",$subaddress);
  }
  my $newstreetname=$q->param("NewStreetName");
  my $newaddress=$q->param("NewAddress");
  if( $newstreetname and $newstreetname ne "")
  { $street=$newstreetname;
    $q->delete("SelectStreet");
    $q->param("SelectStreet",$street );
    # ADD street name to list
    my $f = "AddressesOn/$street"; 
    if( ! -e "$ICSdir/$f" ) 
    { &openICS(L,">",$f);
    }
  }
  if( $newaddress and $newaddress ne "New Address") 
  { $address=$newaddress;
    $q->delete("SelectAddress");
    $q->param("SelectAddress",$address );
    #print "###:",$newaddress;
    my @address=&arrayTXTfile("AddressesOn/$street");
    &saveArray2TXTfile("AddressesOn/$street",&uniq(@address,$address));
  }
  $q->delete("NewStreetName");
  $q->delete("NewAddress");
  #print "#####$address and $street and $DamageAddress";
  #########################################
  #if( $address and $street )
  &DEBUG("DamageReportForm1: ",$vAddress);
  if( $vAddress )
  { &DamageAssessmentForm($q);
    #$q->param("LastAction","DamageAssessmentForm");
    #$q->param("LastForm","DamageAssessmentForm");
    my @actions=('Submit','Send Team','Cancel>Home');
    &SubmitActionList(@actions);
    # 
    &DisplayHistory($BlockSeparator,"$vAddress"); 
    print hr(),$q->submit(-name=>'ShowInfo:DamageAssessmentForm', -value=>'Help', -id=>'helpButton');
    &hiddenParam($q,"UserName,UserAction,LastForm,SelectStreet,SelectAddress,SelectSubAddress,LastAction,vAddress"); 
    print $q->end_form;
  }
  else
  { &DEBUG("DamageReportForm:$street:$address:");
    &StreetAddressForm($q,$street,$address,
      "UserName,UserAction,SelectStreet,SelectAddress,LastAction"); 
  }
}

sub StreetAddresses
{ my $street=@_[0];
  my @lines;
  &openICS(L,"AddressesOn/$street");
  while(<L>)
  { chop;
    next if( /^#/);     # comment
    next if( /^$/);     #null line
    push @lines,$_;
  } 
  close L;
  return @lines;
}

sub PeopleAtAddress
{ my $AddressStreet=@_[0];
  my ($address,$street)=split(/=/,$AddressStreet);
  my @foundI=();
  &TIE( @DBname );
  my @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { next if( ! &ActiveMember($i));
    my $rec=$DBmaster{ $recn[$i] };
    my @col=split(/\t/, $rec);
    my $DBaddress=$col[$DBcol{StreetAddress}];
    my $DBstreet=$col[$DBcol{StreetName}];
    my $FirstName=$col[$DBcol{FirstName}];
    my $LastName=$col[$DBcol{LastName}];
    my $Phone=$col[$DBcol{HomePhone}];
    my $Cell=$col[$DBcol{CellPhone}];
    if( "$address $street" eq "$DBaddress $DBstreet" )
    { push(@foundI,"{$FirstName $LastName:$Phone:$Cell}"); 
    }
  }
  &UNTIE( @DBname );
  return "@foundI";
}

###########################
# restore_DamageAssessment from file name
# returns NULL if no file
sub restore_DamageAssessment 
{ 
  #my ($street,$address,$subaddress) = @_;
  my ($vAddress) = @_;#VADD
  #my $streetaddress=&vAddressFromArray( $street,$address,$subaddress );
  #my $file="Damages/$streetaddress";
  my $file="Damages/$vAddress"; #VADD
  # print "$file<br>";
  if(-e "$ICSdir/$file")
  { if (&openICS(FILE,$file)) 
    { $q = new CGI(FILE);  # Throw out the old q, replace it with a new one
      close FILE;
    } 
  }
  return $q;
}

# file_DamageAssessment from file 
sub file_DamageAssessment 
{ my ($file) = @_;
  if(-e "$ICSdir/$file")
  { if (&openICS(FILE,$file)) 
    { $q = new CGI(FILE);  # Throw out the old q, replace it with a new one
      close FILE;
    } 
  }
  return $q;
}

sub save_DamageAssessment
{ my ($q) = @_;
  #my $subaddress = $q->param('SelectSubAddress');
  #my $address = $q->param('SelectAddress');
  #my $street = $q->param('SelectStreet');
  my $vAddress=&vAddressFromParam($q);
  # print "DEBUG: $street, $address, $subaddress, $streetaddress<br>";
  my $statusfile = "Damages/$vAddress";
  my $logfile = "DamageLogs/$vAddress";
  $q->param('UXtime',$UXtime);
  $q->param('StreetAddress',$vAddress); #VADD ??
  $q->param('vAddress',$vAddress);
  $q->param('time',$timestr);
  ########################
  my $parmlist=$damageassessmentParmlist.",SelectStreet,SelectAddress,SelectSubAddress,Notes,UXtime,UserName,Notes,ReportedBy,vAddress";
    &saveParmsCGIfile($q,$statusfile,$parmlist);
  ###################### Log file
  my $parmOut=$damageassessmentParmlist.",SelectStreet,SelectAddress,SelectSubAddress,Notes,UXtime,UserName,Notes,ReportedBy,time,vAddress";
  &logParmsCGIfile($q,$logfile,$parmOut);
}

##########################################
# Loads all Damage info in Damages/* 
# Returns catatenated string of all info.
sub LoadDamageData
{ undef $data;
  my $file,$data;
  &DEBUG("LoadDamageData:0: $data");
  foreach $file (<"$ICSdir/Damages/*">)
  { if (&openICS(FILE,$file)) 
    { my $q = new CGI(FILE);  # Throw out the old q, replace it with a new one
      close FILE;
      my @parm=$q->param;
      &DEBUG("LoadDamageData:parms: @parm");
      foreach my $p (@parm)
      { my @values=$q->param("$p");
	@values=&changeNL2character(@values); # NL creates problems
	$p=~s/\: //;  # remove undocumented feature of paramname
	for($i=0;$i<=$#values;$i++)
	{ $data.="$p=$values[$i]\n";
	}
      }
    } 
    $data.="$BlockSeparator\n";
  }
  return $data;
}

# Returns a list of info blocks
# for parameter e.g., FireSuppressionUrgency, that has a value != None.
sub DamagesByParameter
{ my ($parm_choice,$value_choice)=@_;
  my @subblock,@block,$l,@info,$address,$d; 
  my @outBlocks; $#outBlocks=-1;
  my %blockTime;
  #
  my $data=&LoadDamageData;
  my @blocks=split(/$BlockSeparator\n/,$data);
  &DEBUG("DamagesByParameterA: $#blocks");
  # block all damages 
  for(my $i=0;$i<=$#blocks;$i++)
  { my @lines=split(/\n/,$blocks[$i]);
    for(my $j=0;$j<=$#lines;$j++)
    { next if($lines[$j]=~/^action/);
      next if($lines[$j]=~/^.cgifields/);
      if( $lines[$j] =~ m/UXtime=(\d*)/ )
      { $blockTime{$1}=$i;
      }
    }
  }
  # special treatments
  if ( $parm_choice =~ "^NewestFiveAssessment" )
  { foreach my $time (sort {$b <=> $a} keys %blockTime) #newest first
    { push(@outBlocks,$blocks[$blockTime{$time}]);
      last if( $#outBlocks >= 4);
    }
  }
  ##############################
  elsif ( $parm_choice =~ "^UnresolvedAssessment" )
  { &DEBUG("DamagesByParameterB: $#blocks");
    for(my $i=0;$i<=$#blocks;$i++)
    { my $block = $blocks[$i];
      if( &unresolvedDamages($block) ) 
      { push(@outBlocks,$block);
      }
    }
  }
  else
  { for(my $i=0;$i<=$#blocks;$i++)
    { my $block = $blocks[$i];
      $block =~ m/$parm_choice=([\w ]+)/;
      my $val=$1;
      #if( $1 ne "None" and $1 ne "" and $1 ne "Accessible")
      next if( $val eq "None" or $val eq "" or $val eq "Accessible");
      &DEBUG("DamagesByParameterC: $parm_choice: $val");
      push(@outBlocks,$block);
    }
  }
  return @outBlocks;
}

sub DisplayDamageLocations
{ my ($parm_in)=@_;
  # Load team info
  my ($teamName_ref,$teamLocation_ref)=&TeamInfo; #ONLY needed for all teams?
  # load labels
  &openICSorDie(L,"Lists/SelectDamageDisplay.txt");
  while(<L>)
  { chop;
    my ($var,$label,$always)=split(/:/,$_,3);
    $label{$var}=$label;
  }
  print $q->h3("$label{$parm_in} by Location"),hr();
  my @block=&DamagesByParameter($parm_in,'');
  while( my @lines=split(/\n/,shift(@block)) )
  { my %assessments;
    my %parm;
    while (my $line = shift(@lines) )
    { my ($name,$value)=split(/[=\.]/,$line,2);
      if( &MemberQ(("StreetAddress","SelectAddress","SelectStreet"),$name)>=0 
	  or 
	&MemberQ((@SelectvAddressNames,"vAddress"),$name)>=0 #VADD
      )
      { $parm{$name}=$value;
      }
      else
      { $parm{$name}.="$value, ";
      }
    }
    #######
    # ADD response team for address
    my $address=$parm{"vAddress"};
    my @team;
    $#team=-1;
    foreach my $team ( keys %$teamLocation_ref)
    { if( $teamLocation_ref->{$team} =~ /$address/ )
      { push(@team,$team);
      }
    }
    #######
    if( $parm{"vAddress"} ) 
    { print $q->submit("Address",$parm{"vAddress"}); } #VADD
    else
    { print $q->submit('Address',"$parm{'SelectStreet'}=$parm{'SelectAddress'}");
    }
    foreach my $team ( @team )  
    { print $q->submit('ResponseTeamAtLocation',$team );
    }
    print "<br>",&COLOR("green",
      strftime(" %a %b %e %H:%M:%S %Y",localtime($parm{"UXtime"})));
    #####################
    foreach $name ( sort keys %parm )
    { next if( &MemberQ(("StreetAddress","UXtime"),$name)>=0 );
      $value = $parm{$name}; $value=~s/, $//;
      next if( $value =~ m/\WNone\W/);
      next if( &MemberQ(("None","0","Accessible",""),$value)>=0 );
      my $color="blue"; if( $name eq $parm_in ) { $color="red"; }
      ##############################
      $name =~ m/([\w]*)(Assessment|Team|UrgencyDue)$/;
      my $type=$1;
      my $class=$2;
      if( $name =~ m/Notes/ )
      { $assessments{"Notes"}.= &COLOR("red",$value)." ";
      }
      elsif( $name =~ m/UrgencyDue/ )
      { $type = $name;
	$type =~ s/UrgencyDue//;
       	my $dueMinutes=int(($value-time)/60);
	if( $dueMinutes < 0 ){ $color="red"; }
	elsif( $dueMinutes < 5 ){ $color="orange"; }
	else{ $color="green"; }
	$assessments{"UrgencyDue"}.= &COLOR("blue",$type) .":".&COLOR($color,"$dueMinutes min")." ";
      }
      elsif( $class =~ m/[\w]+/ )
      { if( $type=~m/People/ )
	{ $type =~ s/People//;
	  $assessments{"People"}.= &COLOR("blue",$type) .":".&COLOR("red",$value)." ";
	}
	else
	{ $assessments{$class}.= &COLOR("blue",$type)
	  .":".&COLOR("red",$value)." ";
	}
      }
    }
    print "<br>";
    my @type=("People","Assessment","UrgencyDue","Team","Notes");
    for(my $i=0;$i<=$#type;$i++)
    { if( $assessments{$type[$i]} =~ m/[\w]+/ )
      { print "$type[$i]: ",$assessments{"$type[$i]"},"<br>";
      }
    }
    print hr;
    ########################
  }
  print hr;
  $q->param('LastAction',"$UserAction");
  $q->param('LastForm',"DisplayDamageLocations");
  &hiddenParam($q,'UserName,UserAction,LastAction,LastForm'); 
  @actions=('Back','Cancel>Home'); 
  &SubmitActionList(@actions);
  print $q->end_form;
}

sub DisplayHistory
{ my ($separator,$address)=@_; # BlockSeparator followed by 2 blocks 
  my @blocks=&LoadDamageLog("$address");
  return if($#blocks<0);
  ###########
  my @changeblocks=();
  for($ib=0;$ib<=$#blocks;$ib++)
  { 
    my @block1=();
    if( $ib > 0 ){ @block1=split(/\t/,$blocks[ $ib-1 ]); }
    my @block2=split(/\t/,$blocks[ $ib ]);
    my @changed=();
    my $user,$time;
    for(my $i=0; $i<=$#block2;$i++)
    { if( $block2[$i] =~ /^time=/ )
      { $time=$block2[$i];
	$time=~s/^time=(.*)/$1/;
      }
      if( $block2[$i] =~ /^UserName=/ )
      { $user=$block2[$i];
	$user=~s/^UserName=(.*)/$1/;
      }
      if( $block2[$i] =~ /^ReportedBy=/ )
      { $user=$block2[$i];
	$user=~s/^ReportedBy=(.*)/$1/;
      }

      # deselect @changed
      next if( $block2[$i] =~ /^time=|^UserName=|^StreetAddress=|^firstname=|^lastname=|^UXtime=|^ReportedBy=|^vAddress|^.cgi|^Select|^=/ );
      next if( $block2[$i] =~ /=None$/ and $ib eq 0);
      next if( $block2[$i] =~ /=Accessible$/ and $ib eq 0);
      if( &MemberQ(@block1,$block2[$i]) < 0 or $#block1 lt 0)
      { push @changed,">$block2[$i]";
      }
    }
    if($#changed>=0 ) 
    { 
      push @changeblocks,join("\t",&COLOR("blue","$time"),&COLOR("green","by $user"),@changed);
    }
  }
  if( $#changeblocks ge 0)
  { print hr(),,&BOLD("Change History (most recent first)"),"<br>"; 
  }
  # Coloring
  for( my $i=$#changeblocks; $i>=0; $i--)
  { my $str= $changeblocks[$i];
    $str=~s/Assessment=([^\t]*)[\t]/=<font color=red>$1<font color=black><br>/g;
    $str=~s/Assessment=(.*)/=<font color=red>$1<font color=black>/;
    $str=~s/Notes=([^\t]*)/Notes=<font color=orange>$1<font color=black>/;
    $str=~s/\t/<br>/g;
    print $str,"<br>";
  }
}

#############################
#DOC
# DamageAssessmentForm  	->Map:
# 				->ResponseTeam:
#				->Submit	->Damage
#				->ShowContacts:	->DamageAssessmentForm
#				->Send Team:	->ManageResponseTeams
#				->Cancel	->requestUserAction
sub DamageAssessmentForm
{ my $q=@_[0];
  my $needs="";
  my $contacts="";
  &initializeAllPersonnelData;
  my $street=$q->param("SelectStreet");
  my $address=$q->param("SelectAddress");
  my $subaddress=$q->param("SelectSubAddress");
  my $vAddress=$q->param("vAddress");
  $q->param("LastForm","DamageAssessmentForm");
  if ( ! $vAddress )
  { $vAddress=&vAddressFromParam($q); #VADD from SelectAddresses
    $q->param('vAddress',$vAddress);
  }
  $q=&restore_DamageAssessment($vAddress);
  print $q->h3("Damage Assessment Form");
  print $q->h6("[$vAddress]");
  print hr;
  print <<___EOR;
<input type=submit name=UserAction value="Map:AddressLocation:$vAddress">
___EOR

  if(-e "$ICSdir/../Image/Address/$vAddress/House" )  
  { print <<___EOR;
<input type=submit name=UserAction value="Image:AddressLocation:$vAddress:House">
___EOR
  }
  ## ADD photo reference
  print hr;
  #################################
  my @personnel=keys %$RoleByName_ref;
  ######################
  print &BOLD("Reported By: ");
  $q->delete('ReportedBy');
  print $q->popup_menu(-name=>"ReportedBy",-values=>[@personnel],-default=>$UserName),"<br>";
  #################################
  # ADD response team for address
  my ($teamName_ref,$teamLocation_ref)=&TeamInfo; #ONLY need for all teams?
  my @team;
  $#team=-1;
  foreach my $team ( keys %$teamLocation_ref)
  { if( $teamLocation_ref->{$team} =~ /$vAddress/ )
    { push(@team,$team);
    }
  }
  if( $#team>=0)
  { print hr;
    foreach my $team ( @team )  
    { print $q->submit('ResponseTeamAtLocation',$team );
    }
    print " deployed";
  }
  print hr;
  ##
  for(my $i=0;$i<=$#damageassessmentParm;$i++)
  { my $assessment=$damageassessmentParm[$i]; 
    my @choice=split(/,/,$damageassessmentChoices[$i]);
    my $multiple=$damageassessmentMultiple[$i];
    my $damage=$assessment;
    $damage=~s/Assessment$//;
    @value=$q->param($assessment); 
    $value=$value[0];
    if($multiple)
    { #####################
      # SCROLLING version
      print "<table class='damageform' border=1 cellspacing=0 cellpadding=5>
      <tr><td width='30%'>";
      print &BOLD("$damage:</td><td>");
      print $q->scrolling_list(-name=>"$assessment",-values=>[@choice],-default=>[@value],-multiple=>'true');
      print "</td></tr>";
      print "</table>";
      #####################
    }
    else
    { #########################
      # POPUP menu version
      my @mylabels=map { $_=>"_".$_ } @choice;
      &DEBUG(">>mylabels: @mylabels");

      print " <table class='damageform' border=1 cellspacing=0 cellpadding=5>";
      print "<tr><td width='30%'>",&BOLD("$damage: "),"</td><td>";
      print $q->radio_group(-name=>"$assessment",
	-values=>[@choice],
	-default=>$value,
	-linebread=>'true',
	-labels=>{@mylabels} 		# <br> DOESN'T work

      );
      #print $q->popup_menu(-name=>"$assessment",-values=>[@choice],-default=>$value);
      print "</td></tr>";
      print " </table>";
      #####################
    }
  }
  print &BOLD("Notes"),"<br>";
  $q->delete("Notes"); # New Notes
  my $str="";
  if($vAddress )
  { $needs=&specialNeedsAt($vAddress);
    $str=$needs;
    $contacts=&contactInfoAt($vAddress);
  }
  if(-e "$ICSdir/DamageLogs/$vAddress" ){ $str=""; }
  &DEBUG("Note:$vAddress $str");
  print $q->textarea(-name=>'Notes',-rows=>4,-columns=>54, -default=>$str);
  print hr();
  if($action eq 'ShowPropertyContacts')
  { print &BOLD("Contacts:"),"<br>";
    print $q->textarea(-name=>'Contacts',-rows=>4,-columns=>54, -default=>$contacts);
    $q->delete('action');
  }
  else
  { 
    if($contacts)
    { print $q->submit('action','ShowPropertyContacts');
    }
  }
  print hr();
}

# produces string of specialNeeds at parcel address
sub specialNeedsAt
{ my $address=$_[0]; 
  #remove subAddress
  my @vAddress= &vAddress2Array($address);
  $#vAddress=1;
  my $address=&vAddressFromArray(@vAddress);
  &TIE(DBSpecialNeeds);
  my @addresses=keys %DBSpecialNeeds;
  @addresses=&selectHead($address,@addresses);
  my $str="";
  foreach $address (@addresses)
  { my $info=$DBSpecialNeeds{$address}; 
    if($info)
    { $str.="\n<$address>";
      $str.="\n$info";
    }
  }
  if($str) { return($str); }
}

# produces string of contactInfo at parcel address
sub contactInfoAt
{ my $address=$_[0]; 
  #remove subAddress
  my @vAddress= &vAddress2Array($address);
  $#vAddress=1;
  my $address=&vAddressFromArray(@vAddress);
  &TIE(DBcontactInfo);
  my @addresses=keys %DBcontactInfo;
  @addresses=&selectHead($address,@addresses);
  #die ">>>>@addresses";
  my $str="";
  foreach $address (@addresses)
  { my $info=$DBcontactInfo{$address}; 
    if($info)
    { $str.="\n<$address>";
      $str.="\n$info";
    }
  }
  if($str) { return($str); }
}

sub PrintUrgencyForm
{ my $name = @_[0];
  my $default = $q->param("$name"."Urgency");
  my $due = $q->param("$name"."UrgencyDue");
  print "<br>",&COLOR("blue","$name:")," ";
  if($due)
  { my $dueMinutes=int(($due-time)/60);
    if( $dueMinutes < 0 )
    { print &COLOR("red","in ($dueMinutes min) "); 
    }
    elsif( $dueMinutes < 5 )
    { print &COLOR("orange","in ($dueMinutes min) "); 
    }
    else
    { print &COLOR("green","in ($dueMinutes min) "); 
    }
  }
  print $q->popup_menu("$name"."Urgency",['Change','None','<5 minutes','<30 minutes','<2 hours'],$default);
  print $q->hidden(-name=>"$name"."UrgencyDue",-default=>"$due");
}

sub PrintResponseTeamForm
{ my $name=@_[0];
  my $teamName = "$name"."Team";
  my $default=$q->param("$teamName");
  ###############
  # make list of available teams
  my @list = ("None");
  my $currentAssign=$q->param("$teamName");
  if( $currentAssign ne "None" ){ push @list,$currentAssign; }
  my @tmp=@availableTeams;
  while( my $team=shift @tmp)
  { $team =~ s/\s+//g;
    if( $team =~ /$name/ )
    { my $ABC=chop $team;
      push @list,$ABC;
    }
  }
  ###############
  print "<br>$name:";
  print $q->popup_menu(-name=>"$teamName",-values=>[@list],-default=>$default,-attributes=>\%attributes);
}

# return list of addresses and unresolve issues
sub unresolvedDamages
{ my ($block)=@_;
  my $unresolved=0; # \t separated list of addresses
  my @lines=split(/\n/,$block);
  my @issues;
  $#issues=-1;
  for(my $i=0;$i<=$#lines;$i++) 
  { $_=$lines[$i];
    next if(/=None|.cgifield|=Accessible|Urgency=|Team=|=$/ ); #ignore these
    next if(!/Assessment=/);
    if ( /Assessment=/ )
    { push @issues,$_;
    }
    if( $#issues >=0 )
    { $unresolved=join(/\t/,@issues);
      $unresolved=~s/\n//g;
    }
  }
  return $unresolved; # \t separated list of addresses
}

sub SelectDamageDisplayForm
{ my $q=@_[0];
  ## gather incident statistics
  %issues=&gatherIncidentStatistics;
  ##
  print $q->h3("Review Damages"),hr;
  print &COMMENT("Select Reports by Issue");
  print $q->start_multipart_form;
  my $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5> ";
  &openICSorDie(L,"Lists/SelectDamageDisplay.txt");
  while(<L>)
  { chop;
    my ($var,$label,$always)=split(/:/,$_,3);
    if( $issues{$var} gt 0 or $always)
    { $cmd.="<tr><td><input type=submit name='$var' value='$label'></td> </tr>";
    }
  }
  $cmd.=" </table> </fieldset>";
  print $cmd;
  $q->param('LastAction',"$UserAction");
  $q->param('LastForm',"SelectDamageDisplayForm");
  &hiddenParam($q,'UserName,UserAction,LastAction,LastForm'); 
  @actions=('Cancel>Home'); 
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>'ShowInfo:ReviewDamages', -value=>'Help', -id=>'helpButton');
  print $q->end_form;
} 

sub SelectDamageAssessment
{ my $q=@_[0];
  my @parms=$q->param;
  my @var;
  my $out;
  &openICSorDie(L,"Lists/SelectDamageDisplay.txt");
  while(<L>)
  { chop;
    my ($var,$label)=split(/:/,$_,2);
    if( &MemberQ(@parms,$var)>=0 )
    { $out=$var;
      last;
    }
  }
  return $out;
}

# based upon DamageChoices.txt categories
sub gatherIncidentStatistics 
{ my $file,$line,$data,@assessment,@choice;
  # get assessment names
  my @damagechoice=&arrayTXTfile("Lists/DamageChoices.txt");
  #die ">>@damagechoice";
  for(my $i=0;$i<=$#damagechoice;$i++)
  { my $data=$damagechoice[$i];
    my ($damage,$choices,$multiple)=split(/:/,$data);
    push(@assessment,$damage."Assessment");
  }
  #
  foreach $file (<"$ICSdir/Damages/*">)
  { if (&openICS(FILE,$file)) 
    { my $q = new CGI(FILE);  # Throw out the old q, replace it with a new one
      close FILE;
      my @parm=$q->param;
      foreach my $p (@parm)
      { my @values=$q->param("$p");
	@values=&changeNL2character(@values); # NL creates problems
	$p=~s/\: //;  # remove undocumented feature of paramname
	next if($values[0] eq 'None' or $p !~ /Assessment$/ );
	$issues{$p}++;
      }
    } 
  }
  return %issues;
}

sub LoadDamageLog
{ my $Address=@_[0];
  my $file="DamageLogs/$Address";
  my @blocks; $#blocks=-1;
  my @block; $#block=-1;
  &openICS(FILE,$file);
  while(<FILE>) # load all log data
  { chop;
    $_=&uri_unescape($_);
    push(@block,$_);
    if($_ =~ /^=/ )
    { push(@blocks,join("\t",@block));
      $#block=-1;
    }
  }
  return @blocks;
}

# return sorted list off Damage Addresses
sub DamageReportAddresses
{ my $line,$data;
  my @address=();
  foreach my $file (<"$ICSdir/Damages/*">)
  { 
    if (&openICS(FILE,$file)) 
    { my $q = new CGI(FILE);  # Throw out the old q, replace it with a new one
      close FILE;
      #my $street=$q->param("SelectStreet");
      #my $address=$q->param("SelectAddress");
      #my $subaddress=$q->param("SelectSubAddress");
      #my $vAddress=$q->param("vAddress");
      #push(@address,"$street\t$address");
      # print "DEBUG: $street $address $subaddress:<br>";
      push(@address,&vAddressFromParam($q));
    }
  }
  @address=sort(@address);
  return @address;
}

1;
