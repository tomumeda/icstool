#!/usr/bin/perl
##!/usr/local/ActivePerl-5.24/bin/perl
#
unlink glob "./DB/*.db"; # linux.db incompatible with OSX.db WARN: includes all ICSTool.db files May want to be selective
# unlink glob "./DB/Images/*"; # REST images
system "csvFix.j"; # edit first to point to the correct csv file
system "MasterDB.csv2db.pl";
system "mkAddressList.pl";
system "mkParcelLonLatDB.j";
system "parcelStreetAddresses.j";
system "noLLaddresses.parcelAdd.j";
system "makeMapStreetAddressEmPrep.j";
system "mkMemberAddressList.j";
system "setPermission.j";
system "mkdir DB/Downloads";
system "mkdir DB/Uploads";
system "mkdir DB/Maps";
system "mkdir DB/Images";
system "setPermission.j";
# check 
unlink "DB/Messages.db";
unlink "DB/Personnel.db";
unlink "DB/ResponseTeams.db";

