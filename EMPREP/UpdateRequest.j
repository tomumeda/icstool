#!/usr/bin/perl 
$host= `hostname` ;
# Is postfix running ?
if( $host =~ /pro1/ ) #
{ $test= `ps -alxw | grep postfix | grep master` ;
  if($test !~ /libexec/){ die "NEED TO RUN 'postfix start'" ; }
}
# hostname must be Pro1 for sendmail to work
#die "$host <hostname needs to be Pro1 " if ( $host ne "pro1\n" and $host ne "Pro1\n" );
# $sendGreylist=1;  #1-> sends to greylist only <<UNCOMMENT tp semd tp greylist only
# CHECK tail /var/log/mail.log
# 
# Mail location: Pro1:/Users/Tom/Library/Mail/V2/IMAP-northside.emprep@imap.gmail.com/[Gmail].mbox/Spam.mbox/F0755B93-6E2D-44DB-9FE0-23FF8693A02E/Data/1/4/Messages
#
#	On Raspian if the mail queue seems stuck try:
#		sudo service postfix restart
######################
require "subMemberDB.pl";
require "googleForm.pl";
#######################
##############################
&initialization;
&Set_timestr; 
$dottedline="-"x33;

&TIE( @DBrecLabels );
open(LLOG,">>UpdateRequest.log");
open(LEMAIL,">xemail.d");
open(LNAMES,">xnames.d");
open(LADDRESS,">xaddress.d");
$greys=`cat greylist.d`;
@greys=split(/\n/,$greys);
foreach my $item (@greys)
{ if($item !~ /^#/) { push @greylist,$item; }
}

foreach $key (sort keys %DBmaster)
{ # print "<<$key>>\n"; 
  &SetDBrecVars($key);
  print "DB memberName: $LastName $FirstName\n";

  if($InvolvementLevel !~/Active/i )
  { print "\t\t\t>>>> $InvolvementLevel: $LastName $FirstName\n"; 
    next;
  }
  #########
  # next if( $FirstName!~m/Takato/ ); ## UNCOMMENT FOR only me TEST

  print " 			Processing: $LastName $FirstName\n"; 
  #########
  $problem="northside.emprep\@gmail.com";

  $replyto="northside.emprep\@gmail.com";
  $replyto="northside.emprep\@gmail.com,emprep-owner\@northside-emprep.org";

  $from="northside.emprep\@gmail.com";

  @to=split(/,/,$EmailAddress);
  $to=$to[0];
  next if ( !$to );

  if($sendGreylist==1)
  { next if(&MemberQ(@greylist,$to) == -1);
  }

  print "\t\t\t>>>>>>>>>>Mailing to: $to\n";
  
  # next;  # COMMENT to actually send 
  # $to="takato\@pacbell.net"; ## UNCOMMENT for all email to one recipient TEST

  print LEMAIL "$to = $LastName, $FirstName\n";
  print LNAMES "$LastName, $FirstName = $to\n";
  print LADDRESS "$StreetName $StreetAddress, $LastName, $FirstName = $to\n";
  print LLOG "$UXtime($timestr): $LastName, $FirstName = $to\n";

  my $htmlform=&googleForm;
  $htmlform=uri_escape($htmlform);
  $htmlform=~s/%(26|2B|2C|2F|3A|3D|3F|40)/chr(hex($1))/eg;
  $htmlform=~s/%20/+/g; # space to +

  #	die $htmlform; # UNCOMMENT to TEST $htmlform

  $textform=&dataListHTML;
  if( $LastName eq "Umeda" )
  { 
    # die "textfrom>> $textform\n";
  }

  open(LMAIL,">STDOUT");
  open(LMAIL,"|/usr/sbin/sendmail -t -f $problem > sendmail.log"); # COMMENT for emailing TEST

$specialrequest=
"======== ANNOUNCEMENT =========
If you are a high-risk person who needs help getting supplies from the stores let us know.
================================
";
undef $specialrequest;

  print LMAIL<<___EOR;
Content-type: text/plain
Reply-to: $replyto
From: $from
To: $to
Subject: [EmPrep] Member Information Update 

Hello $FirstName $LastName, 

$specialrequest
We periodically review member information in our database for accuracy.  Please review your current information below.  
$dottedline
$textform

If you need update your information, please use the form at:

http://icstool.tupl.us:8081?mode=MemberInformation&usertype=SingleUser&LastName=$LastName&FirstName=$FirstName

using:  LOGIN / PASSWORD = emprep / user101

$dottedline

A spreadsheet (.csv) of the database may be downloaded using the Download link provided.

You also can reply to this email with your updates to ($replyto) along with any questions or comments you may have.

Thank you,
Tom Umeda
$from

___EOR
  close(LMAIL);

  if( $LastName eq "Umeda" )
  { #print ">>>> $textform\n";
    #die;
  }
}

&UNTIE( @DBrecLabels );
