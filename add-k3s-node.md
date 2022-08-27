# How to add a new K3s agent (worker) node

## OS

Raspberry Lite, latest, no desktop

## Post Image

touch ssh on image volume

## Post First Boot

from client
ssh-copy-id pi@[get ip address or hostname]
ssh pi@[get ip address or hostname]

sudo raspi-config
change:
- hostname
- password
- performance options: gpu memory to 16

add to /boot/cmdline.txt, at end:
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory

### disable ipv6
sudo nano /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv6.conf.eth0.disable_ipv6 = 1

sudo nano /etc/rc.local
Add this to the end (but before “exit 0”):

service procps reload


### nfs mounts
sudo mkdir /mnt/downloads && sudo mkdir /mnt/lidarr && sudo mkdir /mnt/radarr && sudo mkdir /mnt/sonarr && sudo mkdir /mnt/transmission && sudo mkdir /mnt/jackett

sudo nano /etc/fstab
rpi-nfs-01:/opt/nfs/downloads /mnt/downloads nfs rw,user,soft 0 0
rpi-nfs-01:/opt/nfs/lidarr /mnt/lidarr nfs rw,user,soft 0 0
rpi-nfs-01:/opt/nfs/radarr /mnt/radarr nfs rw,user,soft 0 0
rpi-nfs-01:/opt/nfs/sonarr /mnt/sonarr nfs rw,user,soft 0 0
rpi-nfs-01:/opt/nfs/transmission /mnt/transmission nfs rw,user,soft 0 0
rpi-nfs-01:/opt/nfs/jackett /mnt/jackett nfs rw,user,soft 0 0


reboot

## Install k3s agent

from client

cd  /home/revans/.arkade/bin/
./k3sup join --ip 192.168.68.154 --server-ip 192.168.68.149 --user pi

## Install cert-manager

arkade install cert-manager

