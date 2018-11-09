Neighborhood Member Database System
======
This file describes the Member Database System which is used by ICSTool.  The system includes methods for collecting updates for the neighborhood group members, processing the collected data into a Member Database .db file for the ICSTool.
## Data and Datafiles
1. MemberInfo.csv -- member information in .csv format currently imported from Google Forms [.csv Header](PL/DB.EmPrep/MasterDB.csv.Header)  [.csv Descriptor](PL/DB.EmPrep/MasterDB.csv.Descriptor) 

2. ./PL/DB/MemberInfo.db -- .db version of the MemberInfo.csv  

## Data Processing Tools
1. [Google form for entering member information](https://docs.google.com/forms/d/1nZ4xfWe81QIT9kDw5DLGg3BiZ4mKg07HBhBBUbU2FEg/edit) where the data is stored on a Google spreadsheet.  This spreadsheet can be exported as a .csv file for processing on the ICSTool computer. 
1. ./PL/csvFix.j checks the downloaded ./PL/DB/MemberInfo.csv file for problems.
2. ./PL/MasterDB.csv2db.pl converts the ./PL/DB.EmPrep/MemberInfo.csv file to a ./PL/DB.EmPrep/MemberInfo.db file
## Tools for Managing Member Database
1. ./PL/csvFix.j checks the ./PL/DB/MemberInfo.csv file for problems.
2. ./PL/MasterDB.db2csv.pl converts ./PL/DB.EmPrep/MemberInfo.db to a ./PL/DB.EmPrep/MemberInfo.csv file for export to spreadsheet program.
3. ./PL/getDBinfo.j lists contents of ./PL/DB.Emprep/MemberInfo.db
4. ./PL/UpdateRequest.j emails requests to members listed in ./PL/DB.EmPrep/MemberInfo.db to update their information.
    * This program relies on the UNIX command postfix for sending email.
    * Google forms pre-fill responses template is encoded in ./PL/googleForm.pl subroutines
