#!/bin/bash

#Install prerequisites
yum update -y
yum groupinstall -y "Development Tools"

yum install -y gcc bc wget ncurses-devel bison flex elfutils-libelf-devel openssl-devel devtoolset-8
source /opt/rh/devtoolset-8/enable

#yum install -y yum kernel-devel kernel-headers rpm-build centos-release-scl
cd ~

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.3.tar.xz 
tar -xf linux-5.9.3.tar.xz 
rm -r linux-5.9.3.tar.xz 
cd linux-5.9.3
cp -v /boot/config-$(uname -r) .config
yes "" | make oldconfig
sudo make -j $(nproc) && sudo make modules_install

# Remove older kernels (Only for demo! Not Production!)
rm -f /boot/*3.10*
# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Reboot VM
shutdown -r now
