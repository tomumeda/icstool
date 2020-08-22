#!/usr/bin/perl
# creates AllBerkeley data files for EmPrep files
$HOME=$ENV{HOME};
# move from DB.Emprep -> DB.AllBerkeley
system "cp -f $HOME/Sites/EMPREP/ICSTool/PL/DB.EmPrep/{Parcel,parcel}* $HOME/Sites/EMPREP/ICSTool/PL/DB.AllBerkeley/";
# move from EMPREP -> public/EMPREP
system "cp -f $HOME/Sites/EMPREP/ICSTool/PL/DB.AllBerkeley/{Parcel,parcel}* $HOME/Sites/public/EMPREP/ICSTool/PL/DB.AllBerkeley/";

chdir "$HOME/Sites/public/EMPREP/ICSTool/PL";
system "$HOME/Sites/EMPREP/setPermission.j";
exit;

chdir "$HOME/Sites/public/EMPREP/ICSTool/PL";
unlink "DB","Lists";
system "ln -s ../Lists.AllBerkeley Lists";
system "ln -s DB.AllBerkeley DB";
system "parcels2.j";
system "parcelStreetAddresses.j";

