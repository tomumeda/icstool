#!/usr/bin/perl
#################################
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;

sub initializePersonnelRoleSkill
{ my @tmp;
  if( $initializePersonnelRoleSkill ne 1)
  {
    @skillsDesc=&arrayTXTfile("Lists/Skills.txt");
    @skillsICS= map {  @tmp=split(/\t/,$_); $tmp[0]  } @skillsDesc;
    @roleList=&arrayTXTfile("Lists/Roles.txt");
    @roles= map {  @tmp=split(/\t/,$_); $tmp[0]  } @roleList;
  }
  &DEBUG("initializePersonnelRoleSkill: @skillsICS");
  $initializePersonnelRoleSkill = 1;
}

# initializes  $skills_ref,$NamesByRole_ref,$RoleByName_ref from Personnel/*
sub initializeAllPersonnelData
{ my @tmp;
  &initializePersonnelRoleSkill;
  ($skills_ref,$NamesByRole_ref,$RoleByName_ref)=&PersonnelInfo;
}

# returns CGI param INFO from Personnel/$nameLastFirst
sub loadPersonnelFile 
{ my ($name) = @_; 
  my ($lastname,$firstname)=split(/[\.\s]/,$name);
  my $filename="Personnel/$name";
  my $q=0;
  if(-e "$ICSdir/$filename" && &openICS(FILE,$filename))
  { $q = new CGI(FILE); # read info from FILE
    close FILE;
    return $q;
  }
  return $q;
}

