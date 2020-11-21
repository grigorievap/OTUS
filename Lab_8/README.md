---
Задание:
---


**1. Определить алгоритм с наилучшим сжатием**
**2. Определить настройки pool’a**
**3. Найти сообщение от преподавателей**


---
Решение:
---


https://zfsonlinux.org/ 
https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL%20and%20CentOS.html 


# Определить алгоритм с наилучшим сжатием #
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
[vagrant@zfs ~]$ sudo yum install -y yum-utils,wget
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

[vagrant@zfs ~]$ sudo zfs create zfspool/fs01
[vagrant@zfs ~]$ sudo zfs create zfspool/fs02
[vagrant@zfs ~]$ sudo zfs create zfspool/fs03
[vagrant@zfs ~]$ sudo zfs create zfspool/fs04

[vagrant@zfs ~]$ df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        912M     0  912M   0% /dev
tmpfs           919M     0  919M   0% /dev/shm
tmpfs           919M  8.5M  911M   1% /run
tmpfs           919M     0  919M   0% /sys/fs/cgroup
/dev/sda1        40G  3.2G   37G   8% /
tmpfs           184M     0  184M   0% /run/user/1000
zfspool         1.3G  128K  1.3G   1% /zfspool
zfspool/fs01    1.3G  128K  1.3G   1% /zfspool/fs01
zfspool/fs02    1.3G  128K  1.3G   1% /zfspool/fs02
zfspool/fs03    1.3G  128K  1.3G   1% /zfspool/fs03
zfspool/fs04    1.3G  128K  1.3G   1% /zfspool/fs04

[vagrant@zfs ~]$ zfs list
NAME           USED  AVAIL     REFER  MOUNTPOINT
zfspool        275K  1.28G     37.4K  /zfspool
zfspool/fs01  32.9K  1.28G     32.9K  /zfspool/fs01
zfspool/fs02  32.9K  1.28G     32.9K  /zfspool/fs02
zfspool/fs03  32.9K  1.28G     32.9K  /zfspool/fs03
zfspool/fs04  32.9K  1.28G     32.9K  /zfspool/fs04

[vagrant@zfs ~]$ man zfs get | grep 'compression='
     deduplication consider using compression=on, as a less resource-intensive alternative.
                           by running: zfs set compression=on dataset.  The default value is off.
     compression=on|off|gzip|gzip-N|lz4|lzjb|zle
       # zfs set compression=off pool/home
       # zfs set compression=on pool/home/anne
	   
[vagrant@zfs ~]$ zfs get compression
NAME          PROPERTY     VALUE     SOURCE
zfspool       compression  off       default
zfspool/fs01  compression  off       default
zfspool/fs02  compression  off       default
zfspool/fs03  compression  off       default
zfspool/fs04  compression  off       default

[vagrant@zfs ~]$ sudo zfs set compression=gzip-9 zfspool/fs01
[vagrant@zfs ~]$ sudo zfs set compression=lz4 zfspool/fs02
[vagrant@zfs ~]$ sudo zfs set compression=lzjb zfspool/fs03
[vagrant@zfs ~]$ sudo zfs set compression=zle zfspool/fs04

[vagrant@zfs ~]$ zfs get compression
NAME          PROPERTY     VALUE     SOURCE
zfspool       compression  off       default
zfspool/fs01  compression  gzip      local
zfspool/fs02  compression  lz4       local
zfspool/fs03  compression  lzjb      local
zfspool/fs04  compression  zle       local


[vagrant@zfs ~]$ wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8

[vagrant@zfs ~]$ sudo cp War_and_Peace.txt /zfspool/fs01
[vagrant@zfs ~]$ sudo cp War_and_Peace.txt /zfspool/fs02
[vagrant@zfs ~]$ sudo cp War_and_Peace.txt /zfspool/fs03
[vagrant@zfs ~]$ sudo cp War_and_Peace.txt /zfspool/fs04

[vagrant@zfs ~]$ zfs get compression
NAME          PROPERTY     VALUE     SOURCE
zfspool       compression  off       default
zfspool/fs01  compression  gzip-9    local
zfspool/fs02  compression  lz4       local
zfspool/fs03  compression  lzjb      local
zfspool/fs04  compression  zle       local

[vagrant@zfs ~]$ zfs get compressratio
NAME          PROPERTY       VALUE  SOURCE
zfspool       compressratio  1.08x  -
zfspool/fs01  compressratio  1.08x  -
zfspool/fs02  compressratio  1.08x  -
zfspool/fs03  compressratio  1.07x  -
zfspool/fs04  compressratio  1.08x  -

[vagrant@zfs ~]$ zfs list
NAME           USED  AVAIL     REFER  MOUNTPOINT
zfspool       4.94M  1.27G     37.4K  /zfspool
zfspool/fs01  1.19M  1.27G     1.19M  /zfspool/fs01
zfspool/fs02  1.19M  1.27G     1.19M  /zfspool/fs02
zfspool/fs03  1.20M  1.27G     1.20M  /zfspool/fs03
zfspool/fs04  1.19M  1.27G     1.19M  /zfspool/fs04
























