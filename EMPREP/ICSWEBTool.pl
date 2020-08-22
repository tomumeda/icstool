#!/usr/bin/perl
##TEST
use lib ("/home/tom/Sites/ICSTool/Lib","/Users/Tom/Sites/ICSTool/Lib");
use URI::Escape;
use Fcntl;
use DB_File;
use POSIX qw(strftime);
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;
####################### If cache lib is used
# list ICSTool Lib directories
######################
# print Dump($q); #DEBUG
$OrgName="EmPrep";
#######################
require "subCommon.pl";
require "subICSWEBTool.pl";
require "subMemberDB.pl";
require "subMessageSystem.pl";
require "subDamageReport.pl";
require "subManageResponseTeam.pl";
require "subMaps.pl";
  require "MemberInformation.pl";
  require "subImageUpload.pl";
#########################
&initialization;
#########################
## NEED TO DELETE LOCAL VARIABLES that are cached on server
sub undefAlllocal
{ my $list="UserName,FindByName,action,UserAction,LastUserAction,firstname,lastname,LoginName,ContactInformation,PersonnelName,SignIn,ReviewDamages,FireAssessment,PeopleInjuredAssessment,PeopleTrappedAssessment,PeopleDeadAssessment,RoadsAssessment,UrgencyAssessment,HazardsAssessment,StructuralAssessment,AssignRole,MessageAction,SelectNames,SelectStreet,SelectAddress,SelectSubAddress,vAddress,SelectTeam,ICSpassword,RoleByName_ref,NamesByRole_ref,ResponseTeamAtLocation,InfoShown,LastForm,reDo,ShowReportFor,MapFile,mode,usertype";
  foreach my $var (split(/,/,$list))
  { 
    undef ${$var};
    undef @{$var};
  }
}
&undefAlllocal;
## global variables ?? May be create problems with uninitialized variables
&param2var($q);
$q->delete_all();
#######################
# print ">>>QUERY_STRING:",$ENV{"QUERY_STRING"};		#####################
&Eval_QUERY_STRING;
#######################
#print ("mode= $mode ");
#print ("FirstName= $FirstName ");
#######################
if($mode eq "MemberInformation")
{ 
  # print "ShowReportFor $ShowReportFor"; 
  require "MemberInformation.pl";
  require "subImageUpload.pl";
  &MemberInformation($q);
  exit 0;
}
#######################
do "subMessageSystem.pl";
do "subManageResponseTeam.pl";
###########################
&initializePersonnelRoleSkill;
######################## 
# I don't know why I get these array. Correct for program BUG
sub undefArray
{ my @name=("action","UserName","UserAction");
  foreach my $name ( @name )
  { if ( @{$name} )
    { ${$name}=${$name}[0];
      undef @{$name};
    }
    #print "<br>undefArray: $name, ${$name}";
  }
}
&undefArray;

######################## 
&xHTMLHeader;
######################## 
print $q->h2("$OrgName ICS Tool");
print $q->start_multipart_form;
######################## 
if( ( my $ishow = &FindMatchQ("ShowInfo:",@params)) >-1 )
{ my ($dum,$info)=split(/:/,$params[$ishow]);
  $q->delete($params[$ishow]);
  &ShowInfoExit($info);
  goto END;
}

##################################### Process UserAction
#print ">0>",$action,"::",&MemberQ(@action,"Cancel>Home"),">>",join("::",@action),"<br>";
if($action eq "Cancel>Home" or &MemberQ(@action,"Cancel>Home") ge 0)
{ my $LastUserName=$UserName; #CHANGE
  &undefAlllocal;
  $UserName=$LastUserName;
  #print ">1>",&MemberQ(@action,"Cancel>Home"),">>",join("::",@action),"<br>";
}

if($action eq "ChangeUser")  # CHK
{ undef $UserName;
  undef $lastname; 
  undef $firstname;
  if( $LoginName )
  { $FindByName=$LoginName;
  }
}

# Save Personnel data
if($action eq "Submit" and ($UserAction eq "Sign In Others" or $UserAction eq "UpdatePersonnelInfo") )
{ 
  if(!$PersonnelName)
  { if( &goodName($lastname,$firstname) ) #create UserName
    { $PersonnelName="$lastname.$firstname";
    }
  }
  if($PersonnelName)
  { &savePersonnelInfo($q,$PersonnelName);
  }
  else
  { print(&COMMENT("[BAD name: Re-do $UserAction!]<br>"));
    $action="Back";
    $LastAction=$UserAction;
  }

  if($UserAction eq "UpdatePersonnelInfo") 
  { undef $UserAction;
    $q->delete("UserAction");
  }
  undef $action;
  $q->delete('action');
  undef $PersonnelName;
  $q->delete('PersonnelName');
}
if($action eq "New Name")
{ $FindByName=$LoginName;
}

######################### UserName SignIn or Edit or NewName
#&DEBUG("at SignIn:$UserName:$SignIn:$FindByName:$action:$UserAction");
if($SignIn)
{ $UserName=$SignIn;
  if(&SelectPersonnelNames($UserName) eq 0) # has no PersonnelFile->get from DB
  { &SetMemberParameters($q,$UserName);
    &savePersonnelInfo($q,$UserName);
  }
}

if(!$UserName 
    or ($action eq "Submit" and $UserAction eq "Edit My Info")
    or ($action eq "Submit" and $LastAction eq "New Name")
)
{ if( &goodName($lastname,$firstname) ) #create UserName from PersonnelInfoForm/UserInfoForm
  { $UserName="$lastname.$firstname";
    $q->param("UserName",$UserName);
    &savePersonnelInfo($q,$UserName);
    undef $UserAction;
  }
  elsif($#params>-1 
    && $action ne "ChangeUser" 
    && $action ne "Find your name" 
    && $action ne "Try Again"
    && $action ne "New Name"
  )
  { #print(&COMMENT("BAD name: Re-enter!"));
  }
}
####################################################################################
HOME:
if(!$UserName)
{ &loginUser($q);
}
else
{ 
  &initializeAllPersonnelData;
  # ADD 
  # &PersonnelInfoUpdate($q);
  # &DamageInfoUpdate($q);
  &TeamDataUpdate($q);
  # &MessageInfoUpdate($q);
  # load User Info 
  ######################## 
  &loadPersonnelInfo($UserName);
  @UserSkills=@PersonnelSkills;
  $UserAssignment=$PersonnelAssignment;
  $UserContactInfo=$PersonnelContactInfo;
  @assignmentOptions=&AssignmentOptions($UserName);

  ## Process User Request
  if( $AssignRole and $SelectNames)
  { &RoleAssignment($q);
  }
  ##
  ## send MESSAGES here ########
  &SendMessageTo($q);
  ####################################
  if($action eq 'Back') ## ??
  { $UserAction = $LastAction;
  }
  if($UserAction)
  { &serviceUserAction($q);
  }
  else
  { &requestUserAction($q); 
  }
}
END:
print   $q->end_html;

########################################################
sub loginUser
{ my $q=@_[0];
  &DEBUG(">>loginUser:$FindByName:");

  if($FindByName)
  { &printFindByNameTable($q,"User");
  }
  elsif($action eq "New Name")
  { &UserInfoForm($q);
  }
  else
  { print &COMMENT("$OrgName Members sign in here:<br>");
    print $q->textfield(-name=>'FindByName',-size=>20, -placeholder=>'enter partial name here') ;
    print $q->submit('action','Find your name'),hr();
    print &COMMENT("If you are not an $OrgName Member, click here:"),
      $q->submit('action','New Name');
    print hr(),$q->submit(-name=>'ShowInfo:SignInForm', -value=>'Help', -id=>'helpButton');
    print hr(),$q->submit(-name=>'ShowInfo:ICSTool', -value=>'ICSTool Info', -id=>'helpButton');

  }
  print $q->end_form;
}

sub UserInfoForm
{ my ($q)=@_;
  &DEBUG("UserInfoForm ","$UserName");
  my @myskills;
  my $assign;
  if( $UserName )
  { ($lastname,$firstname)=split(/\./,$UserName,2);
    @myskills=@UserSkills;
    # @assignmentOptions=&AssignmentOptions($UserName); ## call before
    $assign=$UserAssignment;
    $ContactInformation=$UserContactInfo;
    # print ">>$UserAssignment,@UserSkills,$UserContactInfo";
    print $q->h3("[$UserName]");
    #print $q->h6("[$UserName]"),hr();
    print &COMMENT("Submit any changes"),"<br>";
  }
  else
  { print $q->h3("New Name Form"),hr();
    $assign="Initial Surveyor";
    print $q->hidden(-name=>"LastAction",-value=>"New Name"); 
  }
  ##
  if($UserName)
  { $q->param(-name=>"lastname",-value=>"$lastname"); 
    $q->param(-name=>"firstname",-value=>"$firstname"); 
    print $q->hidden(-name=>"lastname",-value=>"$lastname"); 
    print $q->hidden(-name=>"firstname",-value=>"$firstname"); 
  }
  else
  { print 
    $q->textfield(-name=>'firstname',-value=>"",-size=>20,-placeholder=>"First Name"),
    $q->textfield(-name=>'lastname',-value=>"",-size=>20,-placeholder=>"Last Name");
    print "<br>";
  }
  #
  &printSkillsTable($UserName);
  ############################
  $q->param("LastUserAction",$UserAction); #???seem to need
  &hiddenParam($q,"UserName,LastUserName,UserAction,LastAction");
  @actions=('Submit',"Cancel>Home"); 
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>'ShowInfo:UserInfoForm', -value=>'Help', -id=>'helpButton');
}

sub PersonnelInfoForm
{ my $q=@_[0];
  my @myskills;
  my $assign;
  my $FormType;
  &DEBUG("PersonnelInfoForm: $FindByName,$PersonnelName");
  if($UserAction eq "Manage Response Teams" ) # switch UserAction
  { $q->delete("UserAction");
    $UserAction="UpdatePersonnelInfo";
    $q->param("UserAction",$UserAction);
  }
  if($UserAction eq "UpdatePersonnelInfo" )
  { print $q->h3("Personnel Info Form"),hr();
    $FormType="PersonnelInfoForm";
  }
  else
  { print $q->h3("Sign In Others"),hr();
    $FormType="SignInOthers";
    $q->param("LastAction","Sign In Others");
    #$q->param("LastAction","$UserAction");
  }
  if(!$PersonnelName and $action ne "New Name")
  { if($FindByName)
    { &printFindByNameTable($q,"Personnel");
    }
    else
    { print &COMMENT("Find member name:<br>");
      print $q->textfield(-name=>'FindByName',-size=>20, -placeholder=>'partial name OK') ;
      print $q->submit('action','Find Name');
      print &COMMENT("<br>If non-member, click here: <br>"),
	$q->submit('action','New Name');
    }
    @actions=("Cancel>Home"); 
  }
  elsif($action eq "New Name")
  { print $q->h3("New Name Form"),hr();
    $assign="Initial Surveyor";
    print 
    $q->textfield(-name=>'firstname',-value=>"",-size=>20,-placeholder=>"First Name"),
    $q->textfield(-name=>'lastname',-value=>"",-size=>20,-placeholder=>"Last Name");
    print "<br>";
    #previous @assignmentOptions=&AssignmentOptions($UserName);
    &printSkillsTable("");
    @actions=('Submit',"Cancel>Home"); 
  }
  else #default is to display for $PersonnelName
  { if( &SelectPersonnelNames($PersonnelName) eq 0) # has no PersonnelFile->get from DB
    { &SetMemberParameters($q,$PersonnelName);
      &savePersonnelInfo($q,$PersonnelName);
    }
    else
    { &loadPersonnelInfo($PersonnelName);
    }
 
    #previous @assignmentOptions=&AssignmentOptions($UserName);
    push @assignmentOptions,"Initial Surveyor";
    #?? my ($lastname,$firstname)=split(/\./,$PersonnelName,2);
    &DEBUG("PersonnelInfoForm:$assign,@myskills,@skillsICS,$ContactInformation");
    print $q->h6("[$PersonnelName]"),hr();
    print &COMMENT("Submit any changes"),"<br>";
    &printSkillsTable($PersonnelName);
    $q->param('PersonnelName',$PersonnelName);
    @actions=('Submit',"Cancel>Home"); 
  }
  &hiddenParam($q,"UserName,UserAction,PersonnelName");
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>"ShowInfo:$FormType", -value=>"$FormType Help", -id=>'helpButton');
  print $q->end_form;
  ############################
}

