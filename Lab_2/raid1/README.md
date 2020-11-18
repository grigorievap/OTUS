---
Задание:
---

### \*\* перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).###

---
Решение:
---

**1) Подключаемся к виртуалке, смотрим оба наших диска**
```
[root@otuslinux vagrant]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk
[root@otuslinux vagrant]# fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

**2) Создаем таблицу разделов на втором диске, такую же как и на первом**
```
[root@otuslinux vagrant]# sfdisk -d /dev/sda | sfdisk /dev/sdb
Checking that no-one is using this disk right now ...
OK

Disk /dev/sdb: 5221 cylinders, 255 heads, 63 sectors/track
sfdisk:  /dev/sdb: unrecognized partition table type

Old situation:
sfdisk: No partitions found

New situation:
Units: sectors of 512 bytes, counting from 0

   Device Boot    Start       End   #sectors  Id  System
/dev/sdb1   *      2048  83886079   83884032  83  Linux
/dev/sdb2             0         -          0   0  Empty
/dev/sdb3             0         -          0   0  Empty
/dev/sdb4             0         -          0   0  Empty
Warning: partition 1 does not end at a cylinder boundary
Successfully wrote the new partition table

Re-reading the partition table ...

If you created or changed a DOS partition, /dev/foo7, say, then use dd(1)
to zero the first 512 bytes:  dd if=/dev/zero of=/dev/foo7 bs=512 count=1
(See fdisk(8).)
```

**3) Проверяем что получилось**
```
[root@otuslinux vagrant]# fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048    83886079    41942016   83  Linux
[root@otuslinux vagrant]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk
└─sdb1   8:17   0  40G  0 part
```

**4) Меняем тип таблицы разделов 2 диска**
```
fdisk /dev/sdb
t - change a partition's system id
fd - Linux raid auto (16 HEX)
w - сохраняем

[root@otuslinux vagrant]# fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048    83886079    41942016   fd  Linux raid autodetect
```

**5) Добавляем партицию в массив**
```
[root@otuslinux vagrant]# mdadm --create /dev/md0 --level=1 --raid-disks=2 missing /dev/sdb1 --metadata=0.90
mdadm: array /dev/md0 started.
```

**6) Проверяем массив**
```
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdb1[1]
      41941952 blocks [2/1] [_U]

unused devices: <none>
[root@otuslinux vagrant]# mdadm -D /dev/md0
/dev/md0:
           Version : 0.90
     Creation Time : Tue Nov 17 16:22:29 2020
        Raid Level : raid1
        Array Size : 41941952 (40.00 GiB 42.95 GB)
     Used Dev Size : 41941952 (40.00 GiB 42.95 GB)
      Raid Devices : 2
     Total Devices : 1
   Preferred Minor : 0
       Persistence : Superblock is persistent

       Update Time : Tue Nov 17 16:22:29 2020
             State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              UUID : bc826959:23312fd5:8ed4a3a1:9f626544 (local to host otuslinux)
            Events : 0.1

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       17        1      active sync   /dev/sdb1
```

**7) Создаем ФС экст4 на нашем массиве**
```
[root@otuslinux vagrant]# mkfs.ext4 /dev/md0
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
2621440 inodes, 10485488 blocks
524274 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2157969408
320 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
```

**8) Синхронизация диска sda с RAID**
```
[root@otuslinux /]# mount /dev/md0 /mnt/
[root@otuslinux /]# rsync -auxHAXSv --exclude=/dev/* --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/mnt/* /* /mnt
```

**9) Монтируем системную информацию**
```
[root@otuslinux /]# mount --bind /proc /mnt/proc
[root@otuslinux /]# mount --bind /dev /mnt/dev
[root@otuslinux /]# mount --bind /sys /mnt/sys
[root@otuslinux /]# mount --bind /run /mnt/run
```

**9) Подключаемся к нашему новому корню, смотрим GUID массива и вносим изменения в fstab**
```
[root@otuslinux /]# chroot /mnt/
[root@otuslinux /]# blkid /dev/md*
/dev/md0: UUID="92ec95ee-2de5-445d-8ee0-3bb1d34a0475" TYPE="ext4"
[root@otuslinux /]# vi /etc/fstab
# Before
#UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
#/swapfile none swap defaults 0 0

#After
UUID=92ec95ee-2de5-445d-8ee0-3bb1d34a0475 / ext4 defaults 0 0
/swapfile none swap defaults 0 0
```

**10) Заносим информацию о массиве в mdadm.conf, делаем резервную копию и перестраиваем initramfs**
```
[root@otuslinux /]# mdadm --detail --scan > /etc/mdadm.conf
[root@otuslinux /]# cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bck
[root@otuslinux /]# dracut --mdadmconf --fstab --add="mdraid" --filesystems "xfs ext4 ext3" --add-drivers="raid1" --force /boot/initramfs-$(uname -r).img $(uname -r) -M
```

**11) Редактируем загрузчик, делаем новый конфиг и устанавливаем на диск sdb**
```
vi /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto rd.auto rd.auto=1 rhgb quiet"
GRUB_PRELOAD_MODULES="mdraid1x"

[root@otuslinux /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Found linux image: /boot/vmlinuz-3.10.0-1127.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-1127.el7.x86_64.img
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
done

[root@otuslinux /]# grub2-install /dev/sdb
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.
```

**12) Перезагружаемся, выбираем загрузку со второго диска**
**13) Проверяем что теперь загрузились со второго диска**
```
[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdb1[1]
      41941952 blocks [2/1] [_U]

unused devices: <none>
[root@otuslinux vagrant]# lsblk
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk
└─sda1    8:1    0  40G  0 part
sdb       8:16   0  40G  0 disk
└─sdb1    8:17   0  40G  0 part
  └─md0   9:0    0  40G  0 raid1 /
```

**14) Меняем тип таблицы разделов 1 диска так, как делали в п.4**
```
[root@otuslinux vagrant]# fdisk /dev/sda 
```

**15) Добавляем наш диск в массив и смотрим пока процесс ребилдинга не завершится и проверяем наш массив**
```
[root@otuslinux vagrant]# mdadm --manage /dev/md0 --add /dev/sda1
mdadm: hot added /dev/sda1

[root@otuslinux vagrant]# watch -n1 "cat /proc/mdstat"

[root@otuslinux vagrant]# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sda1[0] sdb1[1]
      41941952 blocks [2/2] [UU]

unused devices: <none>
```

**16) Устанавливаем теперь загрузчик на первый диск**
```
[root@otuslinux vagrant]# grub2-install /dev/sda
Installing for i386-pc platform.
Installation finished. No error reported.


[vagrant@otuslinux ~]$ sudo -s
[root@otuslinux vagrant]# lsblk
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk
└─sda1    8:1    0  40G  0 part
  └─md0   9:0    0  40G  0 raid1 /
sdb       8:16   0  40G  0 disk
└─sdb1    8:17   0  40G  0 part
  └─md0   9:0    0  40G  0 raid1 /
```

**17) Перезагружаемся и выбираем загрузку с разных дисков, проверяем, RAID работает :) **
