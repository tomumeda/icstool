#!/usr/bin/perl 

require "subCommon.pl";
require "subMemberDB.pl";

sub ImageUpload
{ ($q,$Name,$Address)=@_; 
  #print "<br>IMAGEUPLOAD>>> ($Name,$Address)";
  #print "<br>PARAM>>>",$q->param;
  ######################
  $CGI::POST_MAX = 2048 * 2048;  # maximum upload filesize 
  ######################
  #print $q->header;
  #print $q->start_html( -title => "File upload page",);
  print 
  $q->h3('Upload image to the ICSTool'),
  $q->start_multipart_form( -name    => 'main_form');
  print "Image Catagory: ";
  print $q->radio_group(
      -name=>"ImageCategory",
      -values=>['Selfie','Housemates','Building'],
      -rows=>1
  );
  print "Select image file to upload ",
            $q->filefield(
            -name      => 'filename',
            -size      => 40,
            -maxlength => 80);
  print $q->hr;
  print "Image description";
  print "<input type=textfield name='imageDescriptor' placeholder='Image Description' >";
  print $q->hr;
  print $q->submit(-name=>"action",-value => 'Upload Image');
  print $q->submit(-name=>"action",-value => 'Cancel');
  print $q->hr;
  print $q->end_form;

#####################
# Look for uploads that exceed $CGI::POST_MAX
  if (!$q->param('filename') && $q->cgi_error()) 
  {
    print $q->cgi_error();
    print <<"EOT";
<p>
The file you are attempting to upload exceeds the maximum allowable file size.
$CGI::POST_MAX bytes
<p>
Please refer to your system administrator
EOT
    print $q->hr, $q->end_html;
    exit 0;
  }

  if($q->param())
  { &save_image_file($ImageCategory,$Name,$Address);
  }

  #  print ">>>$LastName,$FirstName,$Address";
  #print $q->hidden("LastName",$LastName);
  #&var2param($q,"FirstName","StreetName");
}
#-------------------------------------------------------------
sub save_image_file
{ my ($ImageCategory,$Name,$address)=@_;

  #print "<br>UUU>>>$filename=$imageDescriptor<br>$ImageCategory=$Name=$address";
#print "<br> save_image_file PARAM>>>",join("=",$q->param);
  my ($bytesread, $buffer);
  my $num_bytes = 1024;
  my $totalbytes;
  my $untainted_filename;

  if (!$filename) {
    print $q->p('You must enter a filename before you can upload it');
    return;
  }
# Untaint $filename
  if ($filename =~ /^([-\@:\/\\\w.]+)$/) 
  { $untainted_filename = $1;
  } 
  else 
  { print <<"EOT";
Unsupported characters in the filename "$filename". 
Your filename may only contain alphabetic characters and numbers, 
and the characters '_', '-', '\@', '/', '\\' and '.'
EOT
    return;
  }
  if ($untainted_filename =~ m/\.\./) 
  { print <<"EOT";
Your upload filename may not contain the sequence '..' 
Rename your file so that it does not include the sequence '..', and try again.
EOT
    return;
  }

  $filename=~m/\.([\w]+)$/;
  my $EXT=lc $1;

  &TIE("Images/Index");
  $nextN=${"Images/Index"}{"LastN"}+1;

  my $file = "$ICSdir/DB/Images/$nextN.$EXT";
  my $fileDescriptor = "$ICSdir/DB/Images/Descriptor/$nextN.txt";

  print "Uploading $filename to $file<BR>";
        # If running this on a non-Unix/non-Linux/non-MacOS platform, be sure to 
        # set binmode on the OUTFILE filehandle, refer to 
        #    perldoc -f open 
        # and
        #    perldoc -f binmode
  open (OUTFILE, ">", "$file") or die "Couldn't open $file for writing: $!";
  open (DescFile, ">", "$fileDescriptor") or die "Couldn't open Descriptor file $fileDescriptor for writing: $!";

  while ($bytesread = read($filename, $buffer, $num_bytes)) {
    $totalbytes += $bytesread;
    print OUTFILE $buffer;
  }

  if(defined($bytesread))
  { print "<p>Done. File $filename uploaded to $file ($totalbytes bytes)";
    print DescFile $imageDescriptor;

    ${"Images/Index"}{"LastN"}=$nextN; 
    ${"Images/Index"}{"$nextN"}="DB/Images/$nextN.$EXT"; 

    if($ImageCategory eq "Selfie")
    { ${"Images/Selfie"}{$Name}
      =&tabListAdd( ${"Images/Selfie"}{$Name},$nextN);
    }
    if($ImageCategory eq "Housemates")
    { ${"Images/Housemates"}{$Name}
      =&tabListAdd(${"Images/Housemates"}{$Name},$nextN);
      ${"Images/Housemates"}{$address}
      =&tabListAdd( ${"Images/Housemates"}{$address},$nextN);
    }
    if($ImageCategory eq "Building")
    { ${"Images/Building"}{$Name}
      =&tabListAdd(${"Images/Building"}{$Name},$nextN);
      ${"Images/Building"}{$address}
      =&tabListAdd( ${"Images/Building"}{$address},$nextN);
    }
  }
  else
  { print "<p>Error: Could not read file ${untainted_filename}, ";
    print "or the file was zero length.";
    return;
  } 

  close OUTFILE or die "Couldn't close $file: $!";
  close DescFile or die "Couldn't close $fileDescriptor: $!";

  my @image=split(/\//,$file);
  my $image= "$image[$#image-2]/$image[$#image-1]/$image[$#image]";

  print $q->start_multipart_form( -name    => 'main_form');
  print <<___EOR;
<br>
<img src="$image" alt="$ImageCategory" width="200" />
<br>$imageDescriptor
___EOR

  #print $q->hidden("LastName",$LastName);
  #&var2param($q,"FirstName","StreetName");

  print hr();
  print $q->submit('action',"Add Images");
  print $q->submit('action',"Finished");
  print $q->end_form;

  &UNTIE("Images/Index");
  &UNTIE("Images/Selfie");
  &UNTIE("Images/Housemates");
  &UNTIE("Images/Building");

}

sub ImageDelete
{ my ($q,$type,$name,$ntab)=@_;
  print "<br>>>>>($type,$name,$ntab)",${"Images/$type"}{$name};
  ${"Images/$type"}{$name}=&tabListDelete( ${"Images/$type"}{$name},$ntab);
  print "<br>>>>>($type,$name,$ntab)",${"Images/$type"}{$name};
}

1;
