#!/usr/bin/perl
# generates DB from CSV file
# with keys => vAddresses
# values => CSV record (tab separated)
# Header file => column label \t separated
use FileHandle;
require "subUtility.pl";
my ($cnt,$tmp,$group);

$group="HillsideNeighbors";

my $L=FileHandle->new;
my $L1=FileHandle->new;
my $Lout=FileHandle->new;
my $Lmaster=FileHandle->new;
my @StreetNameChange=&arrayTXTfile("StreetNameChange.d");
my %StreetNameChange;
map { my ($a,$b)=split(/\t/,$_); $StreetNameChange{$a}=$b } @StreetNameChange;

my $file_csv="data/$group.csv";
open $L,"$file_csv" || die "Can't open $file_csv";
########## Print Header 
my $header=&readCSVline($L);
my @header= &STRG4String($header) ;
$header=join("\n",@header);
#	print "HEADER: $header\n";
open $L1,">data/$group.Header.csv";
&printCSV($L1,@header); close $L1; 
my %col=&headerColumn(@header);
###
open $Lmaster,"DB/MasterDB.csv.Descriptor";
while(<$Lmaster>)
{ chop;
  my @term=split(/\t/,$_);
  $headerM[$.-1]=$term[0];
  $descriptionM[$.-1]=$term[1];
}
my %colM=&headerColumn(@headerM);
###################
my @recM=map {""} @headerM;
#	die "@headerM >> @descriptorM";
#########################
#	$DB="$group";
#	unlink "DB/$DB.db";
#	&TIE( $DB );
########################
open $Lout,">DB/MasterDB.csv";
&printCSV($Lout ,@headerM);
&printCSV($Lout ,@descriptionM);

$cnt=0;
open $L,"$file_csv" || die "Can't open $file_csv"; # Includes Header
<$L>; # ignore header
while($_=&readCSVline($L))
{ $cnt++;
  #	if($cnt > 10) { die; }
  #	print "\n\nXX: $cnt:$_";
  my @rec = &STRG4String($_) ;
  #	print "\n\n0000>>$#rec : ",join("<>",@rec);	# input rec
  my @recM=map {""} @recM;	# zero output rec
  if($group eq "HillsideNeighbors")
  { my $a,$b;
    my $HomePhone="";
    my $CellPhone="";
    print "\nTT: "
    ,$a=$rec[$col{"Phone 1 - Type"}],
    ,$b=$rec[$col{"Phone 1 - Value"}],
    ,"";
    if($a eq "Mobile" and $b ne "") 
    { $CellPhone=$b;
      $recM[$colM{"CellPhone"}]=$b,
    }
    elsif($b ne "") 
    { $HomePhone=$b; 
      $recM[$colM{"HomePhone"}]=$b,
    }
    print "\nNN CellPhone $CellPhone ";
    print "\nNN HomePhone $HomePhone";

    $recM[$colM{"HomePhone"}]=$HomePhone;
    $recM[$colM{"CellPhone"}]=$CellPhone;

    print "\nNN LastName: "
    ,my $LastName=$rec[$col{"Family Name"}],
    ,"";
    $recM[$colM{"LastName"}]=$LastName;
    print "\nNN FirstName: "
    ,my $FirstName=$rec[$col{"Given Name"}],
    ,"";
    $recM[$colM{"FirstName"}]=$FirstName;

    my $Street=$rec[$col{"Address 1 - Street"}];
    $Street=~s/ :::[.]*$//;
    #	print "\n>>>Street: $Street" ;
    my ($StreetAddress,$StreetName)=split(/\s+/,$Street,2);

    my $tmp=$StreetNameChange{$StreetName};
    $StreetName=$tmp?$tmp:$StreetName;

    my $subAddress=$rec[$col{"Address 1 - Extended Address"}];
    $subAddress=~s/::://g;
    print "\nNN StreetName $StreetName :  $StreetAddress , $subAddress"
    ,"";
    $recM[$colM{"StreetName"}]=$StreetName;
    $recM[$colM{"StreetAddress"}]=$StreetAddress;
    $recM[$colM{"subAddress"}]=$subAddress;

    my $EmailAddress=$rec[$col{"E-mail 1 - Value"}];
    print "\nNN EmailAddress  $EmailAddress"
    ,"";
    $recM[$colM{"EmailAddress"}]=$EmailAddress;

    my $Comments=$rec[$col{"Notes"}];
    print "\nNN Comments  $Comments"
    ,"\n";
    $recM[$colM{"Comments"}]=$Comments;

    $recM[$colM{"GroupAffiliation"}]="Hillside Neighbors";
    $recM[$colM{"InvolvementLevel"}]="Active";

  }
  print "\n>>>",join("; ",@recM);
  print "\n>>>$#recM";
  &printCSV($Lout ,@recM);
}
print "\n",join("; ",keys %colM);
print "\n",join("; ",values %colM);

#print keys %{$DB};
#	&UNTIE( $DB );
#	system "chmod 666 DB/$DB.db";

# returns %col with column label as keys and column number as values
# from @header information
sub headerColumn
{ my @header=@_;
  my $cnt=0;
  my %col;
  map { $col{$_}=$cnt++ } @header;
  return %col;
}

