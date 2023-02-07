---
Задание:
---

### \*\* перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script). ###

---
Решение:
---

**1) Подключаемся к виртуалке, проверяем**
```
[root@lab2 vagrant]# fdisk -l

Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048    83886079    41942016   83  Linux

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux

[root@lab2 vagrant]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk
└─sdb1   8:17   0  40G  0 part
```

**2) Меняем тип таблицы разделов 2 диска**
```
fdisk /dev/sdb
t - change a partition's system id
fd - Linux raid auto (16 HEX)
w - сохраняем

[root@lab2 vagrant]# fdisk -l

Disk /dev/sdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1   *        2048    83886079    41942016   fd  Linux raid autodetect

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef1a

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux
```

**3) Добавляем партицию в массив**
```
[root@lab2 vagrant]# mdadm --create /dev/md0 --level=1 --raid-disks=2 missing /dev/sdb1 --metadata=0.90
mdadm: array /dev/md0 started.
```

**4) Проверяем массив**
```
[root@lab2 vagrant]# cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdb1[1]
      41941952 blocks [2/1] [_U]
unused devices: <none>

[root@lab2 vagrant]# mdadm -D /dev/md0
/dev/md0:
           Version : 0.90
     Creation Time : Sat Jan 21 23:31:25 2023
        Raid Level : raid1
        Array Size : 41941952 (40.00 GiB 42.95 GB)
     Used Dev Size : 41941952 (40.00 GiB 42.95 GB)
      Raid Devices : 2
     Total Devices : 1
   Preferred Minor : 0
       Persistence : Superblock is persistent

       Update Time : Sat Jan 21 23:31:25 2023
             State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              UUID : 944d2bbd:ba16b955:d28b5192:fc2de6af (local to host lab2)
            Events : 0.1

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       17        1      active sync   /dev/sdb1
```

**5) Создаем ФС экст4 на нашем массиве**
```
[root@lab2 vagrant]# mkfs.ext4 /dev/md0
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

**6) Синхронизация диска sda с RAID**
```
[root@lab2 ~]# mount /dev/md0 /mnt/
[root@lab2 ~]# rsync -axu / /mnt 

rsync -auxHAXSv / /mnt 

```

**7) Монтируем системную информацию**
```
[root@otuslinux /]# mount --bind /proc /mnt/proc
[root@otuslinux /]# mount --bind /dev /mnt/dev
[root@otuslinux /]# mount --bind /var /mnt/var
[root@otuslinux /]# mount --bind /sys /mnt/sys
[root@otuslinux /]# mount --bind /run /mnt/run
```

**8) Подключаемся к нашему новому корню, смотрим GUID массива и вносим изменения в fstab**
```
[root@lab2 ~]# chroot /mnt/
[root@lab2 /]# blkid /dev/md*
/dev/md0: UUID="b662982a-aa36-4e83-8b77-0a7772920fc5" BLOCK_SIZE="4096" TYPE="ext4"

[root@lab2 /]# vi /etc/fstab
#Before
#UUID=ea09066e-02dd-46ad-bac9-700172bc3bca /                       xfs     defaults        0 0
#/swapfile none swap defaults 0 0

#After
UUID=1fcfce7e-be80-4bbe-8add-b65d2cddf924 / ext4 defaults 0 0
/swapfile none swap defaults 0 0
```

grub2-mkconfig -o /boot/grub2/grub.cfg


**9) Заносим информацию о массиве в mdadm.conf, делаем резервную копию и перестраиваем initramfs**
```
[root@lab2 /]# mdadm --detail --scan > /etc/mdadm.conf
[root@lab2 /]# cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bck



[root@lab2 /]# dracut --mdadmconf --fstab --add="mdraid" --filesystems "xfs ext4 ext3" --add-drivers="raid1" --force /boot/initramfs-$(uname -r).img $(uname -r) -M
```

**10) Редактируем загрузчик, делаем новый конфиг и устанавливаем на диск sdb**
```
[root@lab2 /]# vi /etc/default/grub
GRUB_CMDLINE_LINUX="crashkernel=auto rd.auto rd.auto=1 rhgb quiet"
GRUB_PRELOAD_MODULES="mdraid1x"

[root@lab2 /]# exit
exit
[root@lab2 ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found CentOS Stream 8 on /dev/md0
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
done

[root@lab2 ~]# grub2-install /dev/sdb
Installing for i386-pc platform.
Installation finished. No error reported.
```

**11) Перезагружаемся, выбираем загрузку со второго диска**

**122) Проверяем что теперь загрузились со второго диска**
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

**17) Перезагружаемся и выбираем загрузку с разных дисков, проверяем, RAID работает :)**
