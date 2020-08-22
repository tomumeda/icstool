#!/usr/bin/perl
#################################
# PUT IN STARTUP.pl
use Fcntl;
use DB_File;
use Time::Local;
use URI::Escape;
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;
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
{ $q = new CGI;
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

# hiddenParam passes parameters in $strlist as hidden parameter 
sub hiddenParam
{ my ($q,$strlist)=@_; #comma separated list; array values indicated by @name
  #&DEBUG("hiddenParam: $strlist");
  my @strparam=split(/,/,$strlist);
  for( my $i=0; $i<=$#strparam; $i++ )
  { my $name=$strparam[$i];
    if( $name =~ /^@/ ) # ARRAY variable
    { $name =~ s/^@//;
      #$q->delete($name);
      my @value=&uniq( $q->param($name) ); #DEBUG $q->hidden oddity
      if( @value )
      { print $q->hidden(-name=>"$name",-default=>[@value]);
      }
    }
    else
    { my $value=$q->param($name);
      #&DEBUG("hiddenParam: $name : $value");
      if( $value )
      { ##
	#  $q->delete($name); #?? TEST
	print $q->hidden($name,$value); # 2013
      }
    }
  }
}

sub hiddenParamAll
{ my $q=$_[0];
  my $str=join(',',$q->param);
  &hiddenParam($q,$str);
}

sub var2param
{ my ($q,@vars)=@_;
  foreach my $name (@vars)
  { $q->param($name,${$name});
  }
}

sub param2var
{ my ($q)=@_;
  @params=$q->param;
  for(my $i=0; $i<=$#params; $i++)
  { my $name=$params[$i];
    my @val=$q->param( $name );
    { if($#val>0)
      { @{ $name } = @val;
      }
      else
      { ${ $name } = $val[0];
      }
    }
    #	print "<br>>>param $name=${$name}";
  }
}

sub param2varNoNullVar
{ my ($q)=@_;
  @params=$q->param;
  for(my $i=0; $i<=$#params; $i++)
  { 
    my $name=$params[$i];
    my @val=$q->param( $name );

    { if($#val>0)
      { @{ $name } = @val;
      }
      elsif($val[0] ne "")
      { ${ $name } = $val[0];
      }
      else
      { undef ${ $name }
      }
    }
    #	print "<br>>>param $name=${$name}";
  }
}

sub SetUrls
{ 
  $external_url      = $q->url(-path_info => 1);
  my $current_url      = $q->url();
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

# Jumps to a label in ../../labels.pl
# NEEDS to be before call to header
sub JumpToLabel
{ do "../../labels.pl";
  my ($label)=@_;
  $url=$HomeUrl;
  $url.=$external_labels{"$label"} ;
  print $q->redirect(-URL=>"$url");
  exit;
}

################################################
# Subroutines
sub TIE		#If this does not seem to work in WEB calls (CHECK permissions)
{ my @list=@_;
  my $type;
  foreach $type (@list)
  { if($type=~/\w/)
    { tie(%{$type},"DB_File","$ICSdir/DB/$type.db",O_RDWR|O_CREAT,0666,$DB_BTREE) #TEST
	or die "!!!! Check DB permissions: abort at tie: $ICSdir/DB/$type :: $ICSdir ::  @list"; # THIS WORKS
    }
  }
}

sub UNTIE
{ my @list=@_;
  foreach $type (@list) { untie %{$type}; }
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

#POD default submit of action 
sub SubmitActionList
{ local(@label)=@_;
  $q->delete("action"); # DEBUG $q not defined
  foreach my $lab (@label)
  #{ print hr(),$q->submit('action',$lab);
  { print hr();
    if( $lab =~ m/Cancel/ )
    { print $q->submit(-name=>'action',-value=>$lab,-id=>'Cancel'); #TEST
    }
    else
    { print $q->submit('action',$lab); 
    }
  }
}

sub SubmitActionListWithComments
{ local(@label)=@_;
  local($lab);
  foreach $lab (@label)
  { print hr(),$q->submit('action',$lab), " $actioncomment{$lab} <BR>";
  }
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

sub HTMLMemberInfoHeader
{ print $q->header(-type=>'text/html',-charset=>'utf-8');
  print <<___EOR;
<!DOCTYPE html >
<html lang="en-US" xml:lang="en-US">
<head>
<title>Member Information Form</title>
<link rev="made" href="mailto:takato%40pacbell.net" />
<link rel="stylesheet" type="text/css" href="MemberInformation.css" />
<link rel="icon" href="http:./next.png" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
___EOR
}

sub HTMLHeader
{ print $q->header(-type=>'text/html',-charset=>'utf-8');
  print $q->start_html(-title=>'ICC',
        -author=>'takato@pacbell.net',
	-style=>{'src'=>"ICSTool.css"});
}

sub xHTMLHeader
{ print $q->header(-type=>'text/html',-charset=>'utf-8'); #NEEDED
  print <<___EOR;
<!DOCTYPE html >
<html lang="en-US" xml:lang="en-US">
<head>
<title>ICSTool</title>
<link rev="made" href="mailto:takato%40pacbell.net" />
<link rel="stylesheet" type="text/css" href="ICSTool.css" />
<link rel="icon" href="http:./next.png" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
___EOR
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
  &openICS(Ltmp,$file);
  while(<Ltmp>)
  { chop;
    next if(/^#/);	# comment
    $_=~s/#.*$//;	#trailing comment
    $_=~s/[\s]*$//;	#trailing space 
    $_=~s/^[\s]*//;	#leading space 
    next if(/^$/);	#null line
    push @lines,$_;
  }
  close Ltmp;
  return @lines;
}

#
sub saveArray2TXTfile
{ my ($file,@vars)=@_;
  &openICS(Ltmp,">",$file);
  for( my $i; $i<=$#vars;$i++)
  { print Ltmp $vars[$i],"\n";
  }
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

# loads CGI $file into $q namespace,
sub loadCGIfile
{ my ($file)=@_; 
  &openICSorDie(FILE,$file);
  my $qfile = CGI->new(FILE);
  close(FILE);
  return($qfile);
}

# save $q namespace into CGI $file 
sub saveCGIfile
{ my ($q,$file)=@_; 
  &openICSorDie(FILE,">",$file);
  $q->save(FILE);
  close(FILE);
}

# overwrites $parm with $value to CGI $file
sub newCGIfile
{ my ($file,@parmvalue)=@_; #pairs of parm,value
  my $qq = CGI->new;
  $qq->delete_all;
  for(my $i=0; $i<$#parmvalue;$i+=2)
  { my $parm=$parmvalue[$i];
    my $value=$parmvalue[$i+1];
    $qq->param($parm,$value);
  }
  &openICSorDie(FILE,'>',$file);
  $qq->save(FILE);
  close(FILE);
}

# add $parm with $value to CGI $file
sub addCGIfile
{ my ($file,@parmvalue)=@_; #pairs of parm,value
  &openICSorDie(FILE,$file);
  my $qq = CGI->new(FILE);
  for(my $i=0; $i<$#parmvalue;$i+=2)
  { my $parm=$parmvalue[$i];
    my $value=$parmvalue[$i+1];
    $qq->param($parm,$value);
  }
  close(FILE);
  &openICSorDie(FILE,'>',$file);
  $qq->save(FILE);
  close FILE;
}

# appends $parm with $value to CGI $file
sub logCGIfile
{ my ($file,@parmvalue)=@_; #pairs of parm,value
  my $qq = new CGI;
  for(my $i=0; $i<$#parmvalue;$i+=2)
  { my $parm=$parmvalue[$i];
    my $value=$parmvalue[$i+1];
    $qq->param($parm,$value);
  }
  my $append=">";
  if( -e $file) { $append=">>"; }
  &openICS(FILE,$append,$file);
  $qq->save(FILE);
  close FILE;
}

# make CGIfile formatted string from parmlist. DBParmList is updated with new parms form parmlist.
sub makeDBParmString
{ my ($DBParmList,$parmlist)=@_;
  my @parms=split(/[,;]/,$parmlist);
  if(!$DBParmList) {$DBParmList="=\n";}
  &DEBUG("makeDBParmString:0: $parmlist  >>$teamstatus ");
  # delete parms from DBParmList if in $parmlist; add parms from DBParmList 
  my $new="";
  for(my $i=0; $i<=$#parms;$i++)
  { my $parm=$parms[$i];
    if($parm=~/^@/) # Array
    { $parm=~s/^@//;
      $DBParmList=~s/^$parm=(.*)\n//g; # delete existing $parm
      if(!@{$parm}) # incase @parm not assigned look for it in $q->
      { &assignVarFromQ($q,"\@$parm");
	&DEBUG("makeDBParmString: assigned from Q:\@$parm:@{$parm} ");
      }
      if(my @xparm=@{$parm})
      { foreach my $value ( @xparm ) { $new.="$parm\=$value\n"; }
       	&DEBUG("makeDBParmString:@xparm <<:$new ");
      }
    }
    else
    { $DBParmList=~s/^$parm=(.*)\n//g; # delete existing $parm
      if(!${$parm}) # in case $parm not assigned look for it in $q->
      { &DEBUG("makeDBParmString: assigning:$parm ");
        &assignVarFromQ($q,$parm);
      }
      if(${$parm})
      { $new.="$parm=${$parm}\n";
       	&DEBUG("makeDBParmString:2<<:$new ");
      }
    }
  }
  &DEBUG("makeDBParmString:final:$new:$DBParmList: ");
  $DBParmList=$new.$DBParmList;
  return($DBParmList);
}

# adds to/updates/creates CGIform DBhash $db{$key} of $parmlist
sub addParmsDBhash
{ my ($db,$key,$parmlist)=@_;
  ${$db}{$key}=&makeDBParmString($db{$key},$parmlist);
}

# assigns global parameters from ($q,$parmlist)
sub assignVarFromQ   
{ my ($q,$parmlist)=@_;
  my $qq=&selectNamespaceParam($q,$parmlist);
  my @parmlist=split(/[,;]/,$parmlist);
  foreach $parm (@parmlist)
  { if($parm=~/^@/)
    { $parm=~s/^@//;
      @{ $parm }=$qq->param($parm);
      &DEBUG("assignVarFromQ: @{$parm}");
    }
    else
    { ${ $parm }=$qq->param($parm);
    }
  }
}

# selectNamespaceParam returns namespace of parameters in $strlist 
sub selectNamespaceParam
{ my ($q,$strlist)=@_; #comma separated list; array values indicated by @name
  my $qq=new CGI;
  $qq->delete_all;
  my @strparam=split(/,/,$strlist);
  #print "\n selectNamespaceParam: @strparam";
  for( my $i=0; $i<=$#strparam; $i++ )
  { my $name=$strparam[$i];
    if( $name =~ /^@/ ) # ARRAY variable
    { $name =~ s/^@//;
      my @value=&uniq( $q->param($name) ); 
      #print "\n selectNamespaceParam: @value";
      if( @value )
      { $qq->param(-name=>"$name",-default=>[@value]);
      }
    }
    else
    { my $value=$q->param($name);
      if( $value )
      { $qq->param($name,$value); 
      }
    }
  }
  return $qq;
}

# saves $parm to CGI $file
sub saveParmsCGIfile
{ my ($q,$file,$parmlist)=@_;
  #print "##: ($q,$file,$parmlist)";
  my $qq=&selectNamespaceParam($q,$parmlist);
  &openICS(FILE,'>',$file);
  $qq->save(FILE);
  $qq->delete_all;
  close(FILE);
}

# add/replace $parm to CGI $file
sub addParmsCGIfile
{ my ($q,$file,$parmlist)=@_; 
  my $qq = new CGI;
  $qq->delete_all;
  $append=">";
  if( -e "$ICSdir/$file" ) # LOAD original data
  { &openICSorDie(FILE,$file);
    $qq = CGI->new(FILE);
  }
  &DEBUG("addParmsCGIfile:parmlist: $parmlist ");
  my @parmlist=split(/,/,$parmlist);
  for( my $i=0; $i<=$#parmlist; $i++ )
  { my $name=$parmlist[$i];
    if( $name =~ /^@/ ) # merge ARRAY variables
    { $name =~ s/^@//;
      my @valueqq=$qq->param($name);
      my @value=$q->param($name);
      &DEBUG("addParmsCGIfile: (@value)(@valueqq)");
      my @value=&uniq((@value,@valueqq));
      if( @value )
      { $qq->param(-name=>"$name",-default=>[@value]);
      }
    }
    else
    { my $value=$q->param("$name");
      if( $value )
      { $qq->param("$name",$value); 
      }
    }
  }
  &openICSorDie(FILE,$append,$file);
  $qq->save(FILE);
  close(FILE);
}

# saves $parm to CGI $file
sub logParmsDB
{ my ($db,$key,$parmlist)=@_;
  my $append;
  my $qq=&selectNamespaceParam($q,$parmlist);
  $db{$key}.=" ";
}

# saves $parm to CGI $file
sub logParmsCGIfile
{ my ($q,$file,$parmlist)=@_;
  my $append;
  my $qq=&selectNamespaceParam($q,$parmlist);
  $append=">";
  if( -e "$ICSdir/$file") { $append=">>" }
  &openICS(FILE,$append,$file);
  $qq->save(FILE);
  close(FILE);
  $qq->delete_all;
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

### returns vAddress in $q->$SelectvAddressNames="SelectStreet,SelectAddress,SelectSubAddress";
#
sub vAddressFromParam
{ my $q=@_[0];
  my $name,@vAddress;
  $#vAddress=-1; # my does not clear this variable
  for $name ( @SelectvAddressNames )
  { # print "N:$name: ", $q->param($name),":n:";
    push(@vAddress, $q->param($name));
  }
  #   print "==@vAddress:<br>";
  return &vAddressFromArray(@vAddress);
}

###
### sets $q->  vAddress and compoents
sub vAddressToParam # add vAddress to $q->param
{ my ($q,$vAddressString)=@_;
  $q->param(vAddress,$vAddressString);
  my @vAddress=&vAddress2Array($vAddressString);
  for(my $i=0;$i<=$#vAddress;$i++)
  { if($vAddress[$i])
    { $q->param($SelectvAddressNames[$i],$vAddress[$i]);
    }
  }
  return $q;
}

# returns parcel vAddress from full vAddress
sub ParcelvAddress
{ my $address=$_[0];
  my @address=&vAddress2Array($address);
  $#address=1; #only first 2
  return(&vAddressFromArray(@address));
}

# to set address from dialog or input. Return 1 if vAddress is complete
sub inputAddress
{ my $q=$_[0];
  # dialog input values
  my $street = $q->param("SelectStreet" );
  my $address = $q->param("SelectAddress" );
  my $subaddress = $q->param("SelectSubAddress" );
  my $vAddress = $q->param("vAddress" ); # complete vAddress
  if($vAddress)
  { ($street,$address,$subaddress)=&vAddress2Array($vAddress);
    $q->param("SelectStreet",$street);
    $q->param("SelectAddress",$address);
    $q->param("SelectSubAddress",$subaddress);
  }
  elsif($street and $address)  # set vAddress
  { $vAddress=&vAddressFromArray($street,$address,$subaddress);
  }
  my $NewStreetName=$q->param("NewStreetName"); #if new input set SelectStreet
  if( $NewStreetName and $NewStreetName ne "New Street Name") 
  { $street=$NewStreetName;
    $q->delete("SelectStreet");
    $q->param("SelectStreet",$street );
  }
  my $NewAddress=$q->param("NewAddress"); #if new address set SelectAddress
  if( $NewAddress and $NewAddress ne "New Address") 
  { $address=$NewAddress;
    $q->delete("SelectAddress");
    $q->param("SelectAddress",$address );
    if( my $NewSubAddress=$q->param("NewSubAddress") and $NewSubAddress ne "sub Address") 
    { $subaddress=$NewSubAddress;
      $q->param("SelectSubAddress",$subaddress );
      $address=&vAddressFromArray($address,$subaddress);
    }
    #append in street database
    my @address=&arrayTXTfile("AddressesOn/$street");
    # ADD street name to list
    my $f = "AddressesOn/$street"; 
    if( ! -e "$ICSdir/$f" ) 
    { &openICS(Ltmp,">",$f);
    }
    &saveArray2TXTfile("AddressesOn/$street",&uniq(@address,"$address=$subaddress"));
    $vAddress=&vAddressFromArray($street,$address,$subaddress);
  }
  if( $vAddress )
  { $q->param("vAddress",$vAddress );
    return("COMPLETE");
  }
  else
  { return("NOT Complete");
  }
}
#################################################################################

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
# Prints columns in .csv form
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
      $rec[$ii]=~s/^[\s]*//; 	#remove leading blanks
      $rec[$ii]=~s/\n//g; 	#remove new line 
    }
  }
  return @rec;
}

1;
