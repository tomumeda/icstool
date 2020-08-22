#!/usr/bin/perl
# Update forms for Member CERT Training History
# parameter: SelectName=LastName.FirstName&action=Display
do "subCommon.pl";
do "subMemberDB.pl";
$SelectName = $ENV{"QUERY_STRING"};
$SelectName=~s/SelectName=(.*)&.*$/$1/; #Flag for direct entry
#
sub PrintForm
{ my $q = &restore_parametersS($q);
  my $value,@results,$i,@actions,$rec;
  print $q->start_multipart_form;
  print $q->h1("Training History $timeh1");
  if ($action  eq 'FindByName')
  { &MemberNamesFound;
    @actions=('Display','Cancel');
  }
  elsif($action eq 'Display')
  { my $recno=$q->param('SelectName');
    if( $recno =~ /^\D/ )  #if not recno
    { my $name = &dotName2LastFirst($recno);
      $recno=$DBrecName{ $name };
    }
    &TrainingHistory($recno);
    @actions=('Save','Cancel');
  }
  elsif($action =~ m/^Save/ )
  { my @parms=$q->param;
    my $name=$q->param("Name");
    my @out=($BlockSeparator,$timestr);
    print $q->h2("CERT Classes Added ($name)");
    for(my $i; $i<length[@parms];$i++)
    { if($parms[$i]=~m/ClassName:/ )
      { my ($dum,$class)=split(/:/,$parms[$i],2);
	my @dates=$q->param($parms[$i]);
	my $dates=join(", ",@dates);
	if($dates)
	{ print &COLOR("blue",$class)," ($dates)<br>";
	  for(my $j=0;$j<=$#dates;$j++)
	  { push @out,"CERTClassNameDateCompleted=$class ($dates[$j])";
	  }
	}
      }
    }
    open L,">>MemberHistory/$name";
    print L join("\n",@out),"\n";
    close L;
    if( $SelectName ) 
    { print &COMMENT("Thank You!<br>")
    }
    else
    { @actions=('Next','Cancel');
    }
  }
  else
  { print "FindByName: ",
      $q->textfield(-name=>'FindByName',-size=>30)," <font color=\"red\"> Enter part of a name to get a list of possible names.<BR>\n";
    @actions=('FindByName');
  }
  if( $SelectName ) { }
  else
  { push (@actions,'Up','Home'); 
  }
  &SubmitActionList(@actions);
  print $q->endform;
}

# displays Training History for Member at DBmaster index
sub TrainingHistory
{ local ($index)=@_;
  my $status;
  my $name=&DBname($index);
  print $q->h2("CERT Classes Completed ($name)");
  my $file="MemberHistory/$name";
  open L,"$file";
  while(<L>)
  { if(/CERTClassNameDateCompleted=/) 
    { my ($dum,$class)=split(/=/,$_);
      print "$class <br>";
    }
  }
  print "$BlockSeparator<br>",
  &COMMENT("CERT Classes to add to your list<br>");
  open L,"recentCERTclasses.d";
  while(<L>)
  { chop;
    my ($class,@dates)=split(/\t/,$_);
    print &COLOR("blue","$class: ");
    print $q->checkbox_group(-name=>"ClassName:$class",-values=>[@dates]);
    print "<br>";
  }
  print &COLOR("red","Write in any other: ");
  print $q->textfield(-name=>"ClassName:Other",-size=>50),"<br>";
  print $q->hidden("Name","$name");
}

sub restore_parametersS 
{ local($q) = @_;
  my @names = $q->param;
  if($FindByName=$q->param('FindByName'))
  { 
  } 
  return $q;
}   

##############################
&initialization;
$action=$q->param('action');
if($action eq 'Up') { &JumpToLabel("sec:ICCDevelopment"); }
if($action eq 'Home') { &JumpToLabel("sec:Home"); }

&HTMLHeader;
#print "($action,$SelectName)>>",join(" ",$q->param),"<<";#DEBUG
print $q->start_html(-title=>'Member Training History',
  -author=>'takato@pacbell.net',
  -style=>{'src'=>'../index.css'});
&TIE( @DBname );
&PrintForm;
print  $q->end_html;
&UNTIE( @DBname );
