#!/usr/bin/perl
# Print info from DB/DBmaster.db
# Use: getDBinfo.j <field> <firstname lastname>
# <field> == (email,cell,contact,address)
use feature ":5.10";
require "subMemberDB.pl";

@tests=@ARGV;
$field= shift  @tests;
$fields="email address contact cell all";
@fieldoptions=split(/\s+/,$fields);
if(&MemberQ(@fieldoptions,$field)<0) 
{ die "INVALID PARAMETER: first argument must be one of ($fields)\n"; 
}

$HOME=$ENV{HOME};
&TIE( @DBrecLabels );
#############################
@recn=sort {$a <=> $b} keys %DBmaster ;
for($i=0;$i<=$#recn;$i++)
{ $rec=$DBmaster{$recn[$i]};
  &SetDBrecVars($recn[$i]);
  $rec=~s/\n//g;
  @col=split(/\t/, $rec);
  $#col=$#DBmasterColumnLabels;

  if( 
    "$FirstName $LastName" =~ /$tests[0]/i && 
    "$FirstName $LastName" =~ /$tests[1]/i
  )
  { 
    print "\n";
    if( $InactiveMember ne "" ){ print "INACTIVE "}; 
    #  print "\n$Timestamp";
    # print "\n$LastName $FirstName\t";
    for($field)
    { if ( "email" =~ /$field/i )
      { print "$EmailAddress\n";
      }
      elsif ( "cell" =~ /$field/i )
      { print "$CellPhone\n";
      }
      elsif ( "address" =~ /$field/i )
      { print "$StreetAddress $StreetName $subAddress\n",
      }
      elsif ( "contact" =~ /$field/i )
      { print "$EmailAddress\t$CellPhone\t$HomePhone \n",
      }
      elsif ( "all" =~ /$field/i )
      { for(my $i=0;$i<=$#DBmasterColumnLabels;$i++)
	{ print "$DBmasterColumnLabels[$i]==${$DBmasterColumnLabels[$i]}\n";
	}
      }
      else
      { print  "INVALID PARAMETER:$field:(email,cell,contact,address)\n"; 
      }
    }
  }
}

