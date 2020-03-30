
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget

cd /tmp
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-3.2.1.tar.gz
tar xzf nrpe.tar.gz

cd /tmp/nrpe-nrpe-3.2.1/
#find a way to check for ssl-lib directory and pass correct one
./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/arm-linux-gnueabihf --enable-command-args
#./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/aarch64-linux-gnu --enable-command-args

make all

make install-groups-users

make install

make install-config

echo >> /etc/services
echo '# Nagios services' >> /etc/services
echo 'nrpe    5666/tcp' >> /etc/services

make install-init

systemctl enable nrpe.service

# configure firewall
iptables -I INPUT -p tcp --destination-port 5666 -j ACCEPT
apt-get install -y iptables-persistent
#Answer yes to saving existing rules

iptables-save > /etc/iptables/rule

# location of config: /usr/local/nagios/etc/nrpe.cfg

# allow nagios server
#allowed_hosts=127.0.0.1,192.168.68.150
sed -i '/^allowed_hosts=/s/$/,192.168.68.127/' /usr/local/nagios/etc/nrpe.cfg
sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg

systemctl start nrpe.service

# service commands
# systemctl start nrpe.service
# systemctl stop nrpe.service
# systemctl restart nrpe.service
# systemctl status nrpe.service


#plugins
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz

cd /tmp/nagios-plugins-release-2.2.1/
./tools/setup
./configure
make
make install

/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 -c check_load