#!/usr/bin/perl
# Search member list for queried skill
do "subMemberDB.pl";
&initialization;

@workgroups=( "First Aid", "Search And Rescue", "Fire Suppression", "Communications","Logistics"
);

@SkillActions=(
  'FindBySkill',
  'FindBySkill_SignedIn',
);

@WorkGroupActions=(
  'FindByWorkGroup',
  'FindByWorkGroup_SignedIn',
); 

@actions=@WorkGroupActions;
push(@actions,@SkillActions,"ListInfo");

sub restore_parametersS
{ local($q) = @_;
  my @names = $q->param;
  $Skill=$q->param('Skill');
  $WorkGroup=$q->param('WorkGroup');
  return $q;
}

sub PrintForm
{ my $value,@results,$i,@actions,$rec;
  $q = &restore_parametersS($q);
  print $q->h2("Find Person By Work Group or General Skill");
  print $q->start_multipart_form;
  $iaction=&MemberQ(@actions,$action);
  if($iaction>=0)
  { &{$action};
    @actions=("Next");
  }
  else
  { 
    print "Select EmPrep Work Group:",
    &COMMENT(" (if searching by EmPrep work group )"),
    "<br>";
    print $q->radio_group(-name=>'WorkGroup', -values=>[ @workgroups ],
      -linebreak=>'yes', -default=>$workgroups[0]) ;
    &SubmitActionList(@WorkGroupActions);
    print &COMMENT("\< Choose one of these.");

    print "<br><br><strong>OR</strong><br><br>Search for Skill: ",
    $q->textfield(-name=>'Skill',-size=>30),
    &COMMENT(" \< Partial name OK, e.g., psych"), "<BR>\n" ;
    @actions=@SkillActions;
  }
  push (@actions,'ICS Tools');
  &SubmitActionList(@actions);
  print &COMMENT("\< Choose one of these.");
  print $q->endform;
}

sub FindBySkill_SignedIn
{ my $search=$Skill;
  my @search=split(/[\s,;]/,$search);
  print "People Signed In with ( @search ) skills: <br><br>";
  my $i,%foundskills;
  my @name=keys %DBmaster;
  @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { ##################################
    $rec=$DBmaster{ $recn[$i] };
    @col=split(/\t/, $rec);
    if( &AllMatchQ( $col[$DBcol{SkillsForEmergency}] , @search ) == 1
      && &SignInStatus($recn[$i])=~"IN" )
    { 
      my $actionX="ListInfo=$recn[$i]";
      print $q->submit('action',"$actionX");
      print "$col[$DBcol{NameFirst}] $col[$DBcol{NameLast}] -> $col[$DBcol{SkillsForEmergency}] <BR>\n";
    }
  }

  return(%foundskills);
}

sub FindByWorkGroup_SignedIn
{ my $search=$WorkGroup;
  my @search=split(/[\s,;]/,$search);
  print "People Signed In with ( @search ) WorkGroup: <br><br>";
  my $i,%foundskills;
  my @name=keys %DBmaster;
  @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { $rec=$DBmaster{ $recn[$i] };
    @col=split(/\t/, $rec);
    if( &AllMatchQ( $col[$DBcol{SkillsForEmergency}] , @search ) == 1
      && &SignInStatus($recn[$i])=~"IN" )
    { 
      my $actionX="ListInfo=$recn[$i]";
      print $q->submit('action',"$actionX");
      print " $col[$DBcol{NameFirst}] $col[$DBcol{NameLast}] -> $col[$DBcol{SkillsForEmergency}] <BR>\n";
    }
  }
  return(%foundskills);
}

sub FindByWorkGroup
{ my $search=$WorkGroup;
  my @search=split(/[\s,;]/,$search);
  print "People with ( @search ) WorkGroup: <br><br>";
  my $i,%foundskills;
  my @name=keys %DBmaster;
  @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { $rec=$DBmaster{ $recn[$i] };
    @col=split(/\t/, $rec);
    if( &AllMatchQ( $col[$DBcol{SkillsForEmergency}] , @search ) == 1)
    { 
      my $actionX="ListInfo=$recn[$i]";
      print $q->submit('action',"$actionX");
      print " $col[$DBcol{NameFirst}] $col[$DBcol{NameLast}] -> $col[$DBcol{SkillsForEmergency}] <br>\n";
    }
  }
  return(%foundskills);
}

sub FindBySkill
{ my $search=$Skill;
  my @search=split(/[\s,;]/,$search);
  print "People with ( @search ) skills: <br><br>";
  my $i,%foundskills;
  my @name=keys %DBmaster;
  @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { $rec=$DBmaster{ $recn[$i] };
    @col=split(/\t/, $rec);
    if( &AllMatchQ( $col[$DBcol{SkillsForEmergency}] , @search ) == 1)
    { 
      my $actionX="ListInfo=$recn[$i]";
      print $q->submit('action',"$actionX");
      print " $col[$DBcol{NameFirst}] $col[$DBcol{NameLast}] -> $col[$DBcol{SkillsForEmergency}] <BR>\n";
    }
  }
  return(%foundskills);
}

# returns SignedIn status (IN/OUT) for DBmaster index and Personnel/<name>
sub SignInStatus
{ local $index=@_[0];
  local $status=&PersonnelSignInStatus(&DBname($index));
  return($status);
}

sub ListInfo
{ my @ids=($ContactID);
  print "Contact Info for: <br>";
  &PrintContactInfo(@ids);
}

#############################
# MAIN routine
#############################
&initialization;
$action=$q->param('action');

if($action eq 'ICS Tools')
{ &JumpToLabel("sec:ICCDevelopment");
}
elsif($action eq 'Home')
{ &JumpToLabel("sec:Home");
}

my $actionMOD=$action;
if( $actionMOD =~/ListInfo/ )
{ ($action,$ContactID)=split(/=/,$actionMOD);
}

print $q->header;
print $q->start_html(-title=>'Find Person By Skill', -style=>{'src'=>'../../index.css'});
print $q->h1("Neighborhood Resources $timeh1");
&TIE( @DBname );
&PrintForm;

print  $q->end_html;
&UNTIE( @DBname );

