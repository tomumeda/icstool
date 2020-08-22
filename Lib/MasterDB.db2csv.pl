#!/usr/bin/perl
# Print MemberDB.csv from DB/DBmaster.db
do "subMemberDB.pl";
#############################
&TIE( @DBname );
open L1,"$file_csv" || die;
open L3,">$file_csv.test.csv";
# copy first 2 lines 
#
for($i=0;$i<2;$i++)
{ $_=<L1>;
  print L3 $_;
}

#&PrintCol( @DBmasterColumnLabels ); # NOW included in .db as first record
@recn=sort {$a <=> $b} keys %DBmaster ;

for($i=0;$i<=$#recn;$i++)
{ $rec=$DBmaster{$recn[$i]};
  $rec=~s/\n//g;
  @col=split(/\t/, $rec);
  $#col=$#DBmasterColumnLabels;
    next if( $col[$DBcol{InvolvementLevel}] !~ /Active/i );

  print ">>$i:$rec ($#col) \n";
  &PrintCol(@col);
}

