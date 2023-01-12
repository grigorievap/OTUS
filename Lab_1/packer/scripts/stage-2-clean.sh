#!/bin/bash

# clean all
sudo yum update -y
sudo yum clean all


# Install vagrant default key
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
sudo chmod 0600 /home/vagrant/.ssh/authorized_keys
sudo chown -R vagrant:vagrant /home/vagrant/.ssh


# Remove temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/log/wtmp /var/log/btmp
sudo rm -rf /var/cache/* /usr/share/doc/*
sudo rm -rf /var/cache/yum
sudo rm -rf /vagrant/home/*.iso
sudo rm -rf ~/.bash_history
sudo history -c

sudo rm -rf /run/log/journal/*

# Fill zeros all empty space
#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY
sync
grub2-set-default 0
echo "###   Hi from secone stage" >> /boot/grub2/grub.cfg
