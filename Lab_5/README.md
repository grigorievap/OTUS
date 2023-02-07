# Домашнее задание: Развернуть сервис NFS и подключить к нему клиента

| Основное задание: |
| ---               |

1. Vagrant up должен поднимать 2 виртуалки: сервер и клиент;
1. На сервер должна быть расшарена директория;
1. На клиента она должна автоматически монтироваться при старте (fstab или autofs);
1. В шаре должна быть папка upload с правами на запись;
1. Требования для NFS: NFSv3 по UDP, включенный firewall.

* Задание со звездочкой
\* Настроить аутентификацию через KERBEROS (NFSv4)


| Решение: |
| ---      |


## Настраиваем сервер NFS ##


- В Terminal (pwsh7) необходимо ввести команду, чтоб не ругался на права:
```
$Env:VAGRANT_PREFER_SYSTEM_BIN += 0
```

- Vagrant file
[Vagrant file](https://github.com/grigorievap/OTUS/tree/main/Lab_5/Vagrantfile)

```
vagrant up
```

- Заходим на сервер
``` 
vagrant ssh nfss 
``` 

- Доустанавливаем утилиты
```
[root@nfss vagrant]# yum install nfs-utils 
``` 

- Включаем firewall и проверяем, что он работает
``` 
[root@nfss vagrant]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
``` 

- Разрешаем в firewall доступ к сервисам NFS
``` 
[root@nfss vagrant]# firewall-cmd --add-service="nfs3" \
> --add-service="rpc-bind" \
> --add-service="mountd" \
> --permanent
success

[root@nfss vagrant]# firewall-cmd --reload
success
``` 

- 1. Включаем сервер NFS (для конфигурации NFSv3 over UDP он не требует дополнительной настройки, однако вы можете ознакомиться с умолчаниями в файле __/etc/nfs.conf__)
``` 
[root@nfss vagrant]# systemctl enable nfs --now
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
``` 

- Проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,  20048/tcp, 111/udp, 111/tcp (не все они будут использоваться далее,  но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения)
``` 
[root@nfss vagrant]# yum install net-tools

[root@nfss vagrant]# netstat -tulpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      343/rpcbind
tcp        0      0 0.0.0.0:20048           0.0.0.0:*               LISTEN      3434/rpc.mountd
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      674/sshd
tcp        0      0 0.0.0.0:53624           0.0.0.0:*               LISTEN      3425/rpc.statd
tcp        0      0 0.0.0.0:45561           0.0.0.0:*               LISTEN      -
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      917/master
tcp        0      0 0.0.0.0:2049            0.0.0.0:*               LISTEN      -
tcp6       0      0 :::111                  :::*                    LISTEN      343/rpcbind
tcp6       0      0 :::20048                :::*                    LISTEN      3434/rpc.mountd
tcp6       0      0 :::34737                :::*                    LISTEN      -
tcp6       0      0 :::22                   :::*                    LISTEN      674/sshd
tcp6       0      0 ::1:25                  :::*                    LISTEN      917/master
tcp6       0      0 :::2049                 :::*                    LISTEN      -
tcp6       0      0 :::54149                :::*                    LISTEN      3425/rpc.statd
udp        0      0 127.0.0.1:659           0.0.0.0:*                           3425/rpc.statd
udp        0      0 0.0.0.0:932             0.0.0.0:*                           343/rpcbind
udp        0      0 0.0.0.0:57792           0.0.0.0:*                           3425/rpc.statd
udp        0      0 0.0.0.0:2049            0.0.0.0:*                           -
udp        0      0 0.0.0.0:57403           0.0.0.0:*                           -
udp        0      0 127.0.0.1:323           0.0.0.0:*                           353/chronyd
udp        0      0 0.0.0.0:68              0.0.0.0:*                           2281/dhclient
udp        0      0 0.0.0.0:20048           0.0.0.0:*                           3434/rpc.mountd
udp        0      0 0.0.0.0:111             0.0.0.0:*                           343/rpcbind
udp6       0      0 :::932                  :::*                                343/rpcbind
udp6       0      0 :::38059                :::*                                -
udp6       0      0 :::2049                 :::*                                -
udp6       0      0 :::37660                :::*                                3425/rpc.statd
udp6       0      0 ::1:323                 :::*                                353/chronyd
udp6       0      0 :::20048                :::*                                3434/rpc.mountd
udp6       0      0 :::111                  :::*                                343/rpcbind
``` 

- Создаём и настраиваем директорию, которая будет экспортирована в будущем
``` 
[root@nfss vagrant]# mkdir -p /srv/share/upload
[root@nfss vagrant]# chown -R nfsnobody:nfsnobody /srv/share
[root@nfss vagrant]# chmod 0777 /srv/share/upload
``` 

- Создаём в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию
``` 
[root@nfss vagrant]# cat << EOF > /etc/exports
> /srv/share 192.168.50.11/32(rw,sync,root_squash)
> EOF
``` 

- Экспортируем ранее созданную директорию
``` 
[root@nfss vagrant]# exportfs -r 
``` 

- Проверяем экспортированную директорию следующей командой
``` 
[root@nfss vagrant]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
``` 


## Настраиваем клиент NFS ##


- Заходим на сервер
``` 
vagrant ssh nfsc 
``` 

- Доустановим вспомогательные утилиты
``` 
[root@nfsc vagrant]# yum install nfs-utils 
``` 

- Включаем firewall и проверяем, что он работает
 ``` 
[root@nfsc vagrant]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.

[root@nfsc vagrant]# systemctl status firewalld 
``` 

- Добавляем в __/etc/fstab__ строку
``` 
[root@nfsc vagrant]# echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
[root@nfsc vagrant]# systemctl daemon-reload
[root@nfsc vagrant]# systemctl restart remote-fs.target
``` 

Отметим, что в данном случае происходит автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к каталогу `/mnt/` 


- Заходим в директорию `/mnt/` и проверяем успешность монтирования
```
[root@nfsc vagrant]# cd /mnt

[root@nfsc mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=46,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26789)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
``` 

`vers=3` и `proto=udp`, соотвествует NFSv3 over UDP.


## Проверка работоспособности ##

- Заходим на сервер и переходим в каталог
```
[root@nfss vagrant]# cd /srv/share/upload
```

- Создаём тестовый файл
```
[root@nfss upload]# touch check_file
[root@nfss upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb  5 23:28 check_file
```

- Заходим на клиент и переходим в каталог
```
[root@nfsc mnt]# cd /mnt/upload
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb  5 23:28 check_file
```
- Создаём тестовый файл 
```
[root@nfsc upload]# touch client_file
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Feb  5 23:28 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  5 23:41 client_file
```

- Проверяем клиент:
- Перезагружаем клиент
```
[root@nfsc upload]# reboot
Connection to 127.0.0.1 closed by remote host.
```

- Заходим на клиент, переходим в каталог и проверяем файлы
```
[root@nfsc vagrant]# cd /mnt/upload
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Feb  5 23:28 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  5 23:41 client_file
```

- Проверяем сервер:
- Перезагружаем сервер
```
[root@nfss upload]# reboot
```

- Заходим на сервер
- Проверяем наличие файлов в каталоге 
```
[root@nfss vagrant]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 root      root      0 Feb  5 23:28 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  5 23:41 client_file
```

- Проверяем статус сервера NFS 
```
[root@nfss vagrant]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sun 2023-02-05 23:56:33 UTC; 3min 29s ago
```

- Проверяем статус firewall 
```
[root@nfss vagrant]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-02-05 23:56:29 UTC; 3min 59s ago
     Docs: man:firewalld(1)
 Main PID: 409 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─409 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 05 23:56:27 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 05 23:56:29 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 05 23:56:29 nfss firewalld[409]: WARNING: AllowZoneDrifting is enabled. This is considered ...now.
Hint: Some lines were ellipsized, use -l to show in full.
```

- Проверяем экспорты 
```
[root@nfss vagrant]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

- Проверяем работу RPC 
```
[root@nfss vagrant]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```

- Проверяем клиент:
- Возвращаемся на клиент
- Перезагружаем клиент
- Заходим на клиент
- Проверяем работу RPC 
```
[root@nfsc vagrant]# cd /mnt/upload
[root@nfsc mnt]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```

- Проверяем статус монтирования 
```
[root@nfsc upload]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=23,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10902)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)

[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Feb  5 23:28 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  5 23:41 client_file
```

- Создаём тестовый файл 
```
[root@nfsc upload]# touch final_check
```

- Проверяем, что файл успешно создан
```
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root      root      0 Feb  5 23:28 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  5 23:41 client_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  6 00:13 final_check
```

### Проверка прошла,стенд работоспособен и готов к работе. ###


## Создание автоматизированного Vagrantfile ## 

- [Vagrant файл](https://github.com/grigorievap/OTUS/tree/main/Lab_5/auto/Vagrantfile)
- [Скрипт для сервера](https://github.com/grigorievap/OTUS/tree/main/Lab_5/auto/nfss_script.sh)
- [Скрипт для клиента](https://github.com/grigorievap/OTUS/tree/main/Lab_5/auto/nfsc_script.sh)







































