# returns matching names in Personnel/* from $search
sub SelectPersonnelNames
{ my $search=@_[0];
  my @search=split(/[\s,;]/,$search);
  my %foundnames=(); #delete $foundnames{keys %foundnames};

  my @name=();
  @name=&PersonnelNames;
  for(my $i=0;$i<=$#name;$i++)
  { my $tname=$name[$i];
    if( &AllMatchQ( $tname,@search ) )
    { $foundnames{$tname}=$DBrecName{$tname}; #in case name from DB
    }
  }
  return %foundnames;
}

# Lists file names in Personnel directory. lastname.firstname formst
sub PersonnelNames 
{ my $f,$d,@list;
  $#list=-1;
  #&DEBUG(">>PersonnelNames: $ICSdir ");
  foreach $f (<"$ICSdir/Personnel/*">)
  { my @path=split("/",$f);
    $f=pop(@path);
    push @list,$f;
  }
  return @list;
}

# 
sub update_PersonnelFile
{ my ($q,$name)=@_;
  my $qp=&load_PersonnelFile($name);
  my @list=$q->param ;
  &DEBUG("update_PersonnelFile: $name");
  #print "##::$list ::",$qp->param("skills");
  foreach my $parm (@list)
  { next if($parm =~ /UserName/);
    $qp->param($parm,$q->param($parm));
  }
  return $qp;
}

# 
sub load_PersonnelFile
{ my $name=@_[0];
  my ($lastname,$firstname) = split(/\./,$name,2);
  my $file="Personnel/$name";
  &openICS(FILE,$file);
  my $qp=new CGI(FILE);
  close(FILE);
  $qp->param("firstname",$firstname);
  $qp->param("lastname",$lastname);
  return $qp;
}

# Note: SetMemberParameters from DB
sub SetMemberParameters
{ my ($q,$name) = @_;
  my ($lastname,$firstname) = split(/\./,$name,2);
  # Load from DB
  &TIE( @DBname );
  my $recno = $DBrecName{"$lastname\t$firstname"};
  my $rec=$DBmaster{ $recno }; 
  my @col=split(/\t/, $rec);
  my $Cell=$col[$DBcol{Cell}];
  my $Phone=$col[$DBcol{Phone}];
  my $Email=$col[$DBcol{Email}];
  my $memberskills=$col[$DBcol{SkillsForEmergency}];
  my @memberskills;
  $#memberskills=-1;
  foreach my $skill (@skillsICS)
  { my @search=split(/[^a-z]/,lc($skill));
    if( &AllMatchQ( $memberskills, @search ) == 1)
    { push(@memberskills,$skill);
    }
  }
  my $ContactInformation="Cell:$Cell; Phone:$Phone; Email:$Email";
  $q->param("ContactInformation",$ContactInformation);
  $q->param("skills",@memberskills);
  $q->param("firstname",$firstname);
  $q->param("lastname",$lastname);
  $q->param("assignment","Initial Surveyor");
  &UNTIE( @DBname );
  return $q;
}

# test if UserName needs chnaging and does FindByName dialog 
sub ChangeUserName 
{ my $q=@_[0];
  my $partialNameOK="string: 'tom'";
  my $LastFindByName=$q->param("LastFindByName");
  if($LastFindByName ne $FindByName)
  { $q->delete("UserName");
  }
  if( !$FindByName) # ?
  { $q->delete("FindByName"); # ?
    undef $FindByName; # ?
  } # ?
  #
  #######################
  if( $UserName eq "New Name" ) # ?
  { $q->delete("UserName"); # ?
    undef $UserName; undef @UserName; # ?
  } # ?
  ###
  print $q->start_multipart_form;
  if( $UserName ne $LoginName ) # UserName changed in form 
  { if( ! $FindByName ) # set FindByName
    { $q->param("FindByName","$LoginName"); 
      $FindByName=$LoginName;
    }
    $q->delete("UserName");
  }
  #die ">>FindByName $FindByName :",$q->param("FindByName");
  if( $FindByName ) #FindByName AND not first call
  { 
    &printFindByNameTable($q,"UserName");
    $q->delete("UserName"); undef $UserName;
  }
  elsif( ! $UserName and (! $FindByName and ! $LastFirstName )  )  # initial Sign In
  { print &COMMENT("Registered users, enter your name to log in.");
    print $q->textfield(-name=>'FindByName',-size=>20, -placeholder=>'partial name OK') ;
    print $q->submit('action','Login');
    print &COMMENT("<br>If you have not yet registered, click here to register:<br>"),$q->submit('action','New Name');
  }
  #########################
  print hr();
  print $q->submit(-name=>'ShowInfo:SignIn', -value=>'Help', -id=>'Button');
  $q->param("LastAction","ChangeUserName");
  &hiddenParam($q,'UserAction,LastUserName,LastAction,UserName,LastFindByName');
  print $q->end_form;
}

sub subUserAction
{ my ($q)=@_;
#  &initializeAllPersonnelData;
  sub datarec
  { my ($val,$label)=@_;
    my $valstr="value='$val' label='$label' ";
    my $str ="<tr>".
      "<td> <input type=submit name='UserAction' $valstr  ></td>".
      "<td> <input type=submit name='ShowInfo:$val' value='help' id='Button'></td>".
      "</tr> ";
  } 
  &headerMessages($UserName);
  print $q->h4("What do you want to do?");
  my $cmd="<fieldset><table border=1 width=940 cellspacing=0 cellpadding=5> ";
  $cmd.="<tr>";
  #&initializeAllPersonnelData;
  $cmd.=&datarec("ReportDamage");
  $cmd.=&datarec("ReviewDamages");
  $cmd.=&datarec("Manage ICC Staffing");
  { $cmd.=&datarec("Manage Response Teams");
  }
  $cmd.=&datarec("Sign In Others");
  $cmd.=&datarec("Review My Messages");
  $cmd.=&datarec("Set Up Command Center");
  $cmd.=&datarec("View Maps");
  $cmd.=&datarec("Edit My Info");
  $cmd.=&datarec("How To Reviews");
  if( $RoleByName_ref->{$UserName} eq "WEB Tool Specialist")
  { $cmd.=&datarec("Reset ICSTool");
  }
  $cmd.="</table></fieldset>";
  print $cmd;
}

sub requestUserAction
{ my ($q)=@_;
  my $value,@results,$i,@actions,$rec,@uniqname;
  #$UserName=$q->param('UserName');
  $q->param("LastUserName",$UserName);
  my $LastUserName=$q->param("LastUserName");
  #
  print $q->start_multipart_form;
  print $q->h3("User Action"),hr();
  #
  print &BOLD("UserName: ");  # UserName may change
  $LoginName=$UserName;
  print $q->textfield(-name=>'LoginName',-value=>$LoginName,-size=>20);
  print $q->submit('action','ChangeUser');
  my $assignment=$RoleByName_ref->{$UserName};
  if($assignment)
  { print &COMMENT("<br>Assignment: "),
    $q->submit(-name=>"ShowInfo:$assignment",-value=>"$assignment",-id=>"helpButton");
  }
  ###################
  &subUserAction($q);
  print hr(),$q->submit(-name=>'ShowInfo:UserAction', -value=>'UserAction Help', -id=>'helpButton');
  print hr(),$q->submit(-name=>'ShowInfo:ICSTool', -value=>'ICSTool Info', -id=>'helpButton');
  print $q->end_form;
  $q->delete("FindByName");
  $q->param("LastAction","UserAction"); 
  $q->param("UserName","$UserName"); 
  &hiddenParam($q,'UserName,LastAction,LastUserName');
}

# updates UserInfo from Personnel/FILE 
sub file_UserInfo 
{ my $q=$_[0];
  my $parms="UserName,firstname,lastname,skills,assignment,ContactInformation";
  my $updated=0;
  my $UserName=$q->param("UserName");
  &DEBUG("file_UserInfo",$UserName);

  my $filename="Personnel/$UserName";
  if( -f "$ICSdir/$filename" ) #only if there is a restore file
  { if( &openICS(FILE,$filename) )
    { my $qx = new CGI(FILE); # read info from FILE
      close FILE;
      if( $qx )
      { my @parm=split(/,/,$parms);
	foreach $p (@parm)
	{ if( $qx->param($p) )
	  { $q->param($p,$qx->param($p));
	  }
	}
	$updated=1;
      }
    } 
  }
  return $updated;
}

# find members and Personnel by name
sub findPeopleByName 
{ my $name=@_[0]; 
  &TIE( @DBname );
  my %MemberNameRec=&FindDBName($name);
  my @membernames= keys %MemberNameRec ;
  #name format: lastname.firstname
  for(my $i=0;$i<=$#membernames;$i++) { $membernames[$i]=~s/[\t]/./; }
  my %PersonnelNames=&SelectPersonnelNames($name);
  my @personnelnames=keys %PersonnelNames;
  push( @personnelnames , @membernames ) ;
  @uniqname = &uniq(@personnelnames) ;
  return @uniqname ;
}

sub changeNL2character
{ my @a=@_;
  for(my $i=0; $i<=$#a; $i++)
  { $a[$i]=~s/\n/; /g;
  }
  return @a;
}

# returns 3 HASH reference: $skills_ref $NamesByRole_ref $RoleByName_ref
sub PersonnelInfo
{ my $delim=";";
  undef $skills_ref; 
  undef $NamesByRole_ref;
  my @names=();
  my @assignmentsUsed;
  foreach my $file (<"$ICSdir/Personnel/*">)
  { my @file=split(/\//,$file);
    $name=pop @file; #######
    push @names,$name;
    &openICS(FILE,$file);
    my $q = new CGI(FILE);
    my @skill=$q->param("skills");
    if($#skill>=0)
    { foreach my $skill (@skill)
      { $skills_ref->{$skill}.="$name$delim";
      }
    }
    else
    { $skills_ref->{"Unspecified"}.="$name$delim"; #TEST
    }
    my $assignment=$q->param("assignment");
    if(!$assignment) {$assignment="Initial Surveyor";}
    $NamesByRole_ref->{$assignment}.="$name$delim";
    $RoleByName_ref->{$name}="$assignment";
    push( @assignmentsUsed,$assignment);
  }
  # delete ResponseTeams with no members
  my @teamNames=<"$ICSdir/ResponseTeams/Response*">;
  for(my $i=0; $i<=$#teamNames; $i++)
  { my @path= split("/",$teamNames[$i]);
    my $team=pop(@path);
    if( &MemberQ(@assignmentsUsed,$team)<0 )
    { unlink $teamNames[$i];
    }
  }
  &DEBUG("PersonnelInfo: ",
    values %{$skills_ref}, keys %{$NamesByRole_ref}
  );
  return ($skills_ref,$NamesByRole_ref,$RoleByName_ref);
}
#############
sub example
{ ($skills_ref,$NamesByRole_ref,$RoleByName_ref) = &PersonnelInfo;
  print "== skills\n";
  map { print "$_ --> $skills_ref->{$_}\n"; } keys %$skills_ref ;
  print "== NamesByRole\n";
  map { print "$_ --> $NamesByRole_ref->{$_}\n"; } keys %$NamesByRole_ref ;
  print "== RoleByName\n";
  map { print "$_ --> $RoleByName_ref->{$_}\n"; } keys %$RoleByName_ref ;
}
#############

sub PersonnelStatus
{ my ($q,$level)=@_;
  #########################
  #&initializeAllPersonnel;
  print $q->start_multipart_form;
  sub xPrint
  { my $role=$_[0];
    my ($role,$level,$d)=split(/\t/,$_[0]);
    $level=~s/LEVEL.//;
    my $ndots=">" x ($level-1);
    my $cmd="<table class='staffing' border=1 cellspacing=0 cellpadding=5> ";
    #print "$role";##DEBUG
    if( $NamesByRole_ref->{$role} )
    { my $out= " $NamesByRole_ref->{$role}"; 
      $out=~s/;/, /g;
      $cmd.="<tr><td width='50%'> 
      <label for 'role'>$ndots</label>
      <input type=submit name='AssignRole' value='$role' >
      </td> <td width='50%'> $out </td> </tr>";
    }
    else
    { $cmd.="<tr> <td width='50%'> 
      <label for 'role'>$ndots</label>
      <input type=submit name='AssignRole' id='role' value='$role' >
      </td> </tr>";
    }
    $cmd.="</table> </fieldset>";
    print $cmd;
  }
  ###################
  my @tmp;
  if($level eq "Manage ICC Staffing")
  { 
    print $q->h3("Manage ICC Staffing Form"),hr();
    print &COMMENT("Select Role to Edit");
    $cmd="<fieldset> <table class='staffing' border=2 width=940 cellspacing=0 cellpadding=5> ";
    $cmd.="<tr><td width='50%'>".&COLOR("blue","Role")
    .  " </td> <td width='50%'>".&COLOR("blue","Current Personnel")." </td> </tr>";
    $cmd.=" </table> </fieldset>";
    print $cmd;
    my @rolesICC0 = &deleteNullItems
    ( map { @tmp=split(/\t/,$_); ($tmp[2]=~/ICC/i)?"$tmp[0]\t$tmp[1]":"" ; } @roleList );
    # Filter by assignment and which are free
    foreach my $role (@rolesICC0)
    { &xPrint($role);
    }
    $q->param("LastAction","PersonnelStatus");
  }
  &SubmitActionList('Cancel>Home');
  #??print $q->submit('action','Cancel>Home');
  &hiddenParam($q,'UserAction,UserName');
  print hr(),$q->submit(-name=>"ShowInfo:ICCStaffing", -value=>"Help", -id=>'helpButton');
  print $q->end_form;
}

sub AssignRole
{ my ($q) = @_;
  my $delim=";";
  my ($files,$f,$d,@list,@names,$names,$name);
  # @teams used???
  my @teams = map { @tmp=split(/\t/,$_); ($tmp[2] !~ /ResponseTeam/) ? $tmp[0]:""; } @roleList;
  @teams=&deleteNullItems(@teams);
  ##
  my $assignrole=$q->param("AssignRole");

  @assignmentOptions=&AssignmentOptions($UserName);
  &DEBUG("AssignRole: $assignrole:$UserName: @assignmentOptions");
  if( &MemberQ(@assignmentOptions,$assignrole)<0)
  { print $q->h3("!!Your role is restricted from staffing this position!!"),hr();
    @actions=('Cancel>Home'); 
    &SubmitActionList(@actions);
    print hr(),$q->submit(-name=>'ShowInfo:ICCStaffingAssignmentRestricted', -value=>'Help', -id=>'helpButton');
  }
  else
  { my @MultiPerson = map { @tmp=split(/\t/,$_); ($tmp[2] =~ /MultiPerson/) ? $tmp[0]:""; } @roleList;
    @MultiPerson=&deleteNullItems(@MultiPerson);
    my $isMultiPerson;
    if( &MemberQ(@MultiPerson,$assignrole)>=0)
    { $isMultiPerson=1;
    }

    print $q->h3("Manage ICC Staffing--Assignment"),hr();
    print &COMMENT("Select from ").&COLOR("orange","skill group").&COMMENT(" for: ");
    print $q->submit(-name=>"ShowInfo:$assignrole", -value=>"$assignrole", -id=>'helpButton');

    $cmd="<fieldset> <table border=2 width=940 cellspacing=0 cellpadding=5> ";
    $cmd.="<tr><td width='50%'>".&COLOR("blue","Name")
    .  " </td> <td width='50%'>".&COLOR("blue","Current Assignment")." </td> </tr>";
    $cmd.=" </table> </fieldset>";
    print $cmd;
    foreach my $skill (sort keys %$skills_ref) 
    { my %labels;
      $names=$skills_ref->{$skill};
      @names=split ";",$names;
      $cmd="<fieldset>
      <legend><strong>".&COLOR("orange","$skill")."</strong></legend>
      <table border=1 width=940 cellspacing=0 cellpadding=5> ";
      for(my $i=0;$i<=$#names;$i++)
      { my $name=$names[$i];
	my $in=$RoleByName_ref->{$name};
	# filter by Role
	next if( &MemberQ(@assignmentOptions,$in)<0);
	#TODO account for multiple person option with pre selected names (chckebox)
	if( $isMultiPerson )
	{ $cmd.="<tr><td width='50%'> <label>
	  <input type=checkbox name='SelectNames' value=$name > $name
	  </label> </td> <td width='50%'> $in </td> </tr>";
	}
	else
	{ $cmd.="<tr><td width='50%'> <label>
	  <input type=radio name='SelectNames' value=$name > $name
	  </label> </td> <td width='50%'> $in </td> </tr>";
	}
      }
      $cmd.=" </table></fieldset>";
      print $cmd;

    }
    @actions=('Submit','Cancel>Home'); 
    &SubmitActionList(@actions);
    print hr(),$q->submit(-name=>'ShowInfo:ICCStaffingAssignment', -value=>'Help', -id=>'helpButton' -class=>'helpButton');
  }
  #$q->param("LastAction","AssignRole");
  &hiddenParam($q,'UserName,UserAction,AssignRole');
  print $q->end_form;
}

sub RoleAssignment
{ my $q=$_[0];
  my $assignment=$q->param("AssignRole");
  &DEBUG("RoleAssignment: $assignment");
  my $mess;
  # TODO unassign people from solo roles, do not if multiperson
  { my @unassign=split(/;/,$NamesByRole_ref->{$assignment});
    foreach my $name (@unassign)
    { my $file="Personnel/$name";
      &openICS(FILE,$file);
      my $q = CGI->new(FILE);
      $q->delete("assignment");
      &openICSorDie(FILE,'>',$file);
      $q->save(FILE);
      # Build Message
      &addMessage("$name: unassigned from $assignment.",$UserName,$name,$name);
    }
    if( $#unassign >=0 )
    { &addMessage("(@unassign) unassigned from $assignment.",$UserName,$UserName,$UserName);
    }
  }
  #add new assignment
  my @names=&uniq($q->param("SelectNames"));
  &DEBUG("RoleAssignment: @names");
  foreach my $name (@names)
  { my $file="Personnel/$name";
    &openICS(FILE,$file);
    my $q = CGI->new(FILE);
    # Unassign others from this role if not MultiPerson
    $q->param("assignment",$assignment);
    &openICSorDie(FILE,'>',$file);
    $q->save(FILE);
    # Build Message
    &addMessage("$name: assigned to $assignment.",$UserName,$name,$name);
  }
  close FILE;
  if($#names>=0)
  { &addMessage("(@names) assigned to $assignment.",$UserName,$UserName,$UserName);
  }
  undef $SelectNames;
  undef $UserAction;
  $q->delete("SelectNames");
}

sub SelectStreetName
{ my @damageAddress=&DamageReportAddresses;	
  my @street;
  foreach my $address (@damageAddress)
  { my ($s,$a)=&vAddress2Array($address);
    push(@street,$s);
  }
  tie(%MapStreetAddresses,"DB_File","$ICSdir/DB/MapStreetAddresses.db",O_RDWR,0666,$DB_BTREE);
  push( @street,keys %MapStreetAddresses);
  &DEBUG("SelectStreetName: @street, ");
  my $cmd="<select name=SelectStreet>\n";
  $cmd.="<option value=''>Street Names</option>\n";
  @street=&uniq( @street );
  for( my $i=0; $i<=$#street; $i++)
  { $cmd.="<option value='$street[$i]'>$street[$i]</option>\n";
  }
  $cmd.="</select>\n";
  #$cmd.="<input type=submit name='action' value='SelectStreet' >\n";
  $cmd
}

sub SelectStreetAddress
{ my $street = @_[0];
  my @addresses=&uniq( &StreetAddresses($street) );
  tie(%MapStreetAddresses,"DB_File","$ICSdir/DB/MapStreetAddresses.db",O_RDWR,0666,$DB_BTREE);
  push @addresses,split(/\t/,$MapStreetAddresses{$street});
  @addresses=&uniq( @addresses );
  if($#addresses<0) { return; }
  my $cmd="<select name=SelectAddress>\n";
  $cmd.="<option value=''>Known Addresses</option>\n";
  my @adds;
  foreach my $add (@addresses)
  { push(@adds,$add);
  }
  @adds=&uniq( @adds );
  #
  for( my $i=0; $i<=$#adds; $i++)
  { $cmd.="<option value='$adds[$i]'>$adds[$i]</option>\n";
  }
  $cmd.="</select>\n";
  $cmd.=$q->textfield(-name=>"SelectSubAddress",-value=>"",-size=>10,-maxsize=>20,-placeholder=>"SubAddress");
  $cmd
}

sub StreetAddressForm
{ my ($q,$street,$address,$retain)=@_;
  #print $q->h3("Select Location"),hr();
  #print &SelectDamageAddress;
  if(! $street )
  { print $q->h3("Select Location"),hr();
    print &SelectDamageAddress;
    print hr(),$q->h4("or by Street Name");
    print &SelectStreetName,"<br>"; ##################
    #######################
    print &COMMENT("or by: "),$q->textfield(-name=>"NewStreetName",-size=>25,-maxsize=>50,-placeholder=>"New Street Name");
  }
  elsif(! $address)
  { #print $q->h3("Select Address on $strret"),hr();
    print $q->h3("Address of Location on: $street"),hr();
    #print hr(),&COMMENT(&BOLD("Select an address on:")),&BOLD(" $street<br>");
    print &BOLD(" $street<br>");
    print &SelectStreetAddress($street),"<br>";
    print &COMMENT("or add: "),
    $q->textfield(-name=>"NewAddress",-value=>"",-size=>10,-maxsize=>20,-placeholder=>"New Address"),
    $q->textfield(-name=>"SelectSubAddress",-value=>"",-size=>10,-maxsize=>20,-placeholder=>"SubAddress");
  }
  &hiddenParam($q,$retain);
  print "<br>";
  print $q->submit('action','Go');
  print hr(),$q->submit('action','Cancel>Home');
  print hr(),$q->submit(-name=>'ShowInfo:AddressSpecificationForm', -value=>'Help', -id=>'helpButton');
  print $q->end_form;
}

# prints Skill and assignment table
sub printSkillsTable
{ my ($name)=@_;
  my $assign;
  my @myskills;
  if(my $qq=&loadPersonnelFile($name))
  { @myskills=$qq->param('skills');
    $assign=$qq->param('assignment');
    $ContactInformation=$qq->param('ContactInformation');
  }
  &DEBUG("printSkillsTable: $name:  @myskills : @skillsICS : $assign ");
  my $cmd="<fieldset> <legend><strong>Skills:</strong></legend>
  <table border=1 width=700 cellspacing=0 cellpadding=5>
  <tr>";
  for(my $i=0;$i<=$#skillsICS;$i++)
  { $checked="";
    if(&MemberQ(@myskills,$skillsICS[$i])>=0){ $checked="checked"; }
    $cmd.="<tr><td> 
    <label>
      <input type=checkbox name=skills
      value='$skillsICS[$i]' $checked > _$skillsICS[$i]
    </label> ";
    $cmd.="</td></tr>";
  }
  $cmd.="</table> </fieldset>";
  print $cmd;
  # assignments
  my @localroles=@roles;
  # filter assignment
  @assignmentOptions=&AssignmentOptions($UserName); # WHY not assigned
  @localroles=@assignmentOptions;
  if(!$assign) {$assign="Initial Surveyor"}
  push @localroles,"Unavailable";
  if( $assign ne "Unassigned" ) 
  { @localroles=($assign,@localroles);
    $q->param("assignment",$assign);
  }
  print "<STRONG>Assignment:</STRONG>",
    $q->popup_menu(-name=>'assignment',-values=>[ @localroles ],-default=>$assign); # BUG??????
  &DEBUG( "printSkillsTable:assign: $assign;  @localroles; ");
  print "<br><STRONG>Contact info:</STRONG>";
  print "<BR>",
    $q->textarea(-name=>'ContactInformation',
    -default=>$ContactInformation,
    -rows=>2,
    -columns=>40), "<P>";
}


sub printFindByNameTable
{ my ($q,$type)=@_; 
  my @uniqname = &findPeopleByName($FindByName); 
  &DEBUG("printFindByNameTable: $type,$FindByName,@uniqname");
  my $formType="Sign-In";
  my $var="SignIn";
  if($type ne "User")
  { $formType="Registration";
    $var="PersonnelName";
  }
  if($#uniqname>=0)
  { print $q->h3("$formType Form"),hr();
    my $tmp=$#uniqname+1; 
    print $q->h4("$tmp names found for:");
    print $q->textfield(-name=>'FindByName' ,-size=>20),
      "<input type=submit name=action value='Try Again' >" ;
    ###############################
    my $cmd="";
    $cmd.="<fieldset> <legend>".&COMMENT("<strong>Select From Following Name(s)</strong> (if desired name is not listed you can 'Try Again' with new input or use 'New Name' form)")
    ."</legend>
     <table border=1 width=940 cellspacing=0 cellpadding=5>";
    for(my $i=0;$i<=$#uniqname;$i++)
    { my $i1=$i+1;
      $cmd.=
      "<tr><td>$i1</td>
      <td><input type=submit name=$var value='$uniqname[$i]' >
      </td></tr>";
    }
    $cmd.="</table></fieldset>";
    $cmd.=hr();
    $cmd.="<input type=submit name=action value='New Name'>" ;
    print $cmd;
    print hr(),$q->submit(-name=>'ShowInfo:SignInChoice', -value=>'Help', -id=>'helpButton');
    ###############################
    $q->param("LastFindByName",$FindByName);
  }
  else # no names found
  { print $q->h4("Name not found, re-enter partial name");
    print $q->textfield(-name=>'FindByName',-value=>"$partialNameOK",-size=>20);
    #$q->param("LastFindByName",$q->param("FindByName"));
    print $q->submit('action','Try Again');
    print "<br>".&COMMENT("or"),
    $q->submit('action',"New Name");
    $q->delete("NewPersonnel");
    print hr(),$q->submit(-name=>'ShowInfo:NameNotFound', -value=>'Help', -id=>'helpButton');
  } 
  $q->delete("FindByName");
  # BUG? &hiddenParam($q,'action');
}

sub printNewNameForm
{ my ($q)=@_;
  $q->delete("lastname"); 
  $q->delete("firstname"); 
  my $partialNameOK="string: 'tom'";
  my $FindByName=$q->param("FindByName");
  #####################################
  print &COMMENT("For registered users, enter name to log in.<br>");
  print $q->textfield(-name=>'FindByName',-size=>20, -placeholder=>'partial name OK') ;
  print $q->submit('action','Search'),hr();
  print &COMMENT("For unregistered users, add new information<br>");
  #####################################
  print 
  $q->textfield(-name=>'firstname',-size=>20,-placeholder=>'First Name'),
  $q->textfield(-name=>'lastname',-size=>20,-placeholder=>'Last Name'),
}

sub goodName
{ my @name=@_;
  my $good=1;
  foreach my $name ( @name )
  { if ( !$name or $name =~ /First Name/ or $name =~ /Last Name/ ) 
    { $good=0;
    }
  }
  return $good;
}

sub SelectDamageAddress0
{ my @damageAddress=&DamageReportAddresses; # list of vAddress return
  &DEBUG("SelectDamageAddress0: @damageAddress");
  if($#damageAddress<0) { return ""; };
  my $cmd="<select name=DamageAddress>";
  $cmd.="<option value=''>Reported Address</option>";
  foreach my $address  (@damageAddress)
  { my ($s,$a)=split(/\t/,$address);
    my $AddressStreet="$a $s";
    $cmd.="<option value='$address'>$AddressStreet</option>";
  }
  $cmd.="</select>";
  $cmd
}

sub SelectDamageAddress
{ my $cmd= &SelectDamageAddress0;
  if($cmd eq ""){ return $cmd; }
  print $q->h4("by previously Reported Address");
  $cmd.="<input type=submit name='action' value='SelectReportedAddress' >";
  $cmd
}

sub ShowInfo
{ my $info=$_[0];
  if( $info =~ /^Response Team/)
  { $info = "Response Team" ;
  }
  $info=~s/\s+//g;
  my $file="Info/$info.info"; 
  if( ! -e "$ICSdir/$file" ) { print &COMMENT("No Info file: $file<br>"); return; }
  &openICS(L,$file);
  my @type,@line,@list;
  while(<L>)
  { next if(/^\s*$/); # NO blank lines
    chop;
    if( $_ =~ /^:(.*):$/ ) 
    { push @type,$1; 
      if( $type[$#type] eq "CONTENT" )
      { print "\n<p>";
      }
      if( $type[$#type] eq "ENDLIST" )
      { pop @type; pop @type;
	print "\n</ul>\n</ul>";
      }
      if( $type[$#type] eq "LIST" )
      { print "\n<ul>";
      }
      next;
    }
    push @line,$_;
    if( $type[$#type] eq "TITLE" )
    { print hr(),"\n<h4>",pop @line," Info\n</h4>";
      pop @type;
    }
    if( $type[$#type] eq "CONTENT" )
    { print "\n",pop @line;
    }
    elsif( $type[$#type] eq "LIST" )
    { print "\n<li>",pop @line,"</li>";
    }
  }
  if( $type[$#type] eq "CONTENT" ) { print "\n</p>\n"; }
  print hr();
}

sub ShowInfoExit
{ my $info=$_[0];
  &ShowInfo($info);
  $q->param("LastAction",$UserAction);
  $q->param("InfoShown","$info");
  $q->delete('action');
  &hiddenParamAll($q); 
  print $q->submit('action','Back'); 
  print $q->end_form; 
}

sub ResetICSTool
{ my $q=@_[0];
  if($ICSpassword eq "icsroot")
  { #delete all data files
    @pat=split(/,/,"ResponseTeamLogs/*,ResponseTeams/R*,Damages/*,DamageLogs/*,Personnel/*,PersonnelLog/*,DB/Messages.db");
    foreach $pat (@pat)
    { @f = split(/\n/,`ls $ICSdir/$pat`); 
      foreach $f (@f)
      { &DEBUG("ResetICSTool: unlink: $f");
	unlink "$f";
      }
    }
    system "echo 0 > $ICSdir/ResponseTeams/lastNumber";
    chmod 0666,"$ICSdir/ResponseTeams/lastNumber"; 
    system "echo 0 > $ICSdir/Messages/lastNumber";
    chmod 0666,"$ICSdir/Messages/lastNumber"; 
    system "mkAddressList.pl";
    #
    &undefAlllocal;
    print $q->redirect("$external_url");
    &hiddenParam($q,'UserName,UserAction');
  }
  elsif(!$ICSpassword)
  { print $q->h3("Reset ICSTool Password Form"),hr();
    print $q->start_multipart_form;
    print &COMMENT("Password: "),$q->password_field('ICSpassword','',10,10);
    print hr();
    &hiddenParam($q,'UserName,UserAction');
  }
  else
  { print &COMMENT(" Invalid! "); 
    &hiddenParam($q,'UserName,UserAction');
  }
  @actions=('Submit','Cancel>Home'); 
  &SubmitActionList(@actions);
  print $q->end_form;
}

sub AssignmentOptions
{ my ($user)=@_;
  my @assignedRoles = keys %$NamesByRole_ref;
  my $userAssignment = $RoleByName_ref->{$user};
  my $rec=&FindMatchQ($userAssignment,@roleList); 
  my @roleData=split(/\t/,@roleList[$rec]); 
  my @roleListi;
  my @assignmentOptions=();
  $assignmentOptions[0]=$userAssignment; # User assignment
  #&DEBUG("AssignmentOptions: $userAssignment $rec :: @roleList :: @assignedRoles>");
  goto SKIP if( $roleData[1] eq "LEVEL.X" #|| !$user
  );
  #&DEBUG("AssignmentOptions: @roleData >");
  for(my $i=0;$i<$#roleList;$i++)
  { @roleListi=split(/\t/,@roleList[$i]);
#	print "<br>==$#roleList $rec $i $roleListi[0]==<br>";
    #&DEBUG("AssignmentOptions: @roleListi >");
    if($roleListi[2] =~ m/ResponseTeam/ )
    { push @teamAssignmentOptions,$roleListi[0];
    }
    if($roleListi[2] =~ m/canFormTeam/ )
    { push @formTeamAuthority,$roleListi[0];
      if( $userAssignment =~ m/$roleListi[0]/ ) 
      { $canFormTeam=1;
      }
    }
    if($roleListi[2] =~ m/canAssignAll/ )
    { push @assignAllAuthority,$roleListi[0];
      if( $userAssignment =~ m/$roleListi[0]/ ) 
      { $canAssignAll=1; 
        $canFormTeam=1;
      }
    }
  }
  #&DEBUG("AssignmentOptions: >> $canAssignAll; $canFormTeam; >");
  for(my $i=0; $i < $#roleList; $i++)
  { @roleListi=split(/\t/,@roleList[$i]);
#	print "<br>==$#roleList $rec $i $roleListi[0]==<br>";
    if( $canAssignAll )
    { push (@assignmentOptions,$roleListi[0]);
    }
    elsif($i>$rec) # lower positions can be assigned by user position
    { if($roleListi[1] gt $roleData[1])
      { if($roleListi[2] =~ "ICC" ) # must be ICC to assign lower positions
	{ push (@assignmentOptions,$roleListi[0]);
       	}
      }
      else # stop at next branch
      { last;
      }
    }
    elsif($i<=$rec) # collect upper Roles
    { 
      #print "<br>==$#roleList $rec $i $roleListi[0] == $roleListi[1]::$roleData[1]==@assignedRoles <br>";
      if($roleListi[1] le $roleData[1])
      { if( &FindMatchQ("Incident Commander", @assignedRoles) lt 0  # no IC all assignible
	    and (&FindMatchQ($roleListi[0], @assignedRoles) lt 0 # if role not taken
	      or $roleListi[2]=~/MultiPerson/)) # or MultiPerson
       	{ push (@assignmentOptions,$roleListi[0]);
       	}
	elsif( $roleListi[2]=~/SelfAssign/
	    and (&FindMatchQ($roleListi[0], @assignedRoles) lt 0 # if role not taken
	      or $roleListi[2]=~/MultiPerson/))
       	{ push (@assignmentOptions,$roleListi[0]);
	}
      }
    }
  }
SKIP:
#&DEBUG("AssignmentOptions:out >> @assignmentOptions >");
  push (@assignmentOptions,"Initial Surveyor"); # always
  return &uniq(@assignmentOptions);
}

sub HowToForm
{ my ($q)=@_;
  print $q->h3("'How To' Reviews"),hr();
  print &COMMENT("Select Review<br>");
  print hr(),a({-href=>"docs/SearchRescueReview.pdf",-target=>"_new"},"Search and Rescue Review");
  print hr(),a({-href=>"docs/MedicalOperations1.pdf",-target=>"_new"},"Medical Operation Review, part 1");
  print hr(),a({-href=>"docs/MedicalOperations2.pdf",-target=>"_new"},"Medical Operation Review, part 2");
  $q->param('LastAction',$UserAction);
  &hiddenParam($q,'UserName,UserAction,LastAction');
  &SubmitActionList('Cancel>Home');
  print hr(),$q->submit(-name=>'ShowInfo:HowToReviews', -value=>'Help', -id=>'helpButton' -class=>'helpButton');
  print $q->end_form;
}

1;
