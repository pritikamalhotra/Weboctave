#!/bin/sh
# setup_weboctave.sh
# (C) 2010 by Hobson Lane dba TotalGood.com
# Released under the GNU public license.
#
# This script attempts to install weboctave automatically on an Ubuntu (Debian) system.
# It has only been tested 
#
# Weboctave is a php webapp that allows users to run octave scripts on a remote server.
# It display's both text output and plots but direct manipulation of graphics handles fail.

# this installs and starts the database and web servers
sudo aptitude install apache2 mysql
sudo /etc/init.d/mysql start
sudo /etc/init.d/apache2 start

# the installation above is pointless because the user must have already configured
# apache2 and mysql for this installation script to work

mysqlpass="defaultpassword"
mysqluser="root"
mysqlhost="localhost"
webfolder="/var/www"
apachehost="localhost"
woversion="0.1.0"
dbname="weboctavedb"
localfiledefault_pre="weboctave-"
localfiledefault_suf=".tar.bz2"
wourl="http://downloads.sourceforge.net/project/weboctave/weboctave/$woversion/${localfiledefault_pre}${woversion}${localfiledefault_suf}"
localfile=$wourl

# >&2 directs output to stderr, it can go before or after the text sent by echo
show_usage(){
  echo >&2 
  echo >&2 "usage: `basename $0` -p mysql_pw [-c] [-d] [-x] [-l] [~/weboctave-0.1.0.tar.bz] [-a www.localhost] [-u root] [-h mysql.localhost]  [-v 0.1.0] [-w http://downloads.sourceforge.net/project/weboctave/weboctave/0.1.0/weboctave-0.1.0.tar.bz]"
  echo >&2
  echo >&2 " Password option is required along with its argument:"
  echo >&2 "  -p MYSQL server password, required. default=root"
  echo >&2
  echo >&2 " Options that, if used, require arguments. Default arguments indicated:"
  echo >&2 "  -u MYSQL user name. default=root."
  echo >&2 "  -a Apache web server host name. default=localhost"
  echo >&2 "  -m MYSQL RDMS server host name. default=localhost"
  echo >&2 "  -v Version of weboctave to attempt to download. default=0.1.0"
  echo >&2 "  -f Folder to place php files in to be served. default=/var/www"
  echo >&2 "  -w Web URL of weboctave source code archive. default=http://downloads.sourceforge.net/project/weboctave/weboctave/0.1.0/weboctave-0.1.0.tar.bz"
  echo >&2
  echo >&2 " Options that don't require arguments and are not set by default:"
  echo >&2 "  -c Clean install: Delete old weboctave databases, files."
  echo >&2 "  -x Don't disable existing virtualhosts with a2dissite."
  echo >&2 "  -d Don't create virtualhosts file in /etc/apache2/sites-available."
  echo >&2 "  -l Local archive file of weboctave source code archive, default=\"\""
  echo >&2 "  -h Display this usage help page"
  echo >&2
}

while getopts "cdhl:p:a:u:m:v:w:" opt
do
  case "$opt" in
    c)  cleaninstall="yes";;
    x)  dontdeactivatevirtualhosts="yes";;
    d)  dontcreatevirtualhost="yes";;
    h)  show_usage;;
    l)  localfile=$OPTARG;;
    p)  mysqlpass="$OPTARG";;
    a)  apachehost="$OPTARG";;
    u)  mysqluser="$OPTARG";;
    m)  mysqlhost="$OPTARG";;
    v)  woversion="$OPTARG";;
    w)  wourl="$OPTARG";;
    f)  webfolder="$OPTARG";;
    \?) # unknown flag
      show_usage
      exit 1;;
  esac
done
shift `expr $OPTIND - 1`

if [ ! $localfile ]; then
  localfile="${localfiledefault_pre}${woversion}${localfiledefault_suf}"
fi
if [ $localfile = "$wourl" ]; then
  localfile=""
fi

echo $localfile
echo "Password: $mysqlpass"
echo "Don't deactivate web virtualhosts: $dontdeactivatevirtualhosts"
echo "Don't created virtualhost file: $dontenablevirtualhost"
if [ ! $localfile ]; then
  echo "Retrieving weboctave software from: $wourl";
