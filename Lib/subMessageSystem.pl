#!/usr/bin/perl
#
################################################################
sub MessageTool
{ my ($q)=@_;
  #??
  if($action eq 'Back' and !$InfoShown)
  { $q->delete("MessageAction");
    undef $MessageAction;
  }
  if($action eq 'Back' and $InfoShown)
  { $q->delete('InfoShown');
  }
  &DEBUG("MessageTool: $MessageAction :: @MessageAction");
  if( $MessageAction ) 
  { &MessageAction($q,$MessageAction); 
  }
  else
  {
    print $q->h3("Message Action Form"),hr();
    print &COMMENT("Select Action:"),"<br>";
    my $cmd="";
    $cmd.="<input type=submit name='MessageAction' value='SendMessage' ><br>";
    $cmd.="<input type=submit name='MessageAction' value='ReviewMessages' >";
    print $cmd,hr();
    print $q->submit('action','Cancel>Home');
    &hiddenParam($q,'UserName,UserAction');
    print hr(),$q->submit(-name=>'ShowInfo:MessageTool', -value=>'Help', -id=>'helpButton');
    print $q->end_form;
  }
}

sub openMessages
{ undef %Messages;
  &TIE("Messages");
}

sub closeMessages
{ &UNTIE("Messages");
  undef %Messages;
}

#################################
# MESSAGE section
sub newMessage
{ my ($from,$to,$message) = @_;
  if(!$Messages{lastNumber}){$Messages{lastNumber}=0;}
  $Messages{lastNumber}++;
  $Messages{ $Messages{lastNumber} }="$UXtime;$from;$to;$message";
  return ( $Messages{lastNumber} );
}

sub updateMessageStatus
{ my ($function,$messNumber,@users)=@_;
  foreach my $user (@users)
  { my ($sentList,$readList,$unreadList)= split(/\t/, $Messages{$user} ,3);
    if($function eq "new" )
    { $unreadList.=",$messNumber";
      $unreadList=join(",", &uniq( &MakeArray($unreadList) ) );
      my @read=&MakeArray($readList);
      my $index = &MemberQ( @read, $messNumber );
      @read=&deleteArrayIndex($index,@read);
      $readList=join(",",@read);
    }
    elsif($function eq "acknowledge" )
    { $readList.=",$messNumber";
      $readList=join(",", &uniq( &MakeArray($readList) ) );
      my @unread=&MakeArray($unreadList);
      my $index = &MemberQ( @unread, $messNumber );
      @unread=&deleteArrayIndex($index,@unread);
      $unreadList=join(",",@unread);
    }
    elsif($function eq "sent" )
    { $sentList.=",$messNumber";
      $sentList=join(",", &uniq( &MakeArray($sentList) ) );
    }
    $Messages{$user}=join("\t", $sentList,$readList,$unreadList);
  }
}

# return list of message numbers for @users
sub MessageStatusInfo
{ my ($function,$user)=@_;
  my $return;
  my ($sentList,$readList,$unreadList)=split(/\t/, $Messages{$user} ,3);
  if($function eq "unread" )
  { $return="$unreadList";
  }
  elsif($function eq "sent" )
  { $return="$sentList";
  }
  elsif($function eq "read" )
  { $return="$readList";
  }
  $return;
}

# return \t separated array of message from message number list 
sub getMessages
{ my ($list)=@_;
  my @mess;
  &DEBUG("getMessages: $list");
  foreach my $index (split(/,/,$list))
  { my $input=$Messages{$index};
    push(@mess,"$index;$input");
  }
  close L;
  join("\t",@mess);
}

