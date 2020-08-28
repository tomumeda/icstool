#!/usr/bin/perl
do "../PL/subCommon.pl";
use File::Copy;
my @file = <../../include/*.tex>;

@rolesNN=&arrayTXTfile("../Lists/Roles.txt");
@roles= map {  @tmp=split(/\t/,$_); $tmp[0]  } @rolesNN;
@multi= map {  @tmp=split(/\t/,$_); $tmp[2]  } @rolesNN;

for($i=0;$i<=$#roles;$i++)
{ $role=$roles[$i];
  print "$role\n";
  $role=~s/\s//g;
  # copy  "../../include/$role.tex","$role.tex"; # Uncomment in import files.
}
for($i=0;$i<=$#roles;$i++)
{ $role=$roles[$i];
  print "$role\n";
  $role=~s/\s//g;
  undef $title; undef @head; undef @list;
  $ListItems=0;
  open L,"$role.tex";
  while(<L>)
  { chop;
    if( $_ =~ /\\include/ ) {  next; }
    if( $_ =~ /\\label/ ) {  next; }
    if( $_ =~ /Responsibilities:/ ) {  next; }
    if( $_ =~ /__INPUT/ ) {  next; }
    if( $_ =~ /__SECT4{\s*\\*\w* (.*)$/ ) { $title=$1; next; }
    if( $_ =~ /__SECT5{\s+(.*)$/ ) { $title=$1; next; }
    if( $_ =~ /\\begin/ ) {$ListItems=1; $_=":LIST:\n"; }
    if( $_ =~ /\\end/ ) 
    { $ListItems=0; $_=":ENDLIST:\n"; 
      push @list,$_; 
      next;
    }
    $_ =~ s/\\item //;
    $_ =~ s/\\//g;
    $_ =~ s/%.*$//;
    $_ =~ s/([a-z])([A-Z])/$1 $2/g;
    if($ListItems eq 1 ) { push @list,$_; }
    else { push @head,$_; } 
  }
  open L1,">$role.info";
  print L1 ":TITLE:\n$title";
  print L1 "\n:CONTENT:\n",join("",@head);
  print L1 "\n",join("\n",@list);
}

