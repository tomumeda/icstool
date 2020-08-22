#!/usr/bin/perl 
$host= `hostname` ;
# Is postfix running ?
if( $host =~ /pro1/ ) #
{ $test= `ps -alxw | grep postfix | grep master` ;
  #  if($test !~ /libexec/){ die "NEED TO RUN 'postfix start'" ; }
}
######################
require "subMemberDB.pl";
#######################
##############################
&initialization;
$dottedline="-"x33;

&TIE( @DBrecLabels );
open(LLOG,">>Welcome.log");
open(LEMAIL,">>Welcome.email.d");
open(LNAMES,">>Welcome.names.d");
print LEMAIL "$timestamp\n";
print LNAMES "$timestamp\n";
########################################33
$list=<<___EOR;	# TAB separated
#Umeda	Takato(Tom)	takato\@pacbell.net
Miu	Kenneth	kenmiu2010\@gmail.com
___EOR
@list=split(/\n/,$list);
#####################33
foreach $key (@list)
{ next if($key =~ m/^#/);
  ($LastName,$FirstName,$EmailAddress)=split(/\t/,$key);
  #  next if( $FirstName!~m/Takato/ ); ## UNCOMMENT FOR only me TEST
  print " Processing: $LastName $FirstName\n"; 
  ########################
  $problem="northside.emprep\@gmail.com";
  $replyto="northside.emprep\@gmail.com";
  $replyto="northside.emprep\@gmail.com,emprep-owner\@northside-emprep.org";
  $from="northside.emprep\@gmail.com";

  @to=split(/,/,$EmailAddress);
  $to=$to[0];
  next if ( !$to );
  print "\t\tMailing to: $to\n";
  
  # next;  # COMMENT to actually send 
  # $to="takato\@pacbell.net"; ## UNCOMMENT for all email to this recipient TEST

  print LEMAIL "$to = $LastName, $FirstName\n";
  print LNAMES "$LastName, $FirstName = $to\n";
  print LLOG "$UXtime($timestr): $LastName, $FirstName = $to\n";

  open(LMAIL,">STDOUT");
  open(LMAIL,"|/usr/sbin/sendmail -t -f $problem > sendmail.log"); # COMMENT for STDOUT TEST

  print LMAIL<<___EOR;
Content-type: text/plain
Reply-to: $replyto
From: $from
To: $to
Subject: [EmPrep] Welcome to the Northside EmPrep Neighborhood Group

Hello $FirstName $LastName, 

Welcome to the Northside EmPrep Neighborhood Group.  
I hope you will find this group valuable for your household safety,
as well as a means of meeting your neighbors.

Please add yourself to the group by providing your name, address, and email address
at the form at:

http://icstool.tupl.us:8081?mode=MemberInformation
using:  UserName / Password = emprep / user101

and click on the 'NewName' button.

Or if you would like, you can reply to this email with your infomation
and we will add you to the neighborhood database.

----
The Northside EmPrep WEB site can be found at:

http://northside-emprep.org

which has information about the Northside EmPrep Neighborhood 
and links to a number of resources related to emergency preparedness.

----
If you have any questions or comments please do not hestitate to contact me.

----
I am looking forward to meeting you. 
Thank you,
Tom Umeda
$from
510-761-2280
___EOR
  close(LMAIL);

}

