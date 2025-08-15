#!/bin/bash

s="10.14.198."
s1="-o "StrictHostKeyChecking=no""
s2="/home/user/medkey.txt"
for i in $(seq 83 83); do
 ping -c 3 $s$i > /dev/null 2>&1
 if [ $? != 0 ]; then
 echo "$s$i is down." >> "/home/user/Рабочий стол/failed_ping.txt"
 else 
 echo "obama $s$i" >> /tmp/failed_ping.txt
fi 
 if rpm -qa | grep zabbix-common-4.4.4 > /dev/null; then
 echo "common +"
 else
 scp $s1 -i $s2 /tmp/zabbix-common.rpm root@$s$i:"/tmp/"
 ssh $s1 -i $s2 $s$i 'bash -s' < /tmp/zabbix.sh
fi
 if rpm -qa | grep zabbix-agent-4.4.4 > /dev/null; then
 echo "agent +"
 else
 scp $s1 -i $s2 /tmp/zabbix-agent_444.rpm root@$s$i:"/tmp/"
 ssh $s1 -i $s2 $s$i 'bash -s' < /tmp/zabbix.sh
fi
 if grep Server=10.14.198.250 /etc/zabbix/zabbix_agentd.conf > /dev/null; then
 ssh $s1 -i $s2 $s$i 'bash -s' < /tmp/zabbix1.sh
 else 
 scp $s1 -i $s2 '/tmp/zabbix_agentd.conf' root@$s$i:"/etc/zabbix"
  ssh $s1 -i $s2 $s$i 'bash -s' < /tmp/zabbix1.sh
fi
done