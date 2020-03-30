
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget

cd /tmp
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-3.2.1.tar.gz
tar xzf nrpe.tar.gz

cd /tmp/nrpe-nrpe-3.2.1/
./configure
make check_nrpe
make install-plugin

/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 -c check_load