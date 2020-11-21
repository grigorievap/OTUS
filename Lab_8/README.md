---
Задание:
---


**1. Определить алгоритм с наилучшим сжатием**
**2. Определить настройки pool’a**
**3. Найти сообщение от преподавателей**


---
Решение:
---

### https://zfsonlinux.org/ ###
### https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL%20and%20CentOS.html ###



**1) Смотрим наши диски**
```
[vagrant@zfs ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
sdc      8:32   0  512M  0 disk
sdd      8:48   0  512M  0 disk
sde      8:64   0  512M  0 disk
```

**2) Устанавливаем ZFS**
```
[vagrant@zfs ~]$ sudo yum install -y yum-utils
# Проверим нашу версию линуха (не ядро) чтоб скачать нужный пакет ZFS
[vagrant@zfs ~]$ cat /etc/*release
[vagrant@zfs ~]$ sudo yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
[vagrant@zfs ~]$ gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
# Включаем KMOD и отключаем DKMS
[vagrant@zfs ~]$ sudo yum-config-manager --enable zfs-kmod
[vagrant@zfs ~]$ sudo yum-config-manager --disable zfs
# Устанавливаем и подключаем модуль
[vagrant@zfs ~]$ sudo yum install -y zfs
[vagrant@zfs ~]$ sudo modprobe zfs
# Смотрим версию ZFS
[vagrant@zfs ~]$ zfs version
zfs-0.8.5-1
zfs-kmod-0.8.5-1
```

**3) Создаем и проверям пул**
```
[vagrant@zfs ~]$ sudo zpool create zfspool raidz1 /dev/sd[b-e]

[vagrant@zfs ~]$ zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfspool  1.88G   197K  1.87G        -         -     0%     0%  1.00x    ONLINE  -

[vagrant@zfs ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
├─sdb1   8:17   0  502M  0 part
└─sdb9   8:25   0    8M  0 part
sdc      8:32   0  512M  0 disk
├─sdc1   8:33   0  502M  0 part
└─sdc9   8:41   0    8M  0 part
sdd      8:48   0  512M  0 disk
├─sdd1   8:49   0  502M  0 part
└─sdd9   8:57   0    8M  0 part
sde      8:64   0  512M  0 disk
├─sde1   8:65   0  502M  0 part
└─sde9   8:73   0    8M  0 part

[vagrant@zfs ~]$ zpool status
  pool: zfspool
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        zfspool     ONLINE       0     0     0
          raidz1-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

[vagrant@zfs ~]$ df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        912M     0  912M   0% /dev
tmpfs           919M     0  919M   0% /dev/shm
tmpfs           919M  8.5M  911M   1% /run
tmpfs           919M     0  919M   0% /sys/fs/cgroup
/dev/sda1        40G  3.2G   37G   8% /
tmpfs           184M     0  184M   0% /run/user/1000
zfspool         1.3G  128K  1.3G   1% /zfspool
```

**4) **


















