# Домашнее задание: Работа с mdadm

| Основное задание: |
| ---               |

1. Добавить в Vagrantfile еще дисков
1. Сломать/починить raid
1. Собрать R0/R5/R10 на выбор
1. Прописать собранный рейд в конф, чтобы рейд собирался при загрузке
1. Создать GPT раздел и 5 партиций

* Задание со звездочкой
1. Vagrantfile, который сразу собирает систему с подключенным рейдом
1. Перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается.


| Решение: |
| ---      |

**1) vagrant up**

**2) vagrant ssh**

**3) Смотри что за диски**
```
[vagrant@lab2 ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   10G  0 disk
└─sda1   8:1    0   10G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
sdf      8:80   0  250M  0 disk
```
**4) Зануляем суперблоки:**
```
[root@lab2 vagrant]# mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```
**5) Создаем RAID10 с 4 дисками**
```
[root@lab2 vagrant]# mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

**6) Проверяем собранный RAID**
```
[root@lab2 vagrant]# cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

unused devices: <none>

[root@lab2 vagrant]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sat Jan 21 20:12:46 2023
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat Jan 21 20:12:49 2023
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : lab2:0  (local to host lab2)
              UUID : 93ac85c7:f2f423b6:5379a64a:f1712af9
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
```

**7) Смотрим инфу перед созданием mdadm.conf**
```
[root@lab2 vagrant]# mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=lab2:0 UUID=93ac85c7:f2f423b6:5379a64a:f1712af9
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
```
**8) Создаем mdadm.conf**
```
[root@lab2 ~]# mkdir /etc/mdadm
[root@lab2 ~]# echo "DEVICE partitions" | tee /etc/mdadm/mdadm.conf

[root@lab2 ~]# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf
ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=lab2:0 UUID=93ac85c7:f2f423b6:5379a64a:f1712af9
```
**9) Ломаем RAID**
```
[root@lab2 ~]# mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```
**10) Смотрим что получилось**
```
[root@lab2 ~]# cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[3](F) sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]
unused devices: <none>


[root@lab2 ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sat Jan 21 20:12:46 2023
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat Jan 21 20:42:34 2023
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : lab2:0  (local to host lab2)
              UUID : 93ac85c7:f2f423b6:5379a64a:f1712af9
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
[root@lab2 ~]# mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```
**12) Добавляем диск с массив**
```
[root@lab2 ~]# mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```
**13) Проверяем**
```
[root@lab2 ~]# cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sde[4] sdd[2] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
unused devices: <none>

[root@lab2 ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sat Jan 21 20:12:46 2023
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sat Jan 21 20:45:01 2023
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : lab2:0  (local to host lab2)
              UUID : 93ac85c7:f2f423b6:5379a64a:f1712af9
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       4       8       64        3      active sync set-B   /dev/sde
```
**14) Создаем раздел GPT**
```
[root@lab2 ~]# parted -s /dev/md0 mklabel gpt
```
**15) Создаем партиций**
```
[root@lab2 ~]# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

[root@lab2 ~]# parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

[root@lab2 ~]# parted /dev/md0 mkpart primary ext4 40% 60%
Information: You may need to update /etc/fstab.

[root@lab2 ~]# parted /dev/md0 mkpart primary ext4 60% 80%
Information: You may need to update /etc/fstab.

[root@lab2 ~]# parted /dev/md0 mkpart primary ext4 80% 100%
Information: You may need to update /etc/fstab.
```
**16) Создаем ФС на партициях**
```
[root@lab2 ~]# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 100352 1k blocks and 25168 inodes
Filesystem UUID: cada4f8f-d4a3-41a3-9457-26c934701651
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 101376 1k blocks and 25376 inodes
Filesystem UUID: 0eb6dccf-a04d-4e4a-ab5a-b541193a45b3
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 102400 1k blocks and 25688 inodes
Filesystem UUID: eb64c6c3-e30e-4838-9d62-f81caf32ae49
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 101376 1k blocks and 25376 inodes
Filesystem UUID: dc1d31fe-8b16-4e04-a1b5-2e444dfa30f1
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 100352 1k blocks and 25168 inodes
Filesystem UUID: af3e43f9-5ac1-431d-90de-e600829cbb39
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
**17) Создаем каталоги, куда смонтируются разделы**
```
[root@lab2 ~]# mkdir -p /raid/part{1,2,3,4,5}
[root@lab2 ~]# ls /raid/
part1  part2  part3  part4  part5
```
**18) Монтируем и проверяем**
```
[root@lab2 ~]# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
[root@lab2 ~]# lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda         8:0    0   10G  0 disk
└─sda1      8:1    0   10G  0 part   /
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
