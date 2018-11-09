ICSTool
======
10/2018

This repository holds the PERL based ICSTool WEB server program.

A general desciption of the ICSTool can be found in the file Info.EmPrep/ICSTool.info and the contents are reproduced below:

# ICS Tool Info
ICSTool is an Web based tool to help neighborhood CERT groups rapidly establish their Incident Command System (ICS) at their Incident Command Center (ICC) during an emergency incident. This Tool will facilitate ICS operations by:

* Imposing the ICS structure on CERT group operations
* Providing explanations of different components of the ICS and the duties ICS roles
* Easy reporting of emergency situations
* Keeping of detailed records of:
* Emergency situations (also located on maps)
* ICS personnel status
* Response Teams status
* Providing a WEB based communication system that logs all messages
* Providing access to neighborhood data base information: residents, maps, inventory  


# NOTES
The WEB entry point for the program is: http://<path to ICSTool>/PL/index.pl

The ICSTool depends on WEB communication and will be most effective if there is internet-like connection between neighborhood CERT members. However, during disasters normal internet communication (WEB, cell phone, cable) may not be available, but a battery power local area network(LAN) can be established at the ICC, and if possible extended to the neighborhood, to provide ICSTool functionality at the ICC where it is needed most. 

# Other Documents
The following is a list of documents that explain more of the contents and workings of the ICSTool.
* [README.md](./README.md)              #this file
* [DATA.md](./DATA.md)                               #describes data files used by the ICSTool and ancillary programs
* [MEMBERDATABASE.md](./MEMBERDATABASE.md)                     #describes a method to collect neighborhood information and its manipulation into a form for ICSTool
* [INSTALL.raspberrypi.md](./INSTALL.raspberrypi.md)                #descibes how to implement the ICSTool and support programs on a RaspberryPi computer
