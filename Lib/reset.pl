#!/usr/bin/perl

system "cp -pPRf ../../Resources/DB/DB*.db ./DB/";
system "mkAddressList.pl";
exit;

# DO WE WANT TO DO THIS ??
do "subCommon.pl";
# unlinks log files 
$dir="Personnel,PersonnelLog,Damages,DamageLogs,Messages,ResponseTeams,ResponseTeamLogs,AddressesOn";
@dir=split ",",$dir;
foreach $dir (@dir)
{ @list =  <$dir/*>;
  unlink @list;
}
# unlinks *.db files
# copies # EMPREP/Resources/DB/*.db files to EMPREP/ICSTool/PL/DB/
$dir="DB";
@dir=split ",",$dir;
foreach $dir (@dir)
{ @list =  <$dir/*.db>;
  unlink @list;
}