sub savePersonnelInfo
{ my ($q,$name) = @_;
  &DEBUG("savePersonnelInfo:$UserName,$name,$firstname,$lastname,@skills");
  $q->param("UXtime",$UXtime);
  $q->param("time",$timestr);
  my $file="Personnel/$name";
  &saveParmsCGIfile($q,$file,
   'firstname,lastname,assignment,@skills,ContactInformation,UXtime,time');
  $file="PersonnelLog/$name";
  &logParmsCGIfile($q,$file,
   'firstname,lastname,assignment,@skills,ContactInformation,UXtime,time');
}

# serviceUserAction services UserAction. Returns for END.
sub serviceUserAction
{ my $q=@_[0];
  my $type;
  &DEBUG("serviceUserAction0: $UserAction,$LastForm");
  if($LastForm eq "DamageAssessmentForm" 
      and ($action eq "Submit" 
	or $action eq "Send Team")
  ) 
  { &save_DamageAssessment($q); # save any changes
    print $q->h5("Damage Report for: [$vAddress] received--Thank you"),hr();
    if($action eq "Submit" )
    { undef $UserAction; # to UserActionForm 
    }
  }
  ######### UserAction
  if( $UserAction eq "ReportDamage" )
  { &DEBUG("serviceUserAction1:$ResponseTeamAtLocation:$action:$LastAction ");
    $q->param("LastAction",$UserAction);
    ###
    # switch modes to ManageResponseTeams 
    if( $action eq "Send Team" or $ResponseTeamAtLocation) #switch to Manage Response Team 
    { &ManageResponseTeams($q,'FormTeam');
    }
    ###########################
    elsif($LastForm eq "DamageAssessmentForm")  # repeat form
    { if( $action eq "ShowPropertyContacts"
	  or $action eq "Back")  # redisplay Form
      { &DamageReportForm($q);
      }
      else
      { $q->delete("UserAction");
	&requestUserAction($q);  #should it JUMP
      }
    }
    else # new report
    { #print ">>UserAction ", $q->param("UserAction" );
      &DamageReportForm($q);
    }
  }
############################
  elsif( $UserAction eq "ReviewDamages" and !$ShowReportFor)
  { 
    &DEBUG("serviceUserActionRD:$UserAction:$LastAction:$Address ");
    # switch modes to ManageResponseTeams 
    if( ($LastForm eq "DamageAssessmentForm"
	or $LastForm eq "DisplayDamageLocations")
       	and $ResponseTeamAtLocation)
    { &ManageResponseTeams($q,"ResponseTeamAtLocation");
    }
    elsif( $action eq "Send Team" )
    { &ManageResponseTeams($q,'FormTeam');
    }
    ###
    elsif( $Address and $LastForm eq "DisplayDamageLocations" and $action ne "Back") 
    { &DEBUG("serviceUserActionRD 1a:$UserAction:$LastAction:$Address ");
      $q->param("vAddress", $q->param("Address"));#VADD
      $vAddress=$Address;
      &vAddressToParam($q, $q->param("vAddress"));#VADD
      &DEBUG("serviceUserActionRD1:$vAddress:$LastAction:$Address ");
      &DamageReportForm($q);
    } 
    elsif( $vAddress and $action eq "Back" )
    { &DEBUG("serviceUserActionRD 1b:$UserAction:$LastAction:$vAddress ");
      &DamageReportForm($q);
    } 
    elsif($LastForm eq "DamageAssessmentForm"
	and $action eq "ShowPropertyContacts") 
    { &DamageReportForm($q);
    }
    elsif($LastForm eq "SelectDamageDisplayForm" and !$InfoShown ) # choose damage display filter
    { my $parm=&SelectDamageAssessment($q);
      &DisplayDamageLocations($parm);
    }
    else
    { &DEBUG("serviceUserAction: $action:$LastAction:");
      &SelectDamageDisplayForm($q); 
    }
  }
  elsif( $ShowReportFor )
  { 
    $q->param("vAddress",$ShowReportFor);
    $q->param("DamageAddress",$ShowReportFor);
    $q->delete('ShowReportFor');
    undef $ShowReportFor;
    &DamageReportForm($q);
  }
  ###############################
  elsif( $q->param("AssignRole") and $q->param("UserAction") eq "Manage ICC Staffing")
  { &AssignRole($q);
  }
  elsif( $q->param("AssignRole") and $q->param("UserAction") eq "Manage Response Teams")
  { &AssignRole($q); ##################
  }
  elsif( $q->param("UserAction") eq "Manage ICC Staffing" )
  { &PersonnelStatus($q,"Manage ICC Staffing");
  }
  ############# #############
  elsif( $UserAction eq "Manage Response Teams" ) 
  { &ManageResponseTeams($q,"Manage Response Teams"); 
  }
  #####################################################################
  elsif( $q->param("UserAction") eq "Edit My Info" )
  { &UserInfoForm($q);
  }
  elsif( $UserAction eq "Sign In Others"  or $UserAction eq "UpdatePersonnelInfo" ) 
  { &PersonnelInfoForm($q);
  }
  elsif( $UserAction eq "Review My Messages" )
  { &MessageTool($q);
  }
  elsif( $UserAction eq "Set Up Command Center" )
  { $q->delete("UserAction");
    undef $UserAction;
    &ShowInfoExit('SettingUpICC');
  }
  elsif( $UserAction eq "View Maps" )
  { &ViewMapsForm($q);
  }
  elsif( $UserAction =~ /^Map:/ ) # show appropriate Map:
  { &ViewMap($q);
  }
  elsif( $UserAction =~ /^Image:/ ) # show appropriate Image
  { &ViewImage($q);
  }
  elsif( $UserAction =~ /^Reset ICSTool/ ) 
  { &ResetICSTool($q);
  }
  elsif( $UserAction eq "How To Reviews" )
  { &HowToForm($q);
  }
  else
  { &requestUserAction($q);
  }
}

