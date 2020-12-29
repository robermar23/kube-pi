apt-get update
apt-get upgrade -y

apt-get install -y iptables arptables ebtables nfs-common

update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
update-alternatives --set arptables /usr/sbin/arptables-legacy
update-alternatives --set ebtables /usr/sbin/ebtables-legacy

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get install -qy kubelet=1.17.4-00 kubectl=1.17.4-00 kubeadm=1.17.4-00


mkdir /mnt/downloads && chmod 777 /mnt/downloads && chown 1000:1000 /mnt/downloads
mkdir /mnt/jackett && chmod 777 /mnt/jackett && chown 1000:1000 /mnt/jackett
mkdir /mnt/lidarr && chmod 777 /mnt/lidarr && chown 1000:1000 /mnt/lidarr
mkdir /mnt/radarr && chmod 777 /mnt/radarr && chown 1000:1000 /mnt/radarr
mkdir /mnt/sonarr && chmod 777 /mnt/sonarr && chown 1000:1000 /mnt/sonarr
mkdir /mnt/ssd && chmod 777 /mnt/ssd && chown 1000:1000 /mnt/ssd
mkdir /mnt/transmission && chmod 777 /mnt/transmission && chown 1000:1000 /mnt/transmission