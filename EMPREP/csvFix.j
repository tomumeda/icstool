#!/usr/bin/perl
require "subCommon.pl";
					#
$file_csv="DB/MasterDB.csv"; 		# OUTPUT name
open L0,"$file_csv.20200307091304"; 		# input file -- change each month
# TEST
if(1==2){
@divblock=&arrayTXTfile("DB/DivBlock.8feb2020.csv");
for(my $i=0;$i<=$#divblock;$i++)
{ my ($street,$address,$subaddress,$divblock)=split(/,/,$divblock[$i]);
  print ">>>$street,$address,$subaddress,$divblock\n";
  $divblock{"$street=$address"}=$divblock;
}
}

# TEST
open L1,">xoutQ";
open L2,">xout";
open Lduplicate,">csvFix.duplicate.names";
open L3,">$file_csv"; # output file ; do not change L3
############################
$lineSep="n";
while(<L0>)
{ $_=&evenQuotes($_);
  $_=~s/\r//g;
  push(@lines,$_);

}
#die "lineSep: ( $lineSep )";
############################
$lines[0]=~s/\s+//g;	# Labels have no spaces
#		 DBcol from lines[0]
$first=$lines[0];
@label=split(/,/,$lines[0]);
for(my $i=0;$i<=$#label;$i++)
{ $DBcol{$label[$i]}=$i;
}
#
############################
my $cnt=0;
for($il=0;$il<=$#lines;$il++)
{ $line=$lines[$il];
  if( &evenQuotesQ($line) eq 0)  {die "Uneven quotes $line"}
  #
  #test portion
  @rec= &STRG4String($line) ;
  @rec=map { my $tmp=&clean_name($_);$tmp } @rec;
  print L2 "\n>> $cnt ::\n";;
  print L1 join("=",@rec),"=<<\n";
  
  # EDITS #############################################################
  if(1==2){
  my $Xaddress=$rec[$DBcol{"StreetName"}]."=".$rec[$DBcol{"StreetAddress"}];
  #print "###XXX $Xaddress >> $divblock{$Xaddress}\n";
  if($il>1) # skip header
  {
    if($rec[$DBcol{'GroupAffiliation'}] eq "")
    { $rec[$DBcol{'GroupAffiliation'}]="NorthSide EmPrep.$divblock{$Xaddress}";
    }
    
    if($rec[$DBcol{'InvolvementLevel'}] eq "")
    {
      if($rec[$DBcol{'InactiveMember'}] =~ /Yes/i )
      { $rec[$DBcol{'InvolvementLevel'}]="No Involvement";
      }
      else
      { $rec[$DBcol{'InvolvementLevel'}]="Active";
      }
    }
  }
}

  # #############################################################
  
  # 		diagnostic output
  for($i=0;$i<=$#rec;$i++)
  { print L2 "$label[$i] : $rec[$i] \n";
  }
  $name="$rec[$DBcol{LastName}].$rec[$DBcol{FirstName}]";
  #print $name,"\n";
  $namecnt{$name}++;
  # output new csv portion
  if($#rec<3){ die "rec->> @rec"; }
  &PrintCol(@rec);
  $line=join(",",@rec);
  $cnt++;
  print "\n>>$#rec ::",join("::",@rec),"<<\n";
}
foreach $name (keys %namecnt)
{ if($namecnt{$name} >1)
  { print "\nDUPLICATE NAME $name : $namecnt{$name}";
    print Lduplicate "DUPLICATE NAME $name : $namecnt{$name} \n";
  }
}

############################
sub evenQuotesQ
{ my $str=$_[0];
    $test=$str;
    $test=~s/[^"]//g;
    if(length($test)%2 eq 0) { return(1) }
    else{ return(0) };
}

sub evenQuotes
{ my $str=$_[0];
  my $nQuote=1;
  while( $nQuote ne 0 )
  { $test=$str;
    $test=~s/[^"]//g;
    if( ($nQuote=length($test)%2) ne 0)
    { $str=$str.<L0>;
    }
  }
  $str
}

