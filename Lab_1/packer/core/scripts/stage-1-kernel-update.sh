#!/bin/bash

#Install prerequisites for build kernel from source
yum install -y gcc bc wget ncurses-devel bison flex elfutils-libelf-devel openssl-devel
cd ~
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.tar.xz
tar -xf linux-5.4.tar.xz
cd linux-5.4
cp -v /boot/config-$(uname -r) .config
sudo make oldconfig && sudo make -j $(nproc) && sudo make modules_install

# Remove older kernels (Only for demo! Not Production!)
rm -f /boot/*3.10*
# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Reboot VM
shutdown -r now
