ICSTool Databases, Data Source, Data Formats
======
This document describes the format and content of the databases the ICSTool uses during its operation.  Their locations are relative to the /.ICSTool/ directory.

# Participants Information
Participant information is kept in the directory ./PL/Personnel with the participant's name as the filename.  The naming convention is "last name"."first name" where the quoted names are the names used in the SignIn procedure.  This information is maintained by the ICSTool from the time a person signs in and can be editted or changed with the ICSTool.  There is a Group Member Database that can fill-in this information when a member signs in.  The Group Member Database is described in the file ./MEMBERDATABASE.md.
## Data Format
The files are created by the [PERL CGI->save()](http://perldoc.perl.org/CGI.html) command where the variable name is the ICSTool internal name.  Below is an example of the contents where the variable names are somewhat self descriptive:
```
firstname=Takato%28Tom%29
lastname=Umeda
skills=Communications                           # list of skills>
skills=Fire%20Suppression
skills=First%20Aid
ContactInformation=Cell%3A6%2F30%2F2017%209%3A17%3A31%3B%20Phone%3A6%2F30%2F2017%209%3A17%3A31%3B%20Email%3A6%2F30%2F2017%209%3A17%3A31
UXtime=1511756118                               # time of last entry>
time=Sun%20Nov%2026%2020%3A15%202017
assignment=Incident%20Commander                 # ICS assignment>
=
```

# Damage Assessments
Damage assessment information is kept in the directory ./PL/Damages with the property address as the filename.  The address naming convention is "Street=Street Address=SubAddress=" with "=" as separators.  These files are created/editted with the ReportDamage/ReviewDamage feature of the ICSTool. 
## Data Format
The files are created by the [PERL CGI->save()](http://perldoc.perl.org/CGI.html) command.
Below is an example of the contents where the variable names which correspond to the ICSTool form are somewhat self descriptive:
```
AllClearSignAssessment=None
FireAssessment=Small%20Flames
HazardsAssessment=Electrical
HazardsAssessment=Water%20Leak
StructuralAssessment=Heavy%20Damage
PeopleInjuredAssessment=1
PeopleTrappedAssessment=2
PeopleDeadAssessment=2
RoadsAssessment=Accessible
UrgencyAssessment=ImmediateThreat
SelectStreet=Cedar%20St
SelectAddress=2649
UXtime=1524024549                           # time of last entry
UserName=Umeda.Takato%28Tom%29
ReportedBy=Umeda.Takato%28Tom%29            # name of last reporter
vAddress=Cedar%20St%3D2649%3D
=
```

# Response Teams
The ICSTool can by used to help with the formation and deployment of Response Teams and to track their status.  Response Team information is kept in the directory ./PL/ResponseTeams with filename "Response Team N" where N is a sequence number for the team.

## Data Format
The files are created by the [PERL CGI->save()](http://perldoc.perl.org/CGI.html) command.
Below is an example of the contents where the variable names are somewhat self descriptive:
```
time=Wed%20Apr%2018%2022%3A22%202018
SelectNames=Doe.Jane
SelectNames=Smith.Joe
vAddress=Cedar%20St%3D2647%3D
=
```

# Messages
There is a simple Messaging system available through the ICSTool.  Messages can be sent and received to specified individuals or groups.
## Data Format
Messages are stored in PERL DB_File format with the command:
```
tie(%Messages,"DB_File","./PL/DB/Messages.db",O_RDWR|O_CREAT,0666)
```
# Help Files
ICSTool has simple markup Help files on almost every displayed page. These files are located in the ./PL/Info directory with filenames corresponding to the display page.  An example for SignInForm.info is given below.  There are only a few markup commands available for these files. Each markup command must be on its own line.  HTML5 language may be imbedded in the text.
* :TITLE:
Displayed title
* :CONTENT:
Marks the beginning of content.
* :LIST:
Marks the beginning of a list where each line is a new item.  Lists may be nested.
* :ENDLIST:
Marks the end of the current list.
```
:TITLE:
Sign In Form
:CONTENT:
Everyone who participates in the Incident Command System (ICS) must sign-in.
:LIST:
If you are a EmPrep member, you can search for your information name by entering a portion of your name, e.g. 'to' for 'tom', over the 'enter partial name here' field.
If you are not an EmPrep member, then click on the 'New Name' button which will take you to the form where you can enter your personal information.
:ENDLIST:
```


# Maps
The ICSTool maintains map background images local to the server in JPEG format.  Address locations are translated into longitude-latitude locations which are then translated to pixel locations on the maps.  The map descriptor of each map used by the ICSTool are listed in the file ./PL/Lists/MapsAvailable.txt where each item refer to a Map Descriptor File.  The following is an example of the contents of this file for four maps:
```
Lists/MapDamageStatus.Rooftop.txt
Lists/MapSpecialNeeds.Rooftop.txt
Lists/MapDamageStatus.EmPrep11x17.txt
Lists/MapAddressLocation.Rooftop.NOMENU.txt     #Does not display on menu
```

## Map Descriptors File
This file contains information needed to produce a map.  An example that generates the damage stata map is shown below.  
```
MapTitle=Parcel Map EmPrep<br>Damage Status                 # Title of map HTML format
MapParameters=Lists/Map.Rooftop.Info.txt                    # file containing background map information
MapAddressLonLat=ParcelLonLatByAddress                      # database name to use map locstion from address
MapExtraAddressLonLat=NoParcelAddressLL                     # additional map locations not in previous database
address=Le Roy Ave=1643=                                    # dummy address to get routines to work

MapYOffset=0;                                               # image Y offset in pixels
MarkerSize=18                                               # marker size
MarkerBoarderSize=20                                        # marker size    
subMarkerSize=8

#Legend data
LegendMarkerSize=18                                         # legend rectangular marker size
LegendTextSize=30                                           # legend text size

#Symbol Overlay data
MapSymbolMarkerSize=18                                      # legend rectangular marker size
MapSymbolTextSize=30                                        # legend text size

MapFixedSymbols=Lists/MapDamageStatus.Rooftop.FixedSymbols.txt  # filename of fixed symbols for map

DisplayType=DamageStatus                                    # map display type
GraphType=BoxSymbol                                         # type of symbol used on map
```
An example file that generates the Special Needs map is shown below.  This file has BoxColor[] and BoxName[] which are new and are in development.
```
MapTitle=Parcel Map EmPrep<br>Special Needs
MapParameters=Lists/Map.Rooftop.Info.txt
MapAddressLonLat=ParcelLonLatByAddress                      # address to latitude-longitude database: ./PL/DB/<>.db
MapExtraAddressLonLat=NoParcelAddressLL                     # extra address to latitude-longitude data ./PL/DB/<>.db
address=Le Roy Ave=1643=                                    # dummy address to get routines to work BUG

MapYOffset=0;                                               # imageYRef
MarkerSize=18 
MarkerBoarderSize=20 
subMarkerSize=8

#Legend data
LegendMarkerSize=18                                         # legend rectangular marker size
LegendTextSize=30                                           # legend text size

#Symbol Overlay data
MapSymbolMarkerSize=18 # legend rectangular marker size
MapSymbolTextSize=30 # legend text size

MapFixedSymbols=Lists/MapSpecialNeeds.Rooftop.FixedSymbols.txt  # filename of map fixed symbols

DisplayType=SpecialNeeds
GraphType=BoxSymbol

BoxColor[0]=red
BoxColor[1]=blue
BoxColor[2]=green

BoxName[0]=SpecialNeeds:
BoxName[1]=Visitors:
BoxName[2]=Pets:
```
### Map Parameters File
This file contains filename of the background map and data for determining a pixel location from latitude-longitude location.
```
MapFile=Maps/rooftops.EmPrep.jpg                    # background map filename
MapXdim=822px                                       # jpg image pixel dimensions
MapDimX=822
MapYdim=881px
MapDimY=881
#reference points {CoordX,CoordY,x-pix,y-pix}       # latitude-longitude to pixel interpolation parameters
MapLowerLeftCoordXRef=-122.260537
MapUpperRightCoordXRef=-122.254916
MapLowerLeftCoordYRef=37.876982
MapUpperRightCoordYRef=37.881720
MapLowerLeftPxXRef=1
MapLowerLeftPxYRef=881
MapUpperRightPxXRef=822
MapUpperRightPxYRef=1 
```
### Map Fixed Symbols File
This file contains SVG instructions for fixed symbol overlays, such as, legends.  An example is shown below:
```<rect x="20" y="10" width="20" height="20" stroke="black" fill="red" />
<rect x="20" y="50" width="20" height="20" stroke="black" fill="blue" />
<rect x="300" y="10" width="20" height="20" stroke="black" fill="green" />
<text x="50" y="30" font-size="20">Special Needs</text>
<text x="50" y="70" font-size="20">Visitors</text>
<text x="330" y="30" font-size="20">Pets</text>

<text x="350" y="310" font-size="18" fill="red" id="Incident Command Center">ICC</text>
<text x="400" y="355" font-size="18" fill="red" id="Division A meeting point">A</text>
<text x="510" y="620" font-size="18" fill="red" id="Division B meeting point">B</text>
<text x="595" y="460" font-size="18" fill="red" id="Division C meeting point">C</text>
```

## Map Data Sources
Latitude-longitude data for parcel address are derived from the [City of Berkeley Parcel GIS data](https://data.cityofberkeley.info/City-Government/Parcels/bhxd-e6up).  The Shapefile contains almost all of the Berkeley addresses.  The free GIS system [QGIS](https://qgis.org/en/site/) was used to process the Berkeley data into ./QGIS/Parcels/Parcels.dbf where a subregion is extracted into the ./PL/DB/ParcelLonLatByAddress.db file.  Map and geolocation files used by ICSTool:
```
$HOME/QGIS/Parcels.dbf                      # City of Berkeley Parcels database in .dbf
./DB/ParcelInfoByAddress.db                 # tab separate Addesses on City of Berkeley Parcel Streets
./DB/ParcelStreetAddresses.db               # City of Berkeley Parcel Addresses by Street
./DB/ParcelLonLatByAddress.db               # City of Berkeley latitude-longitude by StreetAddress

./PL/StreetAddressList.d                    # list of StreetAddresses in neighborhood
./PL/StreetList.d                           # list of Streets in neighborhood

./PL/Lists/MapStreetAddressLLEmPrep.txt     # neighborhood latitude-longitude-pixel data for StreetAddresses

./DB/MapStreetAddressesEmPrep.db            # neighborhood tab separate Addesses by Street
./DB/MapStreetAddressPIXEmPrep.db           # neighborhood latitude-longitude-pixel data by StreetAddress
./DB/MapStreetAddressLLEmPrep.db            # neighborhood map pixel location by StreetAddresses 

./Maps/rooftops.EmPrep.jpg                  # neighborhood background map for map display generated by QGIS
./Maps/EmPrep1700x2550.jpg                  # neighborhood map by EmPrep Neighborhood group
```
## Tools for Creating Map Data for ICSTool 
```
QGIS                                        # GIS system to convert City of Berkeley Parcel .dbf to $HOME/QGIS/Parcels.dbf and produce .jpg maps of neighborhood areas 
./PL/mkParcelLonLatDB.j                     # creates  ./DB/ParcelInfoByAddress.db and ./DB/ParcelStreetAddresses.db files of parcel geolocation information from $HOME/QGIS/Parcels.dbf 
./PL/mkAddressList.pl                       # makes ./PL/StreetAddressList.d and ./PL/StreetList.d for ICSTool
./PL/parcelStreetAddresses.j                # makes .PL/List/MapStreetAddressLL.txt and AddressesOn/$street
./PL/makeMapStreetAddressEmPrep.j           # makes ./PL/DB/MapStreetAddressesEmPrep.db, ./PL/DB/MapStreetAddressLLEmPrep.db, and ./PL/DB/MapStreetAddressPIXEmPrep.db from .PL/Lists/MapStreetAddressLLEmPrep.txt. 

```


