#!/usr/bin/perl

sub ViewImage
{ my ($q)=@_;
  my $imageFiles=$UserAction; # UserAction has Map: prepended. Remove!
  $imageFiles=~s/^Image://;
  if($imageFiles =~ m/AddressLocation:/) # if not from menu directly
  { &showImageChoice($imageFiles);
  }
################################
  print $q->start_multipart_form; # DEBUG do we need this here????
################################
  if( $LastForm =~ "DamageAssessmentForm" ) # in case Back selected
  { $q->param("UserAction","ReviewDamages");
    $q->param("LastAction","ReviewDamages");
  }
  else
  { $q->param("LastAction","View Maps");
  }
  &hiddenParamAll($q); # Does not work here ?
  print hr(),$q->submit('action','Back'); 
  print hr(),$q->submit('action','Cancel>Home');
  print $q->end_form;
}

1;
