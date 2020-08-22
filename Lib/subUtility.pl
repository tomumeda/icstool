#!/usr/bin/perl
#################################
# PUT IN STARTUP.pl
use Fcntl;
use FileHandle;
use DB_File;
use Time::Local;
use URI::Escape;
use POSIX qw(strftime);

############# global variables
# ICSTool root directory
sub setICSdir
{ my $SCRIPT_FILENAME=$ENV{SCRIPT_FILENAME};
  my @parts=split(/\//,$SCRIPT_FILENAME);
  $#parts-=1;
  $ICSdir=join("/",@parts);
  if(!$ICSdir) # not from WEB
  { $ICSdir=$ENV{PWD};
  }
  $ENV{ICSdir}=$ICSdir;
  #print ">>ICSdir: $ICSdir<br> ";
}

if(!$ICSdir)
{ &setICSdir;
}

#
$BlockSeparator="-----------------------------------";
# HTML parameters
#$EntryType=$ENV{"QUERY_STRING"};
#$EntryType=~s/CallType=(.*)/$1/;
#$EntryType=~s/\+/ /g;
#print  "<br>QUERY_STRING: ",$ENV{"QUERY_STRING"};
# $OrgName=$ENV{"QUERY_STRING"};
# $OrgName=~s/OrgName=(.*)/$1/;
# $OrgName="EmPrep";
############# global variables

# default initialization 
sub initializationBasic
{ 
  &Set_timestr;
  &SetUrls;
} 

# default initialization 
sub initialization
{ 
  &Set_timestr;
  &SetUrls;
} 

# converts URI encoded string to normal string
sub uri_unescape
{ my $string=@_[0];
  $string=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
  return $string;
}
# evaluate calling parameter string in form a=b&c=d
sub Eval_QUERY_STRING
{ my $ParmString=&uri_unescape($ENV{"QUERY_STRING"});
  my @ParmString=split(/&/,$ParmString);
  foreach my $eqn (@ParmString)
  { my @eqn = split(/=/,$eqn,2);
    ${$eqn[0]}=$eqn[1];
    # print "<br>Eval_QUERY_STRING: $eqn";
  }
}

sub xxSetUrls
{ 
  $external_url      = url(-path_info => 1);
  my $current_url    = url();
  my @path=split "/",$current_url ;
  $#path-=3;
  $HomeUrl=join "/",@path;  # set relative to ../ICC/PL
  &DEBUG("SetUrls: $external_url");
}

# Very important subroutine -- get rid of all the naughty
# metacharacters from the file name. If there are, we
# complain bitterly and die.
sub clean_name {
   my($name) = @_;
    $name=~s/^\s+//; #no leading blanks
    $name=~s/\s+$//; #no trailing blanks
    $name=~s/  / /g; #only single spaces
   return "$name";
}

sub string_NoBlank
{ my($in)=@_;
  $in=~s/\s+//g;
  return $in;
}

################################################
# Subroutines
sub TIE		#If this does not seem to work in WEB calls (CHECK permissions)
{ my @list=@_;
  my $type;
  foreach $type (@list)
  { if($type=~/\w/)
    { tie(%{$type},"DB_File","$ICSdir/DB/$type.db",O_RDWR|O_CREAT,0666,$DB_BTREE) #TEST
	or die "!!!! Check DB permissions: abort at tie: $ICSdir/DB/$type :: $ICSdir"; # THIS WORKS
    }
  }
}

sub UNTIE
{ my @list=@_;
  foreach $type (@list) { untie %{$type}; }
}

# returns %column {$name} -> column# from $DBname of "Header" key
sub DBHeaderCol
{ my ($DBname)=@_;
  my $headRec=${ $DBname }{ "Header" };
  my @header=split(/\t/,$headRec);
  my %col;
  my $col=0;
  map { $col{ $_ }=$col++ } @header;
  return %col;
}

##################
sub Set_timestr
{ 
  $UXtime=time;
  $timestr= strftime "%a %b %e %H:%M %Y", localtime;
  $timestamp= strftime "%Y-%m-%d %H:%M:%S", localtime;
  $yyyymmddhhmmss= strftime "%Y%m%d%H%M%S", localtime;
  $timeh1="<small>($timestr)</small>"
}

#############################
# returns array from string with comma separator.  Delete spaces. Used in 
# converting .csv
sub MakeArray
{ my ($string)=$_[0]; # "label1, label2, label3")
  $string=~s/\s//g;
  return split(/,/,$string); 
}
#########################
##POD 
##POD uniq( @list )
##POD   return @unique_list from @list (strings)
sub uniq
{ my($i,$ii,$test1,$test2);
  my @retval;
  my ( @slist ) = sort (@_);
  for($i=0;$i<=$#slist;$i++)
  { my $test1=$retval[$ii-1];
    my $test2=$slist[$i];
    if ( $test1 ne $test2 ){ $retval[ $ii++ ] = $slist[$i]; }
  }
  return(@retval);
}

#########################
##POD 
##POD MemberQ( @list, $test )
##POD   return index to $test in @list (strings)
sub MemberQ
{ local($i); local($elem)=pop(@_);
  #if($#_>-1) { 
    for($i=0;$i<=$#_;$i++) { return($i) if( $elem eq $_[$i] ); }
    #}
  return(-1);
}
#########################
##POD 
##POD MemberQlc( @list, $test )
##POD   return index to $test in @list (strings)
sub MemberQlc
{ local($i); local($elem)=pop(@_);
  #if($#_>-1) { 
    for($i=0;$i<=$#_;$i++) { return($i) if( lc($elem) eq lc($_[$i]) ); }
    #}
  return(-1);
}

#########################
#POD 
#POD &FindPattern(@list,$pattern); 
#POD 	find first item in @list with $pattern
sub FindPattern 
{ local($i); local($pattern)=pop(@_);
  for($i=0;$i<=$#_;$i++) { return($i) if( $_[$i] =~ m/$pattern/ ); }
  return(-1);
}

#POD return the index to first item in @list that matches /^$find/
sub FindMatchQ
{ my ($find,@list)=@_;
  return(-1) if($find eq "");
  for(my $i=0;$i<=$#list;$i++) { return($i) if( $list[$i] =~ /^$find/ ); }
  return(-1);
}

#POD return the index to first item in @list whose matches the head of $find
sub FindFirstElement
{ my ($find,@list)=@_;
  my $index=&FindMatchQ($find,@list);
  if($index<0) { return(""); }
  return($list[$index]);
}

# returns 1 if all strings in @find are found in $base.
sub AnyMatchQ
{ my ($base,@find)=@_;
  my $i,$match=0;
  #&DEBUG("AnyMatchQ:$base;;@find");
  if($#find==0 and $base =~/$find[0]/i) # needed because the following does not seem to find mismatch
  { $match=1; return($match);
  }
  for($i=0;$i<=$#find;$i++)
  { 
    #&DEBUG("AllMatchQ:$i;;$base;;$find[$i]");
    if( $base=~/$find[$i]/i )
    { $match=1;
      #&DEBUG(">>AnyMatchQ:$match;;$base;;$find[$i];;",$base eq $find[$i]);
      last;
    }
  }
  return($match);
}

# returns 1 if all strings in @find are found in $base.
sub AllMatchQ
{ my ($base,@find)=@_;
  my $i,$match=1;
  #&DEBUG("AllMatchQ:$base;;@find");
  if($#find==0 and $base eq $find[0]) # needed because the following does not seem to find mismatch
  { return($match);
  }
  for($i=0;$i<=$#find;$i++)
  { 
    if( $base!~/$find[$i]/i )
    { $match=0;
      #&DEBUG(">>AllMatchQ:$match;;$base;;$find[$i];;",$base eq $find[$i]);
      last;
    }
  }
  return($match);
}

sub COMMENT
{ my $c=$_[0];
  return "<font color=\"red\">$c<font color=\"black\">";
}

sub BOLD
{ my $c=$_[0];
  return "<strong>$c</strong>";
}

sub COLOR
{ my ($color,$text)=@_;
  return "<font color=\"$color\">$text<font color=\"black\">";
}

sub BlockDifference
{ my ($separator,@lines)=@_; # contains 2 blocks terminating with $separator 
  # returns 
  # added element to block1 relative to block2
  # $separator
  # added element to block2 relative to block1
  # $separator
  my $cnt;
  my @savelines;
  my @block1,@block2;
  $#block1=$#block2=-1;
  my $n=1;
  for(my $i=0;$i<=$#lines;$i++) #load 2 blocks
  { if($n==1){ push(@block1,$lines[$i]) }
    else { push(@block2,$lines[$i]) }
    if($lines[$i] =~ m/$separator/ ) { $n++; next; };
    last if ($n>2);
  }
  #find new block1 elements
  for(my $i=0;$i<=$#block1;$i++)
  { my $test=$block1[$i];
    $cnt=0;
    for(my $j=0;$j<=$#block2;$j++)
    { if($test eq $block2[$j] ) { $cnt++; last; }
    }
    if($cnt == 0 ) { push (@savelines,$test); }
  } 
  push(@savelines,$separator);
  #find new block2 elements
  for(my $i=0;$i<=$#block2;$i++)
  { my $test=$block2[$i];
    $cnt=0;
    for(my $j=0;$j<=$#block1;$j++)
    { if($test eq $block1[$j] ) { $cnt++; last; }
    }
    if($cnt == 0 ) { push (@savelines,$test); }
  } 
  push(@savelines,$separator);
  return @savelines; 
}

# input text file ignore lines that begin with # or NULL lines
# and delete end of line beginning with #
# Returns @array of lines
sub arrayTXTfile
{ my $file=@_[0];
  my @lines;
  my $Ltmp=FileHandle->new; #	does not work with variable FH
  &openICS($Ltmp,$file);
  while(<$Ltmp>)
  { chop;
    next if(/^#/);	# comment
    $_=~s/#.*$//;	#trailing comment
    $_=~s/[\s]*$//;	#trailing space 
    $_=~s/^[\s]*//;	#leading space 
    next if(/^$/);	#null line
    push @lines,$_;
  }
  close $Ltmp;
  return @lines;
}

#
sub saveArray2TXTfile
{ my ($file,@vars)=@_;
  my $Ltmp=FileHandle->new;
  &openICS($Ltmp,">",$file);
  for( my $i; $i<=$#vars;$i++)
  { print $Ltmp $vars[$i],"\n";
  }
  close $Ltmp;
}

# delete one item in array referenced by index
sub deleteArrayIndex
{ my ($index,@array)=@_;
  return @array[0 .. $index-1, $index-$#array .. -1 ];
}

# deletes "" items in array 
sub deleteNullItems
{ my @array=@_;
  for(my $i=0;$i<=$#array;$i++)
  { if( $array[$i] eq "" )
    { @array=&deleteArrayIndex($i,@array);
      $i--;
    }
  }
  return @array;
}

# delete matching element in array
sub deleteElement
{ my ($element,@array)=@_;
  for( my $i=0; $i<=$#array;$i++)
  { if( $element eq $array[$i] )
    { $array[$i]="";
    }
  }
  @array=&deleteNullItems(@array);
}

# delete matching elements (\t separated) in array; lc and no_space test
sub deleteElements
{ my ($elements,@array)=@_;
  my @elements=split(/\t/,$elements);
  foreach my $element (@elements)
  { my $test= lc(&string_NoBlank($element)) ;
    for( my $i=0; $i<=$#array;$i++)
    { my $testarray= lc(&string_NoBlank($array[$i])) ;
      if( $testarray  =~ /$test/i )
      #if( $element eq $array[$i] )
      { 
	# print "YYY $test,$testarray YYY";
	$array[$i]="";
      }
    }
  }
  @array=&deleteNullItems(@array);
}

# replace matching element in array with replacement
sub replaceElement
{ my ($element,$replacement,@array)=@_;
  for( my $i=0; $i<=$#array;$i++)
  { if( $element eq $array[$i] )
    { $array[$i]=$replacement;
    }
  }
  @array=&deleteNullItems(@array);
}

sub deleteDuplicatesTab
{ my ($string)=@_;
  my @list=sort(split(/\t/,$string));
  for(my $i=0;$i<$#list;$i++)
  { if($list[$i] eq $list[$i+1])
    { $list[$i]="";
    }
  }
  @list=&deleteNullItems(@list);
  $string=join("\t",@list);
}
# returns @list from @array that has head $head. e.g., &selectHead($head,@array);
sub selectHead
{ my ($head,@array)=@_;
  my @out; $#out=-1;
  for( my $i=0;$i<=$#array;$i++)
  { if( $array[$i] =~ /^$head/)
    { push(@out,$array[$i]);
    }
  }
  return @out;
}

# adds to/updates/creates CGIform DBhash $db{$key} of $parmlist
sub addParmsDBhash
{ my ($db,$key,$parmlist)=@_;
  ${$db}{$key}=&makeDBParmString($db{$key},$parmlist);
}

sub DEBUG
{ my @var=@_;
  return();
  my $str="@var";
  $str=~m/^([^:]*:)/;
  my $head=$1;
  $str=~s/$head//;
  print &COLOR("green","DEBUG:").  &COLOR("orange","$head").  &COLOR("blue",$str),"<br>";
}

# interprets array of PARM=VAL strings into ${PARM}=VAL.
# Arrays can be assigned by: Array[1]=value
sub ParmValueArray
{ my @array=@_;
  foreach my $line (@array)
  { my ($parm,$value)=split(/=/,$line,2);
    $parm=~/([\w]+)(\[)([\d]+)(\])/;
    my $head=$1;
    my $i=$3;
    $value=~s/[\t]+/\t/g;
    if($i=~/\d/)
    { ${$head}[$i]=$value;
    }
    else
    { ${$parm}=$value;
    }
  }
}

#################################################################################
# $vAddress is a string composed of values for 
# ($City,$Street,$Address,$subAddress)=("Berkeley","Le Roy Ave","1643","#D");
# using $vAddressDelim as separators. $vAddressDelim is a visible character
# and $vAddress can be used as file name.
#
# vAddress definitions and routines:
$vAddressDelim="=";
$vAddressNames="Street,Address,SubAddress";
@vAddressNames=split(/,/,$vAddressNames);
$SelectvAddressNames="SelectStreet,SelectAddress,SelectSubAddress";
@SelectvAddressNames=split(/,/,$SelectvAddressNames);

sub vAddressFromArray # compose vAddress from its components
{ my @vAddress=&deleteNullItems(@_); # assume nulls are more detailed addresses
  if(!$vAddress[2]){ $vAddress[2]=""; }
  return join( $vAddressDelim, @vAddress );
}
#print &vAddressFromArray("Le Roy Ave","1643",""),"\n";

sub vAddress2Array # separates vAddress into components
{ my ($vAddressString)=@_;
  return split($vAddressDelim,$vAddressString);
}

#
# returns vAddress from DBrec
sub vAddressFromDBrec
{ my $rec=$_[0];
  my @col=split(/\t/, $rec);
  my $vAddress=&vAddressFromArray(
    $col[$DBcol{StreetName}],$col[$DBcol{StreetAddress}],$col[$DBcol{subAddress}] );
  return $vAddress;
}

# returns parcel vAddress from full vAddress
sub ParcelvAddress
{ my $address=$_[0];
  my @address=&vAddress2Array($address);
  $#address=1; #only first 2
  return(&vAddressFromArray(@address));
}

sub vAddressQ
{ my $test=$_[0];
  $test =~ s/[^=]//g; # test for 3 component address
  if($test ne "==") { return(0); }
  else { return(1); }
}

########################
sub openICSorDie
{ my ($fh,$mode,$file)=@_;
  if($mode!~/[><]/)
  { $file=$mode;
    $mode="<";
  }
  if($file!~/$ICSdir/)
  { $file="$ICSdir/$file";
  }
  #&DEBUG("openICSorDie: $file"
  my $status=open($fh,$mode,$file);
  if(!$status and $mode eq ">" ){ die ">>Cannot write to: $file "; }
  return $status;
}

sub openICS
{ my ($fh,$mode,$file)=@_;
  if($mode!~/[><]/)
  { $file=$mode;
    $mode="<";
  }
  if($file!~/$ICSdir/)
  { $file="$ICSdir/$file";
  }
#  &DEBUG("openICS: $file");
  my $status=open($fh,$mode,$file);
  return $status;
}

#
# tabVarAdd adds $item to $tabVar[tab separated list]
# returns [tab separated list]
#
sub tabListAdd
{ my ($tabvar,$item)=@_;
  my @tab=split(/\t/,$tabvar);
  push(@tab,$item);
  my $out=join("\t",@tab);
  $out;
}

#
# tabListDelete delete $item in $tabList[tab separated list]
# returns [tab separated list]
#
sub tabListDelete
{ my ($tabvar,$item)=@_;
  my @tab=split(/\t/,$tabvar);
  @tab=&deleteElement($item,@tab);
  my $out=join("\t",@tab);
  $out;
}
###########################################################
# CSV Subroutines
#
#returns one line from <CSV>
sub readCSVline
{ my $L=$_[0];	# filehandle ($L) as arguement 
  my $line=<$L>;
  # print "$line";
  chop $line;
  $line=&completeCSVline($L,$line);
  return $line;
}

# continues to read from CSV file <$L>
# reads <CSV> until even number of "s are in output 
# so to work around incompatibility between UNIX and CSV definition of lines,
# i.e. avoids UNIX problem with <CSV> lines that have embedded \n inbetween "s.
sub completeCSVline
{ my ($L,$line)=@_;
  my @c;
  my $n;
  while( )
  { $line=~s/\"\"/2_QUOTES/g; # embedded single "
    $n=@c=$line=~/\"/g;
    #	print "YY $n>>$line\n";
    if($n%2 == 0) { last; }
    else { $line.=<$L>; chop $line; }
  }
  $line=~s/2_QUOTES/\"\"/g;
  return $line;
}
#
# Prints columns in .csv form to <$L> from @data
#
sub printCSV
{ my ($L,@data)=@_;
  my $data=join("\",\"",@data);
  print $L "\"",$data,"\"\n";
}

sub PrintCol
{ my @col=@_;
  my $cols=join("\",\"",@col);
  print L3 "\"",$cols,"\"\n";
}

# substitute for quoted strings
sub STRG
{ local ($i) = @_;
  return "STR$i.X";
}

# returns an array from a quoted csv record 
sub STRG4String
{ my $t=$_[0];
  local $ii,$SS,@str,$ss,$j,$i,@str,@rec;
  $#str=-1;
  for($i=0 ; $t =~ m/"/ ; $i++)		#do until no "'s
  { $ss=&STRG($i);			#replace name variable
    $t =~ s/\"([^"]*)\"/$ss/;		#find pair of "'s
    push @str,$1;
  }
  @rec=split(/,/,$t);
  for($j=0;$j<$i;$j++)
  { $ss=$str[$j];
    $SS=&STRG($j);
    for($ii=0;$ii<=$#rec;$ii++)
    { $rec[$ii]=~s/$SS/$ss/;
      # Put rec[] edits here.
      $rec[$ii]=~s/^[\s]*//; 	# remove leading blanks
      #	$rec[$ii]=~s/\n//g; 	# remove new line 
    }
  }
  return @rec;
}

1;
