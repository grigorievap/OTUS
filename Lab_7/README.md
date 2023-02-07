# Домашнее задание: Работа с загрузчиком #

| Основное задание: |
| ---               |


1. Попасть в систему без пароля несколькими способами
1. Установить систему с LVM, после чего переименовать VG
1. Добавить модуль в initrd

* Задание со звездочкой
- Репозиторий с пропатченым grub: [ссылка](https://yum.rumyantsev.com/centos/7/x86_64/ ).
1. Сконфигурировать систему без отдельного раздела с __/boot__, а только с LVM.
- PV необходимо инициализировать с параметром --bootloaderareasize 1m


| Решение: |
| ---      |


## 1. Попасть в систему без пароля несколькими способами ##

**Способ 1**
+ При запуске ОС, нажимаем **e**, попадая в окно для редактирования загрузки
+ Удаляем в строке, начинающейся с linux16 опции **console=tty0** и  **console=ttyS0,115200n8**
+ Добавляем **init=/bin/sh** и нажимаем **ctrl-x**
+ Попадаем в систему с приглашением **sh-4.2#**
+ Аналогично если бы в системе мы выполнили бы **chroot /sysroot**
+ Смотрим что у нас примонтировано командой **mount | less** и самая верхняя строка выглядит - **sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)**
+ Смотрим **id** и видим **uid=0(root) gid=0(root) groups=0(root)**
+ Смотрим **mount -t xfs** видим что система подключена в режиме RO **/dev/sda1 on / type xfs (ro,relatime,attr2,inode64,noquota)**
+ Чтобы примонтировать в режим RW (для редактирования) необходимо выполнить **mount -o remount,rw /** после чего можно проверить **mount -t xfs**
+ Дальше уже можно скидывать пароль рута, если Selinux включен, то необходимо будет создать файлик в корне **/.autorelabel** чтоб Selinux 

**Способ 2**
+ Выполняем шаги из п. 1.1.1 по 1.1.2
+ Добавляем **rd.break** и нажимаем **ctrl-x**
+ Попадаем в систему с приглашением **switch_root:/#**
+ Смотрим что у нас примонтировано командой **mount | less** и самая верхняя строка выглядит - **rootfs on / type rootfs (rw)**
+ Смотрим **mount -t xfs** видим что система подключена в режиме RO **/dev/sda1 on / type xfs (ro,relatime,attr2,inode64,noquota)**
+ Чтобы примонтировать в режим RW (для редактирования) необходимо выполнить **mount -o remount,rw /** после чего можно проверить **mount -t xfs**
+ Чтоб скинуть пароль необходимо выполнить команду **chroot /sysroot**
+ **passwd root** - меняем пароль, дальше создаем файлик **/.autorelabel** командой **touch /.autorelabel** 
+ Выходим из **chroot** командой **exit**
+ Перемонтируем в режим RO **mount -o remount,ro /** и перегружаемся

**Способ 3**
+ Выполняем шаги из п. 1.1.1 по 1.1.2
+ Заменяем **ro** на **rw init=/sysroot/bin/sh** и нажимаем **ctrl-x**
+ Попадаем в систему с приглашением **:/#**
+ Смотрим что у нас примонтировано командой **mount | less** и самая верхняя строка выглядит - **rootfs on / type rootfs (rw)**
+ Смотрим **mount -t xfs** видим что система подключена в режиме RO **/dev/sda1 on /sysroot type xfs (rw,relatime,attr2,inode64,noquota)**
+ Видим что ФС сразу доступна на редактирование (**RW**)
+ Далее можно менять пароль рута...

## 2. Установить систему с LVM, после чего переименовать VG ##

**1) Смотрим настройки LVM**
```
[root@grub vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
[root@grub vagrant]#
[root@grub vagrant]#
[root@grub vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0
```

**2) Переименуем VG**
```
[root@grub vagrant]# vgrename VolGroup00 OtusLVM
  Volume group "VolGroup00" successfully renamed to "OtusLVM"
[root@grub vagrant]# vgs
  VG      #PV #LV #SN Attr   VSize   VFree
  OtusLVM   1   2   0 wz--n- <38.97g    0
```

**3) Смотрим настройки grub, проверяем имя старой VG**
```
[root@grub vagrant]# cat /etc/fstab | grep -i "Vol"
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0

[root@grub vagrant]# cat /etc/default/grub | grep -i "Vol"
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet"

[root@grub vagrant]# cat /boot/grub2/grub.cfg | grep -i "Vol"
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVo
00 rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet
```

**4) Переименуем старое имя в новое VG в настройках GRUB**
```
[root@grub vagrant]# sed -i 's/VolGroup00/OtusLVM/g' /etc/fstab
[root@grub vagrant]# sed -i 's/VolGroup00/OtusLVM/g' /etc/default/grub
[root@grub vagrant]# sed -i 's/VolGroup00/OtusLVM/g' /boot/grub2/grub.cfg
```

**5) Пересоздаем initrd image**
```
[root@grub vagrant]#  mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

**6) Перезагружаемся и проверяем**
```
[root@grub vagrant]# vgs
  VG      #PV #LV #SN Attr   VSize   VFree
  OtusLVM   1   2   0 wz--n- <38.97g    0
```

## 3. Добавить модуль в initrd ##

**1) Создаем папку в модулях драка и два файла + делаем их исполняемыми**
```
mkdir /usr/lib/dracut/modules.d/01test


[root@grub 01test]# cat module-setup.sh
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}

[root@grub 01test]# cat test.sh
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```

**2) Пересобираем образ initrd**
```
[root@grub vagrant]#  dracut -f -v
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

[root@grub vagrant]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
test
```

**3) Редактируем /boot/grub2/grub.cfg, удаляем rghb и quiet **

**4) Перезагружаемся и видим пингвина**
```
[  OK  ] Reached target Initrd Default Target.
         Starting dracut pre-pivot and cleanup hook...
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
 continuing....
[  OK  ] Started dracut pre-pivot and cleanup hook.
```
