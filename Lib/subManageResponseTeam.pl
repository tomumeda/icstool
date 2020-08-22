#!/usr/bin/perl
# ManageResponseTeams program flow
#	AllTeamsTable 
#		Team		>TeamEditForm
#		Location	>DamageAssessmentForm
#		Personnel	>PersonnelEditForm
#		NewTeam		>FormTeam

#	TeamEditForm
#		Team:Remove			>AllTeamsTable
#		Team:ChangeLocation		>AllTeamsTable
#		Personnel:Add			>AllTeamsTable
#		Personnel:Remove		>AllTeamsTable
#		Location:Change			>AllTeamsTable
#		DamageAssessmentForm		>FormTeam

#	DamageAssessmentForm	>SendTeam
#	PersonnelEditForm	>AllTeamsTable
#	FormTeam		>AllTeamsTable
			

sub openResponseTeams
{ &TIE("ResponseTeams");
}

sub ManageResponseTeams
{ my ($q,$type)=@_;
  #########################
  @SelectNames=$q->param("SelectNames");
  &DEBUG("ManageResponseTeams: $type; @SelectNames; $SelectTeam");
  $UserAction="Manage Response Teams"; # set for other 
  $q->param("UserAction",$UserAction);
  &openResponseTeams;
# SERVICE ResponseTeam changes

# service FormTeam
  if( ($LastAction eq "FormTeam" and $InfoShown )
      or ($action eq "Send Team") )
  { &FormTeam($q);
    return;
  }
  if($LastAction eq "FormTeam" and $SelectTeam and (@SelectNames or $SelectNames) )
  { &AssignTeamMembers($q);
  }
  my $Team =$q->param("Team"); # from Team table
  my @parms= $q->param;
  my @location=&selectHead("Location:",@parms);
  my @personnel=&selectHead("Personnel:",@parms);
  my @team=&selectHead("Team:",@parms);
  &DEBUG("ManageResponseTeams00: $Team; @team; @location; @personnel");
  #####################################################################
  # action on individual Teams
  if($type eq "Manage Response Teams" and $team[0] =~ m/Team:(.*):Remove/ 
      and 1 eq 2
  )
  { my $team=$1;
    my @names=split(";",$NamesByRole_ref->{$team});
    &DEBUG("ManageResponseTeam @names");
    foreach $name (@names)
    { my $q=&loadCGIfile("Personnel/$name");
      $q->delete("assignment");
      &saveCGIfile($q,"Personnel/$name");
    }
    unlink "$ICSdir/ResponseTeams/$team"; # Why does this work?
    undef $Team;
    $q->delete("Team"); 
  }
  &DEBUG("ManageResponseTeams 0 : $type,$Team,@location,@personnel");
  my $lastNumber=$ResponseTeams{lastNumber}; if(!$lastNumber){$lastNumber=0;} # DB version
  $lastNumber=`cat "$ICSdir/ResponseTeams/lastNumber"`;

  my ($teamName_ref,$teamLocation_ref)=&TeamInfo; 

  #########################
  if($type eq "Manage Response Teams" and $action eq 'FormTeam')
  { &FormTeam($q);
  }
  elsif($type eq "Manage Response Teams" 
      and $#location<0 and $#personnel<0 
      and (
           $LastForm eq "TeamEditForm" 
	or !$Team 
	or ($Team and $action eq "Back" ))) # display All Team table
  { &AllTeamsTable($q); 
  }

  #########################
  elsif($type eq "Manage Response Teams" and 
    $location[0] =~ m/Location:(.*):Change/
      or ( $location[0] =~ m/Location:(.*):View/
       	and $q->param($location[0]) eq "" ))
  { my $team=$1; # LOAD team info 
    my $street = $q->param("SelectStreet" ); #VADD XX
    my $address = $q->param("SelectAddress" ); #VADD XX
    my $subaddress = $q->param("SelectSubAddress" ); #VADD XX
    my $DamageAddress = $q->param("DamageAddress" );
    my $vAddress=&vAddressFromParam($q); #VADD XX
    if($DamageAddress)
    { $vAddress=$DamageAddress;
      ($street,$address,$subaddress)=&vAddress2Array($DamageAddress);
    }
    &DEBUG("ManageResponseTeams:: $street, $address :$DamageAddress");
    if(! $street or ! $address)
    { &StreetAddressForm($q,$street,$address,
       	"SelectStreet,SelectAddress,LastAction,UserAction,UserName,$location[0]");
    }
    else
    { 
      &DEBUG("ManageResponseTeams3: $vAddress, $address :$DamageAddress");
      &addCGIfile("ResponseTeams/$team", "vAddress", "$vAddress");
      $q->delete($location[0]); # DOES NOT SEEM TO WORK
      $q->delete("LastAction"); # DOES NOT SEEM TO WORK
      &hiddenParam($q,'UserName,DamageAddress,vAddress');
      # Message personnel
      my @personnel=split(/;/,$NamesByRole_ref->{$team});
      if($#personnel>=0)
      { &addMessage("$assignment: change location to: $vAddress.",$UserName,$assignment,@personnel); 
      }
      # print &COMMENT("$team at: $address $street @personnel");
      &requestUserAction($q); # Main Menu
    }    
  }
  ################
  elsif($type eq "Manage Response Teams" and 
    $location[0] =~ m/Location:(.*):View/)
  { my $team=$1;
    #print "#### $team $location[0]";
    &RestoreTeamInfo($q,$team);
    $q->param("DamageAddress",$q->param("vAddress")); # TODO convert to all vAddress
    $action="SelectReportedAddress";
    $q->param("UserAction","ReviewDamages");
    &DamageReportForm($q); 
    $q->param("UserAction","ReviewDamages");
  }
  ################
  elsif($type eq "Manage Response Teams" and 
    $personnel[0] =~ m/Personnel:(.*):Remove/
      and 1 eq 2)
  { my $team = $1;
    my @deleteNames=$q->param($personnel[0]);
    my @teamNames=split(";",$NamesByRole_ref->{$team});
    ####
    foreach my $name (@deleteNames)
    { my $q=&loadCGIfile("Personnel/$name");
      $q->delete("assignment");
      &saveCGIfile($q,"Personnel/$name");
      @teamNames=&deleteElement($name,@teamNames);
    }
    # update $team members
    if( $#teamNames<0 )
    { #unlink "ResponseTeams/$team";
      &addMessage("$team removed.",$UserName,$assignment,$UserName);
    }
    # Message
    if($#names>=0)
    { &addMessage("@names: removed from $team.",$UserName,$assignment,@names);
    }
    &requestUserAction($q); # Main Menu
  }
  ##############
  elsif($type eq "Manage Response Teams" and 
    $personnel[0] =~ m/Personnel:(.*):Add/)
  { my $team=$1;
    &RestoreTeamInfo($q,$team);
    &AddTeamMember($q,$team);
  }
  #######################
  elsif($type eq "Manage Response Teams" and 
    $personnel[0] =~ m/Personnel:(.*):View/)
  { my $team=$1;
    my $personnel=$q->param($personnel[0]);
    my $q_person=&loadPersonnelFile($personnel);
    $PersonnelName=$personnel;
    $q_person->param("UserName",$UserName);

    &DEBUG("ManageResponseTeams4: $UserName, $PersonnelName ");
    &PersonnelInfoForm($q_person);
  }

  elsif( ($type eq "Manage Response Teams" and $Team )   ### Display individual TEAM Info
      or ($type eq "ResponseTeamAtLocation" and $Team=$q->param("ResponseTeamAtLocation") ) #CHK
  )
  { &TeamEditForm($q,$Team);
  }
  else #error -> return to previous form
  { 
    &hiddenParam($q,'UserName');
    &requestUserAction($q); # Main Menu
  }
  &hiddenParam($q,'UserName,UserAction');
  #######################
}

# update TeamData at beginning of main routine, after loading PersonnelData
# NO DIALOG
sub TeamDataUpdate 
{ my ($q)=@_;
  my @location=&selectHead("Location:",@params);
  my @personnel=&selectHead("Personnel:",@params);
  my @team=&selectHead("Team:",@params);
  &DEBUG("TeamDataUpdate:@team;@personnel;@location;");

  if($team[0] =~ m/Team:(.*):Remove/) #only one Team
  { my $team=$1;
    my @names=split(";",$NamesByRole_ref->{$team});
    &DEBUG("TeamDataUpdate1:$team: @names");
    foreach $name (@names)
    { my $q=&loadCGIfile("Personnel/$name");
      $q->delete("assignment");
      &saveCGIfile($q,"Personnel/$name");
    }
    unlink "$ICSdir/ResponseTeams/$team"; 
    $q->delete($team[0]);
    @params=&deleteElement($team[0],@params);
    undef $Team;
    @params=&deleteElement('Team',@params);
    $q->delete("Team");
    &DEBUG("TeamDataUpdate2:@params");
  }

  elsif( $personnel[0] =~ m/Personnel:(.*):Remove/)
  { my $team = $1;
    my $pname="Personnel:$team:Remove";
    my @deleteNames=$q->param($personnel[0]); 	#?? what is wrong with @{$pname}?
    &DEBUG("TeamDataUpdate p:$pname; @deleteNames ");
    if($#deleteNames<0)
    { print &COMMENT("[No name selected]");
      $reDo="TeamEditForm";
    }
    else
    { my @teamNames=split(";",$NamesByRole_ref->{$team});
      foreach my $name (@deleteNames)
      { my $q=&loadCGIfile("Personnel/$name");
	$q->delete("assignment");
	&saveCGIfile($q,"Personnel/$name");
	@teamNames=&deleteElement($name,@teamNames);
      }
      # update $team members
      if( $#teamNames<0 )
      { unlink "ResponseTeams/$team";
	&addMessage("$team removed.",$UserName,$assignment,$UserName);
      }
      &addMessage("@deleteNames: removed from $team.",$UserName,$assignment,@deleteNames);
      $q->delete($personnel[0]);
      &initializeAllPersonnelData; # reinitialize
    }
    for(my $i=0;$i<=$#personnel;$i++)
    { @params=&deleteElement($personnel[$i],@params);
      $q->delete($personnel[$i]);
    }
    &DEBUG("TeamDataUpdate3:@params");
  }
  # NEW
  elsif( $location[0] =~ m/Location:(.*):Change/)
  { my $team=$1; # LOAD team info 
    my $street = $q->param("SelectStreet" ); #VADD XX
    my $address = $q->param("SelectAddress" ); #VADD XX
    my $subaddress = $q->param("SelectSubAddress" ); #VADD XX
    my $DamageAddress = $q->param("DamageAddress" );
    my $vAddress=&vAddressFromParam($q); #VADD XX
    if($DamageAddress)
    { $vAddress=$DamageAddress;
      ($street,$address,$subaddress)=&vAddress2Array($DamageAddress);
    }
    if($street and $address)
    { &DEBUG("TeamDataUpdate4: $street, $address :$DamageAddress");
      &addCGIfile("ResponseTeams/$team", "vAddress", "$vAddress");
      $q->delete($location[0]); # DOES NOT SEEM TO WORK
      # Message personnel
      my @personnel=split(/;/,$NamesByRole_ref->{$team});
      if($#personnel>=0)
      { &addMessage("$team: change location to: $vAddress.",$UserName,$assignment,@personnel); 
      }
    }    
  }
}

sub TeamEditForm
{ my ($q,$Team)=@_;
# only personnel with FormTeam attribute can use this form
  &RestoreTeamInfo($q,$Team);
  print $q->h3("Edit: $Team"),hr;
  print &COMMENT("Select option to edit");
  $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5> ";
  { my $loc=$teamLocation_ref->{$Team};
    if($loc =~ /\w/ )
    { $cmd.="<tr><td><font size=6 color=blue>View Current Location:</font></td>";
      $cmd.="<td> <input type=submit name='Location:$Team:View' value='$loc'> </td> </tr>";
      if($canFormTeam)
      {
	$cmd.="<tr><td> </td>";
	$cmd.="<td>";
	$cmd.="<input type=submit name='Location:$Team:Change' value='Change Location'> ";
	$cmd.="</td> </tr>";
      }
    }
    else
    { $cmd.="<tr><td><font size=6 color=blue>Location:</font></td>";
      $cmd.="<td>";
      if($canFormTeam)
      { $cmd.="<input type=submit name='Location:$Team:Change' value='Change Location'>";
	$cmd.="</td> </tr>";
      }
    }
    ### Team Personnel
    my @people=split(/;/,$teamName_ref->{$Team});
    $cmd.="<tr><td><font size=6 color=blue>Personnel:</font></td><td>";
    my @cmd;
    foreach my $people (@people)
    { push(@cmd,
	("<label><input type=checkbox name='Personnel:$Team:Remove' value='$people'>"
	  ."<font size=6>$people</font></label>"));
    }
    $cmd.=join("<br>",@cmd);
    if($#people>=0 and $canFormTeam)
    { $cmd.="<br><input type=submit name='Personnel:$Team:Go' value='Remove'>";
      $cmd.="</td> </tr>";
    }
    if($canFormTeam)
    { $cmd.="<tr><td></td><td>
      <input type=submit name='Personnel:$Team:Add' value='Add People'> </td></tr>";
      $cmd.="<tr><td>
      <input type=submit name='Team:$Team:Remove' value='Remove Team'> </td></tr>";
    }
  }
  $cmd.=" </table> </fieldset>";
  print $cmd;
  $q->param("LastAction","$UserAction");
  $q->param("LastForm","TeamEditForm");
  &hiddenParam($q,'UserAction,LastAction,UserName,Team,LastForm');
  @actions=('Back','Cancel>Home'); 
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>'ShowInfo:ResponseTeamEdit', -value=>'Help', -id=>'helpButton');
  print $q->end_form;
}

sub AllTeamsTable
{ my $q=$_[0];
  my @teams=sort keys %$teamLocation_ref; 
  my $nteams=$#teams+1;
  print $q->start_multipart_form;
  print $q->h3("Number of Response Teams:$nteams"),hr;
  print &COMMENT("Select Team, Location, or Personnel to edit");
  $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5> ";
  $cmd.="<tr><td>".&COLOR("blue","Team")
  .  "</td><td>".&COLOR("blue","Location")
  .  "</td><td>".&COLOR("blue","Personnel")
  .  "</td></tr>";
  foreach my $team ( @teams )
  { $cmd.="<tr><td> <input type=submit name='Team' value='$team' > </td>";
    # Location
    my $loc=$teamLocation_ref->{$team};
    $cmd.="<td>";
    if( $loc =~ /\w/ )
    { $cmd.="<input type=submit name='Location:$team:View' value='$loc'>";
    }
    $cmd.=" </td>";
    # People
    $cmd.="<td>";
    my @people=split(/;/,$teamName_ref->{$team});
    foreach my $people (@people)
    { $cmd.="<input type=submit name='Personnel:$team:View' value='$people'>";
    }
    $cmd.="</td>";
  }
  $cmd.=" </table> </fieldset>";
  print $cmd;
  $q->param("LastAction","Manage Response Teams");
  &hiddenParam($q,'UserAction,LastAction,UserName');
  @actions=('FormTeam','Cancel>Home');
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>'ShowInfo:ResponseTeamTable', -value=>'Help', -id=>'helpButton');
  print $q->end_form;
}

sub TeamInfo
{ my $delim=";";
  undef $teamName_ref;
  undef $teamLocation_ref;
  my @currentTeams=<$ICSdir/ResponseTeams/Response*>; 
  #my @currentTeams=keys %ResponseTeams;
  &DEBUG("TeamInfo: @currentTeams");
  foreach my $file (@currentTeams)
  { my @file=split(/\//,$file);
    $team=pop @file;
    my @name=split($delim,$NamesByRole_ref->{$team});
    &DEBUG("TeamInfo: $team; @name");
    if($#name>=0)
    { foreach my $name (@name)
      { $teamName_ref->{$team}.="$name$delim";
      }
    }
    open(FILE,$file);
    my $q = new CGI(FILE);
    my $vAddress=$q->param("vAddress");
    $teamLocation_ref->{$team}=$vAddress;
  }
  return ($teamName_ref,$teamLocation_ref);
}

sub RestoreTeamInfo
{ my ($q,$team)=@_;
  my $file="ResponseTeams/$team"; 
  my $qfile=&loadCGIfile($file);
  my @list=$qfile->param ;
  foreach my $parm (@list)
  { next if($parm eq "UserName"); 
    $q->param($parm,$qfile->param($parm)); 
  }
}

###
sub FormTeam
{ my ($q) = @_;
  if( $canFormTeam != 1 )
  { print $q->h3("!! Your role is restricted from staffing teams !!"),hr();
    &requestUserAction($q);
    return();
  } 
  my ($files,$f,$d,@list,@names,$names,$name,@tmp);
  my $file="$ICSdir/ResponseTeams/lastNumber";
  open L,$file;
  my $lastNumber=<L>;
  ++$lastNumber;
  open L,">$file";
  print L $lastNumber,"\n";
  close L;
  my $responseteam="Response Team $lastNumber";
  &AddTeamMember($q,$responseteam);
}

sub AddTeamMember
{ my ($q,$responseteam) = @_;
  my $delim=";";
  my ($files,$f,$d,@list,@names,$names,$name,@tmp);
  # can do check 
  if( $canFormTeam != 1 )
  { print $q->h3("!!Your role is restricted from staffing teams!!"),hr();
    &requestUserAction($q);
    return();
  }
  else
  {
    print $q->h3("Compose $responseteam"),hr();
    if($q->param("action") eq "Send Team" )
    { my $vAddress=&vAddressFromParam($q);
      $q->param("vAddress",$vAddress);
      print &BOLD(&COMMENT("for: ")),&BOLD( $vAddress ),hr();
    }
    $q->param( 'SelectTeam', $responseteam ) ;
    print &COMMENT("Select Personnel from").&COLOR("orange"," Skill Groups");
    $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5> ";
    $cmd.="<tr><td>".&COLOR("blue","Name")
    .  " </td> <td>".&COLOR("blue","Current Assignment")." </td> </tr>";
    $cmd.=" </table> </fieldset>";
    print $cmd;
    foreach my $skill (sort keys %$skills_ref) 
    { my %labels;
      $names=$skills_ref->{$skill};
      @names=split ";",$names;
      $cmd="<fieldset>
      <legend><strong>".&COLOR("orange",$skill)."</strong></legend>
      <table border=1 width=940 cellspacing=0 cellpadding=5> ";
      for(my $i=0;$i<=$#names;$i++)
      { my $name=$names[$i];
	my $in=$RoleByName_ref->{$name};
	#&DEBUG("AddTeamMember:in: $in @assignmentOptions ");
	#next if( &FindFirstHead($in,@assignmentOptions)<0); #Why was this here?
	$cmd.="<tr><td> <label>
	<input type=checkbox name='SelectNames' value=$name > $name
	</label> </td> <td> $in </td> </tr>";
      }
      $cmd.=" </table> </fieldset>";
      print $cmd;
    }
  }
  $q->param("LastAction","FormTeam");
  &hiddenParam($q,'UserName,UserAction,LastAction,SelectTeam,SelectStreet,SelectAddress,SelectSubAddress,vAddress');
  @actions=('Submit','Cancel>Home'); 
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>'ShowInfo:ResponseTeamAssignment', -value=>'Help', -id=>'helpButton');
  print $q->end_form;
}

sub AssignTeamMembers
{ my $q=$_[0];
  my $mess;
  my $ResponseTeamParms="time,SelectStreet,SelectAddress,SelectSubAddress,vAddress,\@SelectNames";
  #my @names=&uniq(@SelectNames);
  my $assignment=$SelectTeam;
  $q->param("assignment",$assignment);
  $q->param('time',$timestr);
  &DEBUG("AssignTeamMembers: @SelectNames: $assignment ");
  # update Personnel/files
  foreach my $name (@SelectNames)
  { my $file="Personnel/$name";
    &addParmsCGIfile($q,$file,'assignment');
    &addMessage("$name: assigned to $assignment.", $UserName, $name, $name);
  }
  if( $#SelectNames>=0 )
  { &addMessage("(@SelectNames) assigned to $assignment.",$UserName,$UserName,$UserName);
  }
  my $file="ResponseTeams/$assignment";
  &addParmsCGIfile($q,$file,$ResponseTeamParms);

  #$ResponseTeams{lastNumber}=$assignment; # DB
  #&addParmsDBhash("ResponseTeams",$assignment,"SelectStreet,SelectAddress,SelectSubAddress,vAddress,\@SelectNames,assignment,time,teamstatus");
  #&UNTIE("ResponseTeams"); &TIE("ResponseTeams");

  # Team log update
  $file="ResponseTeamLogs/$assignment";
  &logParmsCGIfile($q,$file,$ResponseTeamParms);
  #&logParmsDB("ResponseTeamLogs",$assignment,'time,SelectStreet,SelectAddress,SelectSubAddress,SelectNames,vAddress,\@SelectNames');
  ############################
  &initializeAllPersonnelData; # reinitialize
}

1;
