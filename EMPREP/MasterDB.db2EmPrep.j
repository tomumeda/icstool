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
my @list;
for(my $i=0;$i<=$#recn;$i++)
{ my $rec=$DBmaster{$recn[$i]};
  $rec=~s/\n/; /g;
  my @col=split(/\t/, $rec);
  $#col=$#DBmasterColumnLabels;
  next if( $col[$DBcol{InvolvementLevel}] !~ /Active/i );
  #print ">>$i:$rec ($#col) \n";
  #&printL3Col(@col);
  my $sortrec= &vAddressFromDBrec($rec);
  push @list,"$sortrec\t$rec";
}
@list=sort(@list);
#print join("\n>>",@list);
for(my $i=0;$i<=$#list;$i++)
{ my $rec = $list[$i];
  my @col=split(/\t/, $rec);
  @col=&deleteArrayIndex(0,@col);
  &printL3Col(@col);
}

#####################################
sub printL3Col
{ my @col=@_;
  my $cols=join("\",\"",@col);
  print L3 "\"",$cols,"\"\n";
}

