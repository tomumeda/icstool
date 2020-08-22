#!/usr/bin/perl
# Search Data Base for resource, e.g., ladder
do "subMemberDB.pl";

@actions=( 'FindResource'); #default actions
@Factions=( 'FindResource','ListContacts' ); #function actions

sub restore_parametersS
{ local($q) = @_;
  my @names = $q->param;
  $Resource=$q->param('Resource');
  return $q;
}

sub PrintForm
{ my $value,@results,$i,@actions,$rec;
  $q = &restore_parametersS($q);
  print $q->start_multipart_form;
  print $q->h2("Find Resource By Name/Type");

  $iaction=&MemberQ(@Factions,$action);
  if($iaction>=0)
  { &{$action};
    @actions=("Next");
  }
  else
  { 
    print "Resource: ",
    $q->textfield(-name=>'Resource',-size=>30),
    &COMMENT(" < Enter resource name, e.g., ladder, partial name OK."),
   " <BR>\n";
  }
  push (@actions,'ICS Tools');
  &SubmitActionList(@actions);
  print $q->endform;
}

sub FindResource
{ my $search=$Resource;
  my @search=split(/[\s,;]/,$search);
  print $q->h2("@search");
  my $i;
  #my @name=keys %DBmaster;
  my %found;
  my %people;
  my @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { my $recID = $recn[$i];
    my $rec=$DBmaster{ $recID };
    my @col=split(/\t/, $rec);
    my $equipment=$col[$DBcol{EmergencyEquipment}];
    if( &AllMatchQ( $equipment, @search ) == 1)
    { my $address = "$col[$DBcol{Street}] $col[$DBcol{Address}]";
      for(my $j=0;$j<=$#search;$j++)
      { my $pattern="$search[$j]";
       	$PATTERN=uc($pattern);
       	$equipment =~ s/$pattern/<font color=\"red\">$PATTERN<\/font>/i; 
	$found{"$address"}=$equipment;
	$people{"$address"}.="$recID,";
      }
    }
  }
  foreach my $address ( sort keys %found)
  { my @recIDs=split(",",$people{$address});
    my $actionX="ListContacts=".join(",",@recIDs);
    $actionX =~ s/[,\s]$//;
    print ">>$found{$address} @ $address > ",
    $q->submit('action',"$actionX"),
    "<font color=\"black\"> <br>\n" ;
  }
  return(1);
}

sub ListContacts
{ my @ids=split(/,/,$ContactIDs);
  for(my $i=0;$i<=$#ids;$i++){ $ids[$i]=1*$ids[$i]; }
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
if( $actionMOD =~/ListContacts/ )
{ ($action,$ContactIDs)=split(/=/,$actionMOD);
}

print $q->header;
print $q->start_html(-title=>'Find Resource By Name', -style=>{'src'=>'../../index.css'});
print $q->h1("Neighborhood Resources $timeh1");

&TIE( @DBname );

&PrintForm;
print  $q->end_html;
&UNTIE( @DBname );

