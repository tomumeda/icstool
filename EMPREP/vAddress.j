#!/usr/bin/perl
#
#($City,$Street,$Address,$Address1)=("Berkeley","Le Roy Ave","1643","#D");
# definitions and routines to handle vAddresses
$vAddressDelim="=";
$vAddressNames="Street,Address,SubAddress";
$SelectvAddressNames="SelectStreet,SelectAddress,SelectSubAddress";
@vAddressNames=split(/,/,$vAddressNames);
@SelectvAddressNames=split(/,/,$SelectvAddressNames);

sub vAddressString # makes vAddressString (use in file names) 
{ my @vAddress=&deleteNullItems(@_);
  return join( $vAddressDelim, @vAddress );
}
#print &vAddressString("Le Roy Ave","1643",""),"\n";

sub StringvAddress # makes vAddress from vAddressString 
{ my ($vAddressString)=@_;
  return split($vAddressDelim,$vAddressString);
}
# @a= &StringvAddress( &vAddressString('Le Roy Ave','1643',"DD") );
# print "@a";

###
sub vAddressStringFromParam
{ my $q=@_[0];
  my $name,@vAddress;
  $#vAddress=-1; # my does not clear this variable
  for $name ( @SelectvAddressNames )
  { # print "N:$name: ", $q->param($name),":n:";
    push(@vAddress, $q->param($name));
  }
  #   print "==@vAddress:<br>";
  return &vAddressString(@vAddress);
}

###
sub vAddressStringToParam # add vAddress to $q->param
{ my ($q,$vAddressString)=@_;
  my @vAddress=&StringvAddress($vAddressString);
  for(my $i=0;$i<=$#vAddress;$i++)
  { $q->param($SelectvAddressNames[$i],$vAddress[$i]);
  }
  return $q;
}

