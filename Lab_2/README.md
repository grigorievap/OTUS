---
Задание:
---

- Добавить в Vagrantfile еще дисков
- Сломать/починить raid
- Собрать R0/R5/R10 на выбор
- Прописать собранный рейд в конф, чтобы рейд собирался при загрузке
- Создать GPT раздел и 5 партиций

**В качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда, конф для автосборки рейда при загрузке**

\* доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом

\*\* перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).

---
Решение:
---

**1) vagrant up**

**2) vagrant ssh**

**3) Смотри что за диски**
```
[vagrant@otuslinux ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
sdf      8:80   0  250M  0 disk
```
**4) Зануляем суперблоки:**
```
[vagrant@otuslinux ~]$ sudo  mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```
**5) Создаем RAID10 с 4 дисками**
```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

**6) Проверяем собранный RAID**
```
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

unused devices: <none>

[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 16 19:16:17 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 16 19:16:23 2020
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : b496ec7c:bcb64210:5044661d:4c277083
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
```

**7) Смотрим инфу перед созданием mdadm.conf**
```
[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=b496ec7c:bcb64210:5044661d:4c277083
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
```
**8) Создаем mdadm.conf**
```
[vagrant@otuslinux ~]$ echo "DEVICE partitions" | sudo tee /etc/mdadm/mdadm.conf
[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=b496ec7c:bcb64210:5044661d:4c277083
[vagrant@otuslinux ~]$ cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=b496ec7c:bcb64210:5044661d:4c277083
[vagrant@otuslinux ~]$
```
**9) Ломаем RAID**
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```
**10) Смотрим что получилось**
```
[vagrant@otuslinux ~]$  cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[3](F) sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]

unused devices: <none>

[vagrant@otuslinux ~]$  cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[3](F) sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]

unused devices: <none>
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 16 19:16:17 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 16 21:12:12 2020
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : b496ec7c:bcb64210:5044661d:4c277083
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       -       0        0        3      removed

       3       8       64        -      faulty   /dev/sde
```
**11) Удаляем диск из массива**
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```
**12) Добавляем диск с массив**
```
[vagrant@otuslinux ~]$ sudo mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```
**13) Проверяем**
```
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[4] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

unused devices: <none>

[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Nov 16 19:16:17 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Nov 16 21:16:30 2020
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : b496ec7c:bcb64210:5044661d:4c277083
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       4       8       64        3      active sync set-B   /dev/sde
```
**14) Создаем раздел GPT**
```
[vagrant@otuslinux ~]$ sudo parted -s /dev/md0 mklabel gpt
```
**15) Создаем партиций**
```
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 0% 20%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 20% 40%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 40% 60%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 60% 80%
[vagrant@otuslinux ~]$ sudo parted /dev/md0 mkpart primary ext4 80% 100%
```
**16) Создаем ФС на партициях**
```
[vagrant@otuslinux ~]$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25168 inodes, 100352 blocks
5017 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1936 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25376 inodes, 101376 blocks
5068 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1952 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25688 inodes, 102400 blocks
5120 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1976 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25376 inodes, 101376 blocks
5068 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1952 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1024 blocks
25168 inodes, 100352 blocks
5017 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
13 block groups
8192 blocks per group, 8192 fragments per group
1936 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
**17) Создаем каталоги, куда смонтируются разделы**
```
[vagrant@otuslinux ~]$ sudo mkdir -p /raid/part{1,2,3,4,5}
[vagrant@otuslinux ~]$ ls /raid/
part1  part2  part3  part4  part5
```
**18) Монтируем и проверяем**
```
[vagrant@otuslinux ~]$ sudo -s
[root@otuslinux vagrant]#
[root@otuslinux vagrant]# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
[root@otuslinux vagrant]# exit
exit
[vagrant@otuslinux ~]$ lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda         8:0    0   40G  0 disk
└─sda1      8:1    0   40G  0 part   /
sdb         8:16   0  250M  0 disk
└─md0       9:0    0  496M  0 raid10
  ├─md0p1 259:0    0   98M  0 md     /raid/part1
  ├─md0p2 259:1    0   99M  0 md     /raid/part2
  ├─md0p3 259:2    0  100M  0 md     /raid/part3
  ├─md0p4 259:3    0   99M  0 md     /raid/part4
  └─md0p5 259:4    0   98M  0 md     /raid/part5
sdc         8:32   0  250M  0 disk
└─md0       9:0    0  496M  0 raid10
  ├─md0p1 259:0    0   98M  0 md     /raid/part1
  ├─md0p2 259:1    0   99M  0 md     /raid/part2
  ├─md0p3 259:2    0  100M  0 md     /raid/part3
  ├─md0p4 259:3    0   99M  0 md     /raid/part4
  └─md0p5 259:4    0   98M  0 md     /raid/part5
sdd         8:48   0  250M  0 disk
└─md0       9:0    0  496M  0 raid10
  ├─md0p1 259:0    0   98M  0 md     /raid/part1
  ├─md0p2 259:1    0   99M  0 md     /raid/part2
  ├─md0p3 259:2    0  100M  0 md     /raid/part3
  ├─md0p4 259:3    0   99M  0 md     /raid/part4
  └─md0p5 259:4    0   98M  0 md     /raid/part5
sde         8:64   0  250M  0 disk
└─md0       9:0    0  496M  0 raid10
  ├─md0p1 259:0    0   98M  0 md     /raid/part1
  ├─md0p2 259:1    0   99M  0 md     /raid/part2
  ├─md0p3 259:2    0  100M  0 md     /raid/part3
  ├─md0p4 259:3    0   99M  0 md     /raid/part4
  └─md0p5 259:4    0   98M  0 md     /raid/part5
sdf         8:80   0  250M  0 disk
```
**19) Провижинг в вагрант файле для автоматической сборки RAID 10**
```
box.vm.provision "shell", inline: <<-SHELL
	mkdir -p ~root/.ssh
	cp ~vagrant/.ssh/auth* ~root/.ssh
	yum install -y mdadm smartmontools hdparm gdisk
	# Script for RAID
	mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
	mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}
	mkdir -pm 700 /etc/mdadm
	echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
	mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
	parted -s /dev/md0 mklabel gpt
	parted /dev/md0 mkpart primary ext4 0% 20%
	parted /dev/md0 mkpart primary ext4 20% 40%
	parted /dev/md0 mkpart primary ext4 40% 80%
	parted /dev/md0 mkpart primary ext4 80% 90%
	parted /dev/md0 mkpart primary ext4 90% 100%
	for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i; done
	mkdir -p /raid/part{1,2,3,4,5}
	for i in $(seq 1 5); do  mount /dev/md0p$i /raid/part$i; done
SHELL
```


