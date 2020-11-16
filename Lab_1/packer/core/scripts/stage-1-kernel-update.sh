#!/bin/bash

#Install prerequisites
yum update -y
yum groupinstall -y "Development Tools"

yum install -y gcc bc wget ncurses-devel bison flex elfutils-libelf-devel openssl-devel kernel-devel kernel-headers rpm-build centos-release-scl
yum install -y devtoolset-8
source /opt/rh/devtoolset-8/enable

cd ~
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.3.tar.xz 
tar -xf linux-5.9.3.tar.xz 
rm -r linux-5.9.3.tar.xz 
cd linux-5.9.3
/bin/cp -rf /boot/config-$(uname -r)* .config
yes "" | make oldconfig

make -j $(nproc) rpm-pkg
/usr/bin/rpm -iUh --nodeps ~/rpmbuild/RPMS/x86_64/kernel-*.rpm

# Remove older kernels (Only for demo! Not Production!)
rm -f /boot/*3.10*
# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Reboot VM
shutdown -r now
