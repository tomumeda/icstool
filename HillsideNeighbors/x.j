#!/usr/bin/perl

use lib "/Users/Tom/Sites/ICSTool/Lib";
print join("\n",@INC);

require "subCommonXX.pl";

&initialization;

print $q;
