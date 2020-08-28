#!/usr/bin/perl
use lib ("/Users/Tom/Sites/ICSTool/Lib", "/home/tom/Sites/ICSTool/Lib");

# Print list of street address
require "subMemberDB.pl";
#############################
&TIE( @DBname );
open L1,"|sort -u >StreetAddressList.d";
open L2,"|sort -u >StreetList.d";

@recn=sort {$a <=> $b} keys %DBmaster ;
for($i=0;$i<=$#recn;$i++)
{ $rec=$DBmaster{ $recn[$i] };
  @col=split(/\t/, $rec);
  # edit address  into vAddress form
  $col[$DBcol{"StreetName"}]=~/(\d*)\s*(.*)/;
  if($2) # edit old subAddress
  { 
    #print "\n:", $col[$DBcol{"Address"}];
#    $col[$DBcol{"Address"}]=~/(\d*)\s*(.*)/;
#    if($2) { $col[$DBcol{"Address"}]=~s/(\d*)\s*(.*)/$1=$2/; }
    print "\n:", $col[$DBcol{"StreetAddress"}];
  }
  print L1 "$col[$DBcol{'StreetName'}]\t$col[$DBcol{'StreetAddress'}]\t$col[$DBcol{'subAddress'}]\n";
  print L2 "$col[$DBcol{'StreetName'}]\n";
  #print L3 "$col[$DBcol{'Street'}]\t$col[$DBcol{'Street'}]\t$col[$DBcol{'subAddress'}]\n";
  if($col[$DBcol{'subAddress'}])
  { $address{$col[$DBcol{'StreetName'}]}.="$col[$DBcol{'StreetAddress'}]=$col[$DBcol{'subAddress'}]\t";
  }
  else
  { $address{$col[$DBcol{'StreetName'}]}.="$col[$DBcol{'StreetAddress'}]\t";
  }
}
print "\naddresses: ",join("<>",keys %address);
print "\naddresses: ",join("<>",values %address);

foreach $street ( keys %address )
{ @address=split("\t",$address{$street});
  @address=&uniq(@address);
  $file="AddressesOn/$street";
  open L4,">$file";
  print L4 join("\n",@address),"\n";
}