# return \t separated array of message from message list
sub headerMessages
{ my ($user)=@_;
  use POSIX qw(strftime); #??
  &openMessages;
  my $list=&MessageStatusInfo("unread",$user);
  $list=join(",",sort {$a <=> $b} split(/,/,$list));
  my @mess=split(/\t/,&getMessages($list));
  # if there is message
  # CHECK if acknowledged
  if( $#mess >= 0 ) 
  { my $messNumber=$q->param("Ack"); 
    &updateMessageStatus("acknowledge",$messNumber,$user);
    $list=&MessageStatusInfo("unread",$user);
    $list=join(",",sort {$a <=> $b} split(/,/,$list));
    @mess=split(/\t/,&getMessages($list));
  }
  if( $#mess >= 0 )
  { my $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5 align=center> ";
    #
    $cmd.="<tr><th>".
    &COLOR("blue","Acknowledge").
    "</th> <th>".
    &COLOR("blue","HR:MIN ago").
    "</th> <th>".
    &COLOR("blue","From").
    "</th> <th>".
    &COLOR("blue","To"). "</th></tr>";
    print &COMMENT("<br>Messages for: ").$user;
    #
    foreach my $mess0 (@mess)
    { my ($index,$sec0,$from,$to,$mess)=split(/;/,$mess0,5);
      my $sec=$UXtime-$sec0;
      my $timestr= strftime "%a %b %e %H:%M %Y", localtime($UXtime);
      my $hr=int($sec/3600);
      my $min=int(($sec/3600-$hr)*60);
      $hr=sprintf("%02d",$hr);
      $min=sprintf("%02d",$min);
      #
      $cmd.="<tr><td>".
      $q->submit('Ack',"$index").
      "</td> <td>".
      &COLOR("orange","$hr:$min").
      "</td> <td>".
      "$from". 
      "</td> <td>".
      "$to".  "</td> </tr>".
      "<tr>".
      "<td colspan=4>".&COLOR("purple","$mess")."</td></tr>";
    }
    print "<br>";
    $cmd.=" </table > </fieldset> "; ### ??
    print $cmd;
  }
  &closeMessages;
}
#########################################

sub addMessage
{ my ( $text, $from, $target, @to )=@_;
  if(&MemberQ(@params,"Ack")<0) # ignore if from Acknowledgement
  { $text=~s/\n/<br>/;
    &openMessages;
    my $mess= &newMessage($from,$target,$text);
    &updateMessageStatus("new",$mess,@to);
    &updateMessageStatus("sent",$mess,$from);
    &closeMessages;
  }
}

sub MessageAction
{ my ($q,$MessageAction)=@_;
  my $FormType;
  &openMessages;
  &DEBUG("MessageAction:: $MessageAction");
  if( $MessageAction =~ /SendMessage/ )
  { &SendMessageForm($q);
    $FormType="SendMessageForm";
  }
  elsif($MessageAction =~ /ReviewMessages/ )
  { &ReviewMessageForm($q);
    $FormType="ReviewMessagesForm";
  }
  elsif($MessageAction =~ /ShowMessages/ )
  { &ShowMessageForm($q);
    $FormType="ShowMessageForm";
  }
  $q->param("LastAction",$UserAction);
  print hr(); 
  print $q->submit('action','Back');
  print hr(); 
  print $q->submit('action','Cancel>Home');
  print hr(),$q->submit(-name=>"ShowInfo:$FormType", -value=>'Help', -id=>'helpButton');
  #$q->delete("MessageAction");
  &hiddenParamAll($q);
  print $q->end_form;
  &closeMessages;
}

sub SendMessageForm
{ my ($q)=@_;
  print $q->h3("Send Message Form"),hr();
  print $q->h4("Send Message to Available Staff:");
  ########### role
  my @roles=keys %$NamesByRole_ref;
  @roles=sort &deleteNullItems(@roles);
  push(@roles,"All Personnel");
  my %labels,$tmp;
  my @rolesXX=map {$tmp="SendMessageToRole:$_";$labels{$tmp}=$_;$tmp} @roles;
  $q->delete("MessageAction");
  print $q->checkbox_group(-name=>"MessageAction",-values=>[@rolesXX],-labels=>\%labels
    ,-disabled=>["SendMessageToRole:Unavailable"],
    ,-linebreak=>"true");
  ########### personnel 
  print $q->h4("Send Message To Personnel:");
  my %labels,$tmp;
  my @personnel=keys %$RoleByName_ref;
  @personnelX=map {$tmp="SendMessageToPerson:$_";$labels{$tmp}=$_;$tmp} @personnel;
  print $q->checkbox_group(-name=>"MessageAction",-values=>[@personnelX],-labels=>\%labels
    ,-linebreak=>"true");
  ######
  print &BOLD(&COMMENT("Re:"));
  print &SelectDamageAddress0;
  ######
  $q->delete("Message");
  print $q->h4("Your Message:");
  print $q->textarea(-name=>'Message',-default=>'',-rows=>2,-columns=>55);
  print $q->submit("action","SendMessage");
}

# this routine does the sending
sub SendMessageTo 
{ my ($q)=@_;
  my @MessageAction=$q->param("MessageAction");
  $MessageAction=$MessageAction[0];
  if(&FindMatchQ("SendMessageTo",@MessageAction) ge 0 )
  {
    &DEBUG("SendMessageTo:NO return:2: @MessageAction ");
    #print ("SendMessageTo >3>: @MessageAction ");
    #  $q->delete("MessageAction");
    # make names list
    my @names=();
    for(my $i=0;$i<=$#MessageAction;$i++)
    { if($MessageAction[$i]=~/SendMessageToRole:(.*)/)
      { 
	#print ("SendMessageTo >3>: $1 :: ",keys %NamesByRole_ref);
	if($1 =~/All Personnel/)
	{ @name= keys %NamesByRole_ref;
	} 
	else
	{ push @names,split(/;/,$NamesByRole_ref->{$1});
	}
	&DEBUG("SendMessageTo: @names");
      }
      if($MessageAction[$i]=~/SendMessageToPerson:(.*)/)
      { push @names,$1;
      }
    }
    @names=&uniq(@names);
    &DEBUG("SendMessageTo:>4> @names");
    return if (!@names);
    my $message=$q->param("Message");
    my $address=$q->param("DamageAddress");
    if($address)
    { $message=&COLOR("blue","[$address]")." $message";
    }
    &addMessage( $message, $q->param("UserName"), join(" ",@names), @names );
  }
}

sub ReviewMessageForm
{ my ($q)=@_;
  print $q->h4("Message Filters:");
  print $q->scrolling_list("ListMessagesFilterSentReceived",["Sent","Received"],-size=>2,-multiple=>"true");
  print "<br>",&COMMENT('Location:'),"<br>";
  print &SelectDamageAddress0;
  print "<br>",&COMMENT('PersonnelName:'),"<br>";
  my @names=sort {lc($a) cmp lc($b)} keys %$RoleByName_ref;
  print $q->scrolling_list("ListMessagesFilterPersonnel",[@names],5,-multiple=>"true");
  print "<br>",&COMMENT('Roles:'),"<br>";
  my @roles=sort keys %$NamesByRole_ref;
  print $q->scrolling_list("ListMessagesFilterRole",[@roles],5,-multiple=>"true");
  print "<br>";
  print hr(),$q->submit("MessageAction","ShowMessages");
}

sub ShowMessageForm
{ my ($q)=@_;
  print $q->h3("Message Review"),hr();
  print &COMMENT("Filters: ");
  my @sentreceived= $q->param("ListMessagesFilterSentReceived");
  if($#sentreceived>-1) 
  { print &COLOR("blue","Messages $sentreceived[0]");
  }
  my $DamageAddress=$q->param("DamageAddress");
  if($DamageAddress) { print "<br>",&COMMENT('Location:'),$DamageAddress; }
  my @names=$q->param("ListMessagesFilterPersonnel");
  if($#names>-1) { print "<br>",&COMMENT('Personnel: '),&COLOR("blue","@names"); }
  @roles=$q->param("ListMessagesFilterRole");
  if($#roles>-1) { print "<br>",&COMMENT('Roles:'),&COLOR("blue","@roles"); }
  #
  &DEBUG("ShowMessageForm:keys: ",keys %Messages);
  my ($readList,$sentList,$unreadList)=split(/\t/,$Messages{$UserName},3);
  #print "(Sent:$sentList Read:$readList Unread:$unreadList)";
  my $list="";
  if(!@sentreceived) { $list="$readList,$sentList"; }
  else
  { if(&MemberQ(@sentreceived,"Sent") ) { $list=$sentList; };
    if(&MemberQ(@sentreceived,"Received") ) { $list.=",$readList"; };
  }
  #
  &DEBUG("ShowMessageForm:list: $list");
  my @list=sort {$b <=> $a} split(/,/,$list);

  my @mlist= map { $Messages{$_} } &deleteNullItems(@list);
  &DEBUG("ShowMessageForm:list:: @list");
  my @search=&deleteNullItems(($DamageAddress,@names,@roles));
  &DEBUG("ShowMessageForm:search: @search");
  # apply filter 
  if($#search>-1)
  { my $mlist="";
    foreach  my $mess (keys %Messages) 
    { my $value = $Messages{$mess};
      if( map { $value=~/$_/ } @search )
      { $mlist .= "$mess,"; }
    }
    &DEBUG("ShowMessageForm:search: $mlist");
    $list=$mlist;
  }
  else
  { $list="@list";
  }
  $list=~s/\s/,/g;
  &DEBUG("ShowMessageForm:list: $list");
  #print "<br>:",$list;
  &showMessages($list); # needs list of Messages indices.
}

sub showMessages
{ my ($list)=@_;
  use POSIX qw(strftime);
  my @mess=split(/\t/,&getMessages($list));
  @mess=&uniq(@mess);
  @mess=sort {$b <=> $a} @mess;
  # if there is message
  # CHECK if acknowledged
  if( $#mess >= 0 )
  { my $cmd="<fieldset> <table border=1 width=940 cellspacing=0 cellpadding=5 align=center> ";
    #
    $cmd.="<tr><th>".
    &COLOR("blue","HR:MIN ago").
    "</th> <th>".
    &COLOR("blue","From").
    "</th> <th>".
    &COLOR("blue","To"). "</th></tr>";
    #
    foreach my $mess0 (@mess)
    { my ($index,$sec0,$from,$to,$mess)=split(/;/,$mess0,5);
      my $sec=$UXtime-$sec0;
      my $timestr= strftime "%a %b %e %H:%M %Y", localtime($UXtime);
      my $hr=int($sec/3600);
      my $min=int(($sec/3600-$hr)*60);
      $hr=sprintf("%02d",$hr);
      $min=sprintf("%02d",$min);
      #
      $cmd.="<tr><td>".
      &COLOR("orange","$hr:$min").
      "</td> <td>".
      &COLOR("green","$from"). 
      "</td> <td>".
      &COLOR("green","$to"). 
      "</td> </tr>".
      "<tr>".
      "<td colspan=4>".&BOLD("$mess")."</td></tr>";
    }
    print "<br>";
    $cmd.=" </table > <fieldset> ";
    print $cmd;
  }
}

# END Messages
##########################
1;
