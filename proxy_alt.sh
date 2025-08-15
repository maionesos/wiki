#!/bin/bash

#ВСЁ С КОДИРОВАНИЕМ В URL!! 
all_proxy="http://govtatar%5cdet%2eclinic:1112qwe@i.tatar.ru:8080"

no_proxy1="qms-web.rkbrt.ru, *.tatar, 10.0.0.0/8, *.tatar.ru, *.tatarstan.ru, esia.gosuslugi.ru, mzrt.ezdrav.ru, operblock.ezdrav.ru, gist-aemd.ezdrav.ru"

sed -i -e '/HTTP_PROXY/d' -e '/HTTPS_PROXY/d' -e '/FTP_PROXY/d' -e '/NO_PROXY/d' /etc/sysconfig/network

echo -e "HTTP_PROXY=$all_proxy\nHTTPS_PROXY=$all_proxy\nFTP_PROXY=$all_proxy\nNO_PROXY=\"$no_proxy1\"" >> /etc/sysconfig/network


