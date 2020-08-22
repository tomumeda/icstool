#!/usr/bin/perl
# sets permission to RW of all interactive files
$dir=`find . -type d -print `;
@dirs=split(/\n/,$dir);
chmod 0777, @dirs;

foreach $d (@dirs) 
{ push @f, <$d/*>; 
}

foreach $f (@f)
{ 
  if( $f =~ m/.*\.pl\Z/ 
      or $f =~ m/.*\.j\Z/ 
      or $f =~ m/.*\.db\Z/ 
  )
  { chmod 0777, $f;
  }
  elsif( ! -d $f )
  { chmod 0666, $f;
  }
}

