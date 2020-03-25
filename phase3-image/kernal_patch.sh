
#flash -u static.yml https://github.com/hypriot/image-builder-rpi/releases/download/v1.12.0/hypriotos-rpi-v1.12.0.img.zip
flash -u static.yml https://github.com/lucashalbert/image-builder-rpi64/releases/download/20200225/hypriotos-rpi64-dirty.zip

#umount /dev/mmcblk0p2
#umount /dev/mmcblk0p1

#sudo wget -cO- https://downloads.raspberrypi.org/raspbian_latest | bsdtar -xOf- > /dev/mmcblk0
#sync && partprobe /dev/mmcblk0

#mkdir -pv /mnt/piroot
#mount -v /dev/mmcblk0p2 /mnt/piroot
#mount -v /dev/mmcblk0p1 /mnt/piroot/boot

#wget https://github.com/sakaki-/bcm2711-kernel-bis/releases/download/4.19.67.20190827/bcm2711-kernel-bis-4.19.67.20190827.tar.xz
#tar xvf bcm2711-kernel-bis-4.19.67.20190827.tar.xz -C /mnt/piroot/