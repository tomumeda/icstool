#!/usr/bin/perl

# load data
$name="OrganizationChartOperations";
open L,"Lists/$name.txt";
while(<L>)
{ next if(/^#/); 
  chop;
  s/(\<.*\>)//; #remove attribute field
  push(@line,$_);
  $val=$1;
  $key=$_;
  $key=~s/^[\s]*//;
  push(@attributes,( $key,$val));
}

sub addValue
{ my $v = "$val; ";
  my $ov = $value{$key};
  $value{$key} = $ov.$v;
}
sub plainKey
{ $key=~s/^[\s]*//;
}

# process
$key=$line[0];  # initial head
&plainKey;
push(@keys,$key);
for($il=1;$il<=$#line;$il++)
{ $_=$line[$il]; 
  /(\t*)\w/; $ntab=length($1);
  $val=$_;
  $val=~s/[\t]*//g;
  #look ahead key adjust
  $line[$il+1] =~ /(\t*)\w/; $ntabnext=length($1);
  if ( $il == $#line ) { $ntabnext = $ntab; }
  if($ntabnext > $ntab )
  { &addValue;
    $key=$_;
    &plainKey;
    push(@keys,$key);
  }
  elsif($ntabnext < $ntab )
  { &addValue;
    $dtab=$ntab-$ntabnext;
    for(my $i=0;$i<$dtab;$i++)
    { $key=pop(@keys);
      $key=@keys[$#keys];
    }
  }
  else
  { &addValue;
  }
}

#################
sub makeTree
{ my ($title,$sep,$level) = @_;
  my $list=$value{$title};
  my @list=split(/; /,$list);
  my $out;
  my $width=$maxwidth/(($#list+1)>0?($#list+1):1)/4;
  if ($#list>=0 and $level<=$maxlevel)
  { 
    my $form= " >{\\centering}m{$width cm} | ";
    if( $level > 0 ){ $form=~s/\|\s*$//;}

    $out = "\n\\begin{tabular} { $form }\n { $title }";
    my $subwidth=$width/($#list+1)/4;
    $form= " >{\\centering}m{$subwidth cm} | " x ($#list+1);
    #chop $form; chop $form;
    $form=~s/\|\s*$//;
    $out.= "\n \\\\ \n\\begin{tabular}{ $form  }\n ";
  for(my $i=0;$i<=$#list;$i++)
  { $out .= &makeTree($list[$i]," & ",$level+1);
  }
  $out =~ s/\&[\s]*$//;
  $out.="\n\\end{tabular} \n";
  $out.="\n\\end{tabular} $sep \n";
}
else
{ $out= "$title $sep\n";
}
return $out;
}

$maxlevel=2;
$maxwidth=10;
$table=&makeTree($line[0],"",0);

for($i=0;$i<=$#attributes;$i+=2)
{ my $target=$attributes[$i];
  my $sub=$attributes[$i+1];
  my $type="OrgTable"; #change for different substitution
  $sub=~ /$type\[([^\]]*)\]/;
  $sub=$1; 
  if( $sub )
  { $table=~s/$attributes[$i]/$sub/;
  }
}
open L,">../../include/$name.tex";
print L $table;
