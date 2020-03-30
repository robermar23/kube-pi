set -e

# pre-reqs
sudo apt-get install autoconf gcc libc6 make wget unzip apache2 apache2-utils php libgd-dev -y

## download nagios
dir="/tmp/nagios/"
if [ ! -d $dir ]; then
   mkdir $dir
fi

cd $dir
 
if [ ! -f "nagios-4.4.2.tar.gz" ]; then
    wget "https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.2.tar.gz"
fi
       
if [ ! -f "nagios-plugins.tar.gz" ]; then
    wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
fi

## user and group
### rm users_added
if [ ! -f "users_added" ]; then
    sudo useradd -m -s /bin/bash nagios
    sudo groupadd nagcmd
    sudo usermod -a -G nagcmd nagios
    sudo usermod -a -G nagcmd www-data
    touch users_added
    echo "Nagios user and group added"
fi

# compile and install
if [ ! -d nagios-4.4.2 ]; then
    echo "Compiling nagios"
    tar zxvf nagios-4.4.2.tar.gz
    cd nagios-4.4.2
    ./configure --with-command-group=nagcmd
    make all
    sudo make install
    sudo make install-init
    sudo make install-config
    sudo make install-commandmode
else
    cd nagios-4.4.2
fi

# apache config for nagios
## enable cgi module
sudo a2enmod cgi

## copy the apache config to the apache folder
if [ ! -f /etc/apache2/sites-enabled/nagios.conf ] ; then
   sudo cp sample-config/httpd.conf /etc/apache2/sites-enabled/nagios.conf
   sudo htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin test123
   sudo service apache2 restart
   sudo service nagios start
   sudo ln -s /etc/init.d/nagios /etc/rcS.d/599nagios
fi

apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

if [ ! -d nagios-plugins-release-2.2.1 ]; then
    echo "Compiling plugins"
    tar zxf nagios-plugins.tar.gz
    cd nagios-plugins-release-2.2.1
    ./tools/setup
    ./configure
    make
    make install
    systemctl restart nagios.service
fi

