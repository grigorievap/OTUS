# ZFS #
---
Задание:
---

- Определить алгоритм с наилучшим сжатием
- Определить настройки pool’a
- Найти сообщение от преподавателей


---
Решение:
---


https://zfsonlinux.org/ 
https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL%20and%20CentOS.html 


## 0. Установка ZFS ##

**1) Устанавливаем ZFS**
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

##1. Определить алгоритм с наилучшим сжатием##

**1) Создаем и проверям пул**
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

**2) Создаем DataSet(ДС)**
```
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
```

**3) Глянем в ман и посмотрим какие методы сжатия есть, вместо gzip выбирем gzip-9 и остальные**
```
[vagrant@zfs ~]$ man zfs get | grep 'compression='
     deduplication consider using compression=on, as a less resource-intensive alternative.
                           by running: zfs set compression=on dataset.  The default value is off.
     compression=on|off|gzip|gzip-N|lz4|lzjb|zle
       # zfs set compression=off pool/home
       # zfs set compression=on pool/home/anne
```

**4) Устанавливаем сжатие на наши ДС**
```
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
```

**5) Скачиваем файлик и раскидываем его по ДС и смотрим уровень сжатия**
```
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
```

##2. Определить настройки pool’a##

**1) Скачиваем экспортированный Poll и распаковываем**
```
[vagrant@zfs ~]$ wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O zfs_task1.tar.gz

[vagrant@zfs ~]$ ls -lh
total 8.1M
-rw-rw-r--. 1 vagrant vagrant 1.2M May  6  2016 War_and_Peace.txt
-rw-rw-r--. 1 vagrant vagrant 7.0M Nov 21 15:42 zfs_task1.tar.gz

[vagrant@zfs ~]$ tar -xzf zfs_task1.tar.gz
[vagrant@zfs ~]$ ls zpoolexport/
filea  fileb
```

**2) Импортируем пул и проверяем его**
```
[vagrant@zfs ~]$ sudo zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE

[vagrant@zfs ~]$ zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfspool  1.88G  6.70M  1.87G        -         -     0%     0%  1.00x    ONLINE  -

[vagrant@zfs ~]$ sudo zpool import -d zpoolexport/ otus

[vagrant@zfs ~]$ zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus      480M  2.18M   478M        -         -     0%     0%  1.00x    ONLINE  -
zfspool  1.88G  6.70M  1.87G        -         -     0%     0%  1.00x    ONLINE  -

[vagrant@zfs ~]$ zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            2.04M   350M       24K  /otus
otus/hometask2  1.88M   350M     1.88M  /otus/hometask2
zfspool         4.95M  1.27G     37.4K  /zfspool
zfspool/fs01    1.19M  1.27G     1.19M  /zfspool/fs01
zfspool/fs02    1.19M  1.27G     1.19M  /zfspool/fs02
zfspool/fs03    1.20M  1.27G     1.20M  /zfspool/fs03
zfspool/fs04    1.19M  1.27G     1.19M  /zfspool/fs04

[vagrant@zfs ~]$ zpool list otus
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus   480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -

[vagrant@zfs ~]$ zpool status otus
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```

**3) Смотрим свойства пула**
```
[vagrant@zfs ~]$ zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

##3. Найти сообщение от преподавателей ##

**1) Скачиваем снапшот**
```
[vagrant@zfs ~]$ wget --no-check-certificate 'https://drive.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task2.file
```

**2) Добавляем снапшот и восстанавливаем данные из него**
```
Файл был получен командой
zfs send otus/storage@task2 > otus_task2.file

[vagrant@zfs ~]$ sudo zfs receive otus/storage < otus_task2.file

[vagrant@zfs ~]$ zfs list -t snapshot
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus/storage@task2     0B      -     2.83M  -

[vagrant@zfs ~]$ sudo zfs rollback otus/storage@task2
```

**3) Находим сообщение**
```
[vagrant@zfs ~]$ find /otus/ -name secret_message
/otus/storage/task1/file_mess/secret_message

[vagrant@zfs ~]$ cat /otus/storage/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```
