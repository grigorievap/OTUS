# ZFS #
---

---
Задание:
---

1. Определить алгоритм с наилучшим сжатием
1. Определить настройки pool’a
1. Найти сообщение от преподавателей


---
Решение:
---

## 0. Установка ZFS ##

**0.1) Устанавливаем ZFS**

Прописываем в конфиг вагранта авто установки ZFS
```
box.vm.provision "shell", inline: <<-SHELL
	#install zfs repo
	yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
	#import gpg key 
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
	#install DKMS style packages for correct work ZFS
	yum install -y epel-release kernel-devel zfs
	#change ZFS repo
	yum-config-manager --disable zfs
	yum-config-manager --enable zfs-kmod
	yum install -y zfs
	#Add kernel module zfs
	modprobe zfs
	#install wget
	yum install -y wget
SHELL
```

## 1. Определить алгоритм с наилучшим сжатием ##
В Terminal (pwsh7) необходимо ввести команду, чтоб не ругался на права:
```
$Env:VAGRANT_PREFER_SYSTEM_BIN += 0
```
**1.0) Поднимаем и подключаемся к нашей виртуалке**
```
vagrant up
vagrant ssh
```

**1.1) Создаем пулы**
Смотрим список всех дисков, которые есть в виртуальной машине: lsblk
```
[vagrant@zfs ~]$ lsblk

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
sdc      8:32   0  512M  0 disk
sdd      8:48   0  512M  0 disk
sde      8:64   0  512M  0 disk
sdf      8:80   0  512M  0 disk
sdg      8:96   0  512M  0 disk
sdh      8:112  0  512M  0 disk
sdi      8:128  0  512M  0 disk
```

**1.2) Создаём пулы из дисков в режиме RAID 1:**
```
[root@zfs vagrant]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@zfs vagrant]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@zfs vagrant]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@zfs vagrant]# zpool create otus4 mirror /dev/sdh /dev/sdi
```

**1.3) Смотрим информацию о пулах:**
```
[root@zfs vagrant]# zpool list

NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -

[root@zfs vagrant]# zpool status
  pool: otus1
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors
```

**1.4) Устанавливаем сжатие на наши ДС**
```
[root@zfs vagrant]# zfs get compression
NAME   PROPERTY     VALUE     SOURCE
otus1  compression  off       default
otus2  compression  off       default
otus3  compression  off       default
otus4  compression  off       default

Алгоритм lzjb: zfs set compression=lzjb otus1
Алгоритм lz4:  zfs set compression=lz4 otus2
Алгоритм gzip: zfs set compression=gzip-9 otus3
Алгоритм zle:  zfs set compression=zle otus4

[root@zfs vagrant]# zfs get compression
NAME   PROPERTY     VALUE     SOURCE
otus1  compression  lzjb      local
otus2  compression  lz4       local
otus3  compression  gzip-9    local
otus4  compression  zle       local
```


**1.5) Скачиваем файлик и раскидываем его по ДС и смотрим уровень сжатия**
```
[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
[root@zfs vagrant]# ls -l /otus*

/otus1:
total 22036
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus2:
total 17981
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus3:
total 10953
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus4:
total 39963
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log


[root@zfs vagrant]# zfs list

NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.5M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.1M   313M     39.0M  /otus4

[root@zfs vagrant]# zfs get all | grep compressratio | grep -v ref

otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.64x                  -
otus4  compressratio         1.00x                  -
```
Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.


## 2. Определить настройки pool’a ##

**2.1) Скачиваем экспортированный Poll и распаковываем**

```
[root@zfs vagrant]# wget -O archive.tar.gz https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg

[root@zfs vagrant]# ll
total 7108
-rw-r--r--. 1 root root 7275140 Jan 21 18:16 archive.tar.gz

[root@zfs vagrant]# tar -xzf archive.tar.gz
[root@zfs vagrant]# ls zpoolexport/

filea  fileb
```

**2.2) Импортируем пул и проверяем его**
```
[root@zfs vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE
			
			

[root@zfs vagrant]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  21.6M   458M        -         -     0%     4%  1.00x    ONLINE  -
otus2   480M  17.7M   462M        -         -     0%     3%  1.00x    ONLINE  -
otus3   480M  10.8M   469M        -         -     0%     2%  1.00x    ONLINE  -
otus4   480M  39.1M   441M        -         -     0%     8%  1.00x    ONLINE  -

[root@zfs vagrant]# zpool import -d zpoolexport/ otus

[root@zfs vagrant]# zpool status
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

**2.3) Смотрим свойства пула**
```
[root@zfs vagrant]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupditto                     0                              default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      15987140508020829608           -
otus  autotrim                       off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local


[root@zfs vagrant]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

[root@zfs vagrant]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

[root@zfs vagrant]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

[root@zfs vagrant]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local

[root@zfs vagrant]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

```

## 3. Найти сообщение от преподавателей ##

**3.1) Скачиваем снапшот**
```
[root@zfs vagrant]# wget -O otus_task2.file --no-check-certificate 'https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download'
```

**3.2) Добавляем снапшот и восстанавливаем данные из него**
```
Файл был получен командой
zfs send otus/storage@task2 > otus_task2.file

[root@zfs vagrant]# zfs receive otus/storage < otus_task2.file

[root@zfs vagrant]# zfs list -t snapshot
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus/storage@task2     0B      -     2.83M  -

[root@zfs vagrant]# zfs rollback otus/storage@task2
```

**3.3) Находим сообщение**
```
[root@zfs vagrant]# find /otus/ -name secret_message
/otus/storage/task1/file_mess/secret_message

[root@zfs vagrant]# cat /otus/storage/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```
