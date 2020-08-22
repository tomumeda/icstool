#!/usr/bin/perl
# List {people,pets} by Address.
do "subMemberDB.pl";

@actions=();	#default actions
@Factions=( 'WhoIsAtAddress',"SelectAddress" ); #function actions

sub restore_parametersS
{ local($q) = @_;

  $Street=$q->param('SelectAddress');
  if( $Street ne "" ) { $action="SelectAddress"; }
  else { $Street=$q->param('Street'); }
  $AddressStreet=$q->param('WhoIsAtAddress');
  if( $AddressStreet ne "" ){ $action="WhoIsAtAddress"; }
  #print "Param: @names; $Street; $AddressStreet;;";
  return $q;
}

sub PrintForm
{ my $value,@results,$i,@actions,$rec;
  $q = &restore_parametersS($q);
  print $q->start_multipart_form;
  print $q->h2("Who Is At Street Address?");
  $iaction=&MemberQ(@Factions,$action);
  if($iaction>=0)
  { &{$action};
  }
  else
  { print &COMMENT("Select Street Name: ") ;
    foreach my $street (@street)
    { print "<br>";
      print $q->submit('SelectAddress',$street);
    }
    print "<br>" ; 
    print &COMMENT("Else: ") ;
    @actions=();
  }

  push (@actions,'Next','ICS Tools');
  &SubmitActionList(@actions);
  print $q->endform;
}

sub SelectAddress
{ my @addresses=split(/\t/,$DBAddressOnStreet{$Street});
  print &COMMENT("Select Address on ($Street)<br> ");
  foreach my $address (@addresses)
  { my $AddressStreet="$address=$Street";
    print $q->submit('WhoIsAtAddress',$AddressStreet),"<br>";
  }
  print "<br>";
  print &COMMENT("Else: ");
  @actions=();
}

sub WhoIsAtAddress
{ my ($address,$street)=split(/=/,$AddressStreet);
  my @foundI=();
  my @recn=sort {$a <=> $b} keys %DBmaster ;
  for($i=0;$i<=$#recn;$i++)
  { my $rec=$DBmaster{ $recn[$i] };
    my @col=split(/\t/, $rec);
    my $DBaddress=$col[$DBcol{Address}];
    my $DBstreet=$col[$DBcol{Street}];
    if( "$address $street" eq "$DBaddress $DBstreet" )
    { push(@foundI,$recn[$i]); 
    }
  }
  print $q->h2("$address $street");
  &PrintContactInfo(@foundI);
  @actions=();
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
print $q->start_html(-title=>'Who Is At Street Address', -style=>{'src'=>'../../index.css'});
print $q->h1("Neighborhood Resources $timeh1");

&TIE( @DBname );
&PrintForm;
print  $q->end_html;
&UNTIE( @DBname );

