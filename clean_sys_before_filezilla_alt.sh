#!/bin/bash

# For Astra linux
# Удалить строку с генерированным hostname из /etc/hosts
# Написать HOSTNAME=localhost.localdomain в /etc/sysconfig/network

apt-get clean
systemctl stop salt-minion
rm -rfv /etc/salt/pki/minion/*
> /etc/salt/minion_id

swapoff -a; rm -fv /swapfile
rm -rfv /var/opt/cprocsp/keys/pc*
rm -rf /var/cache/salt/minion/files/base/files/*

> /root/.ssh/known_hosts
> /home/admin1/.ssh/known_hosts

systemctl enable salt-minion
apt-get remove klnagent64

sed 's/^HOSTNAME=.*/HOSTNAME=localhost.localdomain/' -i /etc/sysconfig/network

> /home/admin1/.bash_history
> /home/user/.bash_history
> /root/.bash_history

