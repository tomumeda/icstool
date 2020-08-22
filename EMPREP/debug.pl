#!/usr/bin/perl
#require "subCommon.pl";
#require "subICSWEBTool.pl";
#require "subDamageReport.pl";
#use lib "/Users/Tom/Sites/EMPREP/ICSTool/PL";
use CGI qw/:standard :html3/;


print "\n<br> CONTEXT_DOCUMENT_ROOT >>>>",$ENV{CONTEXT_DOCUMENT_ROOT },"\n";

print header();
print start_html(-title=>'SVG test', -style=>{ -src=>"ICSTool.css" ,-code=>$newStyle });

#print "\n<br>>>INC>>>",join("\n<br>",%INC);
print "\n<br>>HOME>>>",$ENV{HOME},"\n";
print "\n<br> ENV keys>>>>",join("\n<br>",keys %ENV),"\n";
print "\n<br> CONTEXT_DOCUMENT_ROOT >>>>",$ENV{CONTEXT_DOCUMENT_ROOT },"\n";
print "\n<br> DOCUMENT_ROOT  >>>>",$ENV{DOCUMENT_ROOT},"\n";

print "\n<br>>HTTP_HOST>>>",$ENV{SCRIPT_NAME},"\n";

$ENV{ICSdir}="/Users/Tom/Sites/EMPREP/ICSTool";
$dbfile=$ENV{ICSdir};
print "\n<br> >dbfileICS>>>",$dbfile,"\n";

$documentroot=$ENV{DOCUMENT_ROOT};
print "\n<br>>>DOCUMENT_ROOT>>",$documentroot,"\n";
$documentroot=$ENV{SERVER_NAME};
print "\n<br>>>SERVER_NAME>>",$documentroot,"\n";

$dbfile=$ENV{SCRIPT_NAME};
print "\n<br> >dbfile>>>",$dbfile,"\n";

@http_root=split('/',$dbfile);
pop(@http_root);
#shift(@http_root);
$http_root=join("/",@http_root);
print "\n<br>>>>http_root>>",$http_root;

@dbfile=split('/',$dbfile);
$dbfile=pop(@dbfile);
$dbfile=shift(@dbfile);

$dbfile=join("/",@dbfile);
print "\n<br>dbfile>>>",$dbfile,"<br>\n";

$type="DBmaster";
$dbfile="$dbfile/DB/$type.db";
$dbfile=~s/~Tom/\/Users\/Tom\/Sites/;
print "\n<br> >>>>dbfileXX>>>",$dbfile,"<br>\n";

# #tie(%{$type},"DB_File",$dbfile,O_RDWR|O_CREAT,0777)
#or die "Check permissions: abort at tie $dbfile";
#&TIE(DBmaster);

print "\n<br>>>>>>>>ENV:<br>\n";
@list=();
foreach $k (keys %ENV )
{ push @list,"$k >> $ENV{$k}";
}
print join("\n<br>",sort(@list));
print end_html;