else
  echo "Using local weboctave software archive: $localfile";
fi
echo "Weboctave version: $woversion"
echo "MYSQL host name: $mysqlhost"
echo "MYSQL command line to create a database:"
echo ">>mysql -u $mysqluser -p"${mysqlpass}" -h $mysqlhost -e \"create database $dbname;\""
echo "Apache host name: $apachehost"
echo "Local folder for web files= $webfolder"

if [ "$cleaninstall" = "yes" ]; then
  echo "Clean install: YES"
  mysql -u $mysqluser -p"${mysqlpass}" -h $mysqlhost -e "drop database $dbname;" 
  sudo rm -r "$webfolder/weboctave-$woversion"
  cd ~
else
   echo "Clean install: NO"
fi

if [ ! $localfile ]; then
  wget "$wourl" /tmp/
  # rebuild file name in case $woversion has be set by user
  $localfile="/tmp/`basename $wourl`"
fi
if [ ! -f $localfile ]; then
  echo "Error in `basename $0`: File \"$localfile\" does not exist."
  echo
  show_usage
fi

tar -xvf "$localfile"
sudo mv -u "weboctave-$woversion" "${webfolder}/"
cd "${webfolder}/weboctave-$woversion"
sudo chmod -R a+xw *.php
sudo chmod -R a+xw data
sudo chmod -R a+xw Logs
mysql -u $mysqluser -p"${mysqlpass}" -h $mysqlhost -e "create database $dbname;"
sed -i "s/^USE\ .*;\$/USE $dbname;/g" setup/db.sql
mv config/config.php.example config/config.php
mysql -u $mysqluser -p$mysqlpass -h $mysqlhost $dbname < setup/db.sql
sed -i "s/^define(\"DB_HOST\",\"\")\;\$/define(\"DB_HOST\",\"$mysqlhost\")\;/g" config/config.php
sed -i "s/^define(\"DB_USER\",\"\")\;\$/define(\"DB_USER\",\"$mysqluser\")\;/g" config/config.php
sed -i "s/^define(\"DB_PASSWORD\",\"\")\;\$/define(\"DB_PASSWORD\",\"$mysqlpass\")\;/g" config/config.php
sed -i "s/^define(\"DB_DATABASE\",\"\")\;\$/define(\"DB_DATABASE\",\"$dbname\")\;/g" config/config.php
apache2path="/etc/apache2"
if [ ! $dontdeactivatevirtualhosts ]; then
  echo "Deactivating all existing virtualhosts files..."
  sudo a2dissite `basename $apache2path/sites-enabled/*`
  sudo /etc/init.d/apache2 reload
fi
apache2sitesfile="$apache2path/sites-available/weboctave"
if [ ! $dontcreatevirtualhost ]; then
  echo "Creating virtualhost file..."
  sudo echo "<VirtualHost *:80>" | sudo tee "$apache2sitesfile"
  #ServerAdmin webmaster@localhost | sudo tee -a $apache2sitesfile
  sudo echo "ServerAlias $apachehost" | sudo tee -a $apache2sitesfile
  sudo echo "DocumentRoot $webfolder" | sudo tee -a $apache2sitesfile
  sudo echo "CustomLog /var/log/apache2/weboctave-access.log combined" | sudo tee -a $apache2sitesfile
  sudo echo "</VirtualHost>" | sudo tee -a $apache2sitesfile
  sudo a2ensite `basename $apache2sitesfile`
  sudo /etc/init.d/apache2 reload
fi
firefox "http://$apachehost/weboctave-$woversion/index.php"
#mysql -u $mysqluser -p$mysqlpass -h $mysqlhost -e setup/db.sql" script, but edit it first
#   to supply the database name.
#4) Copy "config/config.php.example" to "config/config.php".
#5) Edit "config/config.php" and set your preferences. 
#   You have to set database data.
#Now your WebOctave environment is ready to work and should be
#accessible by any web browser.

