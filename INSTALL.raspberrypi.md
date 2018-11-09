Low cost implementation
======
ICSTool can be implemented on a [RaspberryPi](https://www.raspberrypi.org) like computer.  The current version of ICSTool runs on RaspberryPi 2 and RaspberryPi 3 running [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/). The Lite version is recommended because the Desktop version seems to complicate the implementation of the ICSTool and to slow its response as well.  However, the Desktop version may be used as a development platform, I used a MacBook Pro with macOS since I am more familiar with it.  There are a few differences in implemantation of the ICSTool between the two platform which are described below.
# Hardware requirements
* RaspberryPi 2/3
* 8 GByte MicroSD high speed memory card of at least 8 Gbyte 
* Wifi router (for local LAN operation--surplus router are generally available)
* 12 volt power supply (charger, battery, etc.)
The low cost RaspberryPi also has low power requirements enabling it to operate for a couple of days on a 12volt 40ah battery. 
# RaspberryPi OS install [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/) 

## burning the RaspberryPi OS on the MicroSD card using a Mac
* Down load [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/).
* The following example shows command line instructions to load the OS onto a MicroSD memory card. The items delimited by << >> are user specific items.
```
diskutil list ## (to get MicroSD card location, e.g. /dev/diskN) after inserting MicroSD card on Mac
diskutil unmountDisk /dev/diskN  # from above list
cd <directory of raspbian.img>
sudo dd bs=1m if=<<2017-09-07-raspbian-stretch-lite.img>> of=/dev/diskN conv=sync
sudo touch /Volume/boot/ssh  ## to allow ssh login to the RaspberryPi for setup
diskutil unmountDisk /dev/diskN ##remove MicroSD card from Mac
```
* Insert the MicroSD card into the RaspberryPi and connect it to your LAN
* Instructions for setting up your RaspberryPi
```
ssh -v raspberrypi  ## login as 'pi' with password 'raspberry'
sudo raspi-config   ## change hostname (e.g. ICSTool) and timezone
sudo apt-get -y update
sudo dpkg --configure -a
sudo apt-get -y upgrade
sudo apt-get -f install

sudo apt-get -y install tcsh    ## if you prefer tcsh over bsh
sudo apt-get -y install vim     ## if you prefer vi like editor
chsh -s /usr/bin/tcsh           ## change default shell to tcsh for user pi
sudo adduser --shell /usr/bin/tcsh --ingroup staff <<anotherUser>>  ## add anotherUser
sudo adduser <<anotherUser>> sudo   ## give sudo capabilities to anotherUser

sudo apt-get -y install apache2                 ## WEB server
sudo apt-get -y install libapache2-mod-perl2    ## PERL library
sudo htpasswd -cb <</usr/local/etc/httpdusers>> icsUser (*password*)    ## if you want WEB password protection

sudo reboot     ## when you are done
```
There are several options for allowing and configuring the RaspberryPi to work as a WEB server,
and generally it involves editing the files:
```
/etc/apache2/ports.conf
/etc/apache2/apache2.conf
/etc/network/interfaces
```
Example of /etc/network/interfaces with 2 static IPs.

```
auto lo
iface lo inet loopback

# iface eth0 inet dhcp
auto eth0:2
iface eth0:2 inet static
address 192.168.1.102
netmask 255.255.255.0
broadcast 192.168.1.255
dns-nameservers 8.8.8.8 8.8.4.4

auto eth0:1
iface eth0:1 inet static
address 104.57.229.92
netmask 255.255.255.248
gateway 104.57.229.94
broadcast 104.57.229.255

allow-hotplug wlan0
iface wlan0 inet manual
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

allow-hotplug wlan1
iface wlan1 inet manual
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

iface default inet dhcp

```
Example of /etc/apache2/ports.conf
```
ServerName icstool.tupl.us
Listen 80
Listen 8082

#<VirtualHost 192.168.1.102:80>
<VirtualHost *:80>
DocumentRoot /home/tom/Sites/EMPREP/ICSTool/PL/
ServerName icstool.tupl.us
ServerAlias icstool 
ErrorLog "/var/log/apache2/102.80-host.error_log"
</VirtualHost>

<VirtualHost 192.168.1.102:8082>
DocumentRoot /home/tom/Sites/EMPREP/ICSTool/PL/
ServerName icstool.tupl.us
ServerAlias icstool
ErrorLog "/var/log/apache2/102.8082-host.error_log"
</VirtualHost>

<VirtualHost 107.142.43.251:80>
DocumentRoot /home/tom/Sites/EMPREP/ICSTool/PL/
ServerName icstool.tupl.us
ServerAlias icstool
ErrorLog "/var/log/apache2/tupl-host-80.error_log"
</VirtualHost>

<VirtualHost 107.142.43.251:8082>
DocumentRoot /home/tom/Sites/EMPREP/ICSTool/PL/
ServerName icstool.tupl.us
ServerAlias icstool
ErrorLog "/var/log/apache2/tupl-host-8082.error_log"
</VirtualHost>

<IfModule mod_ssl.c>
# If you add NameVirtualHost *:443 here, you will also have to change
# the VirtualHost statement in /etc/apache2/sites-available/default-ssl
# to <VirtualHost *:443>
# Server Name Indication for SSL named virtual hosts is currently not
# supported by MSIE on Windows XP.
Listen 443
</IfModule>

<IfModule mod_gnutls.c>
Listen 443
</IfModule>
```
Example of /etc/apache2/apacheTU.conf which is included by /etc/apache2/apache2.conf
```
#TU add to /usr/apache2 to be Included in apache2.conf
# UserDir: The name of the directory that is appended onto a user's home
# directory if a ~user request is received.  Note that you must also set
# the default access control for these directories, as in the example below.
#
#UserDir Sites
#
# Control access to UserDir directories.  The following is an example
# for a site where these directories are restricted to read-only.
#
<IfModule mod_userdir.c>
#
# UserDir is disabled by default since it can confirm the presence
# of a username on the system (depending on home directory
# permissions).
#
#UserDir disabled
UserDir "enabled *"
UserDir "disabled root"

#
# To enable requests to /~user/ to serve the user's public_html
# directory, remove the "UserDir disabled" line above, and uncomment
# the following line instead:
#
UserDir Sites
</IfModule>

<Directory "/home/*/Sites">
Options ExecCGI Indexes Includes FollowSymLinks MultiViews
AllowOverride None
Order allow,deny
Allow from all
AuthName "tom Password Please"
AuthType Basic
AuthUserFile /usr/local/etc/httpdusers
Require user tom
</Directory>

<Directory "/home/tom/Sites/EMPREP">
Options Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
AllowOverride All
Order allow,deny
Allow from all
AuthName "EmPrep Password Please"
AuthType Basic
AuthUserFile /usr/local/etc/httpdusers
Require user tom emprep
</Directory>

<Directory "/home/tom/Sites/public/EMPREP">
Options Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
AddHandler cgi-script .cgi .pl
AllowOverride All
Order allow,deny
Allow from all
AuthName "Public Password Please"
AuthType Basic
AuthUserFile /usr/local/etc/httpdusers
Require user tom emprep public
</Directory>

<Files ~ "\.(pl|cgi)$">
Options Indexes Includes FollowSymLinks ExecCGI MultiViews
SetHandler perl-script
PerlResponseHandler ModPerl::Registry
</Files>

SetHandler perl-script
AddHandler perl-script .pl
AddHandler cgi-script .cgi

```