sub loadPersonnelInfo
{ my $name=$_[0];
  my $qq=CGI->new;
  &DEBUG("loadPersonnelInfo:$name");
  $qq=&loadPersonnelFile($name);
  if( $qq )
  { @PersonnelSkills=$qq->param('skills');
    $PersonnelAssignment=$qq->param('assignment');
    $PersonnelContactInfo=$qq->param('ContactInformation');
  }
}
#
#-----------------------------------
sub UpdateMemberInfo
{ my $q=@_[0];
  if($UserAction eq "UpdateMemberInfo" )
  { print $q->h3("Member Information Form"),hr();
    $FormType="MemberInfoForm";
  }

  if(!$PersonnelName and $action ne "New Name")
  { if($FindByName)
    { &printFindByNameTable($q,"Personnel");
    }
    else
    { print &COMMENT("Find member name:<br>");
      print $q->textfield(-name=>'FindByName',-size=>20, -placeholder=>'partial name OK') ;
      print $q->submit('action','Find Name');
      print &COMMENT("<br>If non-member, click here: <br>"),
	$q->submit('action','New Name');
    }
    @actions=("Cancel>Home"); 
  }
  elsif($action eq "New Name")
  { print $q->h3("New Name Form"),hr();
    print 
    $q->textfield(-name=>'firstname',-value=>"",-size=>20,-placeholder=>"First Name"),
    $q->textfield(-name=>'lastname',-value=>"",-size=>20,-placeholder=>"Last Name");
    print "<br>";
    &printMemberInfoForm("");
    @actions=('Submit',"Cancel>Home"); 
  }
  else #default is to display for $PersonnelName
  { if( &SelectMemberNames($PersonnelName) eq 0) # has no PersonnelFile->get from DB
    { &SetMemberParameters($q,$PersonnelName);
      &savePersonnelInfo($q,$PersonnelName);
    }
    else
    { &loadPersonnelInfo($PersonnelName);
    }
 
    #?? my ($lastname,$firstname)=split(/\./,$PersonnelName,2);
    &DEBUG("PersonnelInfoForm:$assign,@myskills,@skillsICS,$ContactInformation");
    print $q->h6("[$PersonnelName]"),hr();
    print &COMMENT("Submit any changes"),"<br>";
    &printMemberInfoForm($PersonnelName);
    $q->param('PersonnelName',$PersonnelName);
    @actions=('Submit',"Cancel>Home"); 
  }
  &hiddenParam($q,"UserName,UserAction,PersonnelName");
  &SubmitActionList(@actions);
  print hr(),$q->submit(-name=>"ShowInfo:$FormType", -value=>"$FormType Help", -id=>'helpButton');
  print $q->end_form;
  ############################
}

1;
