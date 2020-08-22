#!/usr/bin/perl
require "subCommon.pl";
require "subICSWEBTool.pl";
#use Text::Markdown;

#################################
# Definitions for LOCAL starts
&Eval_QUERY_STRING;
if(!$ICSdir)
{ &setICSdir;
}
$BlockSeparator="-----------------------------------";

$OrgName=$ENV{"QUERY_STRING"};
$OrgName=~s/OrgName=(.*)/$1/;
$OrgName="EmPrep";

foreach $f (<Info/*.info>)
{ my @f=split(/[\/\.]/,$f);
  my $info=&ShowInfoX("$f");
  open L1,">$f[0]/$f[1].html";

  my $out=<<___EOR;
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="../MemberInformation.css">
</head>
<body>
$info
</body>
</html>
___EOR
print L1 $out;

}


sub ShowInfoX
{ my $file=$_[0];
  my @type,@line,@list,$out;
  $out="";

  if( ! -e "$file" ) { print &COMMENT("No Info file: $file<br>"); return; }
  &openICS(L,$file);
  while(<L>)
  { next if(/^\s*$/); # NO blank lines
    chop;
    if( $_ =~ /^:(.*):$/ ) 
    { push @type,$1; 
      if( $type[$#type] eq "CONTENT" )
      { 
	$out.= "\n<p>";
      }
      if( $type[$#type] eq "ENDLIST" )
      { pop @type; pop @type;
	$out.= "\n</ul>\n</ul>";
      }
      if( $type[$#type] eq "LIST" )
      { $out.= "\n<ul>";
      }
      next;
    }
    push @line,$_;
    if( $type[$#type] eq "TITLE" )
    { $out.= "<hr>\n<h4>";
      $out.=pop @line;
      $out.=" Info\n</h4>";
      pop @type;
    }
    if( $type[$#type] eq "CONTENT" )
    { $out.= "\n";
      $out.=pop @line;
    }
    elsif( $type[$#type] eq "LIST" )
    { $out.= "\n<li>";
      $out.=pop @line;
      $out.="</li>";
    }
  }
  if( $type[$#type] eq "CONTENT" ) { $out.= "\n</p>\n"; }
  $out.= <hr>;
}
