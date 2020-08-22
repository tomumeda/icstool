#!/usr/bin/perl
#usage: msearch.j 
#$list=`find \. -name \*.m -print`;
use Term::ANSIColor;

use File::Find;
# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;
sub wanted;

# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, 'find', '.');
sub wanted { /^.*\.{pl,j}\z/s && push(@files,"$name");
}
################## END: find2perl 
@files=<*.{pl,j}>;
#die join("\n",@files);

$pat=$ARGV[0];

print colored("#####################\n",'green');
foreach $file (@files)
{
  $file=~s/ /\\ /g;
  $file=~s/&/\\&/g;
  #print "$file $pat\n";
  $greplist=`grep $pat $file`;
  $greplist=~s/($pat)/PAT-patColor<$1>PAT-/gi;
  @grep=split(/\n/,$greplist);
  #print ">@grep: $#grep\n";
  if($#grep>=0)
  { print colored($file,'yellow'),"\n";
    #print colored($greplist,"blue"),"\n";
    for($ig=0;$ig<=$#grep;$ig++)
    { @list=split(/PAT-/,$grep[$ig]);
      for($i=0;$i<=$#list;$i++)
      { $item=$list[$i];
	if($item=~/patColor/)
	{ $coloritem=$item;
	  $coloritem=~s/^(.*)patColor<(.*)>(.*)/$2/;
	  $pre=$1;
	  $pre=~s/;/;/g;
	  $post=$3;
	  print $pre.colored($coloritem,'red').$post;
	}
	else
	{ print "$item";
	}
      }
      print "\n";
    }
    print "\n";
  }
}

#print @out;

