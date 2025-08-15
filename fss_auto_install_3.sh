 #!/bin/bash

if [ $(whoami) = root ] ; then
	echo
else
	echo -en "$color1b Нужно открыть скрипт рутом! Установка прервана. $color1e"
	exit 1
fi

LOGFILE=/tmp/fss_install.log
exec > >(tee -a $LOGFILE)
#exec 2>/dev/null
#exec 2>&1

color1b="\033[37;1;41m"
color1e="\033[0m"
color2b="\033[37;1;42m"
color2e="\033[0m"

echo -e "Установка АРМ ФСС на Альт Линукс!"
echo -en "$color2b Введите 'yes' для продолжения: $color2e"
read inputval
if test "$inputval" != "yes"
	then
	echo -en "$color1b Установка отменена :с $color1e"
	exit 1
fi

user1=$(who | grep '(:0)' | cut -d " " -f1)


mkdir /opt/certs
chmod 777 /opt/certs
env -i wget -nv --no-cache -P /tmp/ http://lk.fss.ru/sfr_certs_2025/sfr_prod_cert_2025.cer
mv /tmp/sfr_prod_cert_2025.cer /opt/certs/cert.cer

# Чек установлена ли БД 9.4:

if rpm -qa | grep -q postgresql9.4; then 
	echo "Уже имеется postgresql старой версии нужно удалить её и сделать бекап"
	echo -n " 'yes' для отмены установки или 'del' для удаления postgresql9.4 (бекапы не делаются!):"
read inputval1
if test "$inputval1" == "yes"
then
	echo -en "$color1b Установка отменена :с $color1e"
	exit 1
elif test "$inputval1" == "del"
then
	apt-get remove -y postgresql-common postgresql9.4
fi
fi

check_bd_table () {
    if psql -p 5433 -U postgres -lqt | grep -qw fss; then
      echo -en "$color2b Таблица ФСС уже существует в БД, сносить(del) или оставить её(go)?$color2e"
      read inputval_table_check
      if test "$inputval_table_check" == "del"; then
        psql -p 5433 -U postgres -c "DROP DATABASE fss;"
      fi
    fi
}

install_clean_table() {
psql -p 5433 -U postgres -c "CREATE USER fss WITH SUPERUSER LOGIN;"
psql -p 5433 -U postgres -c "CREATE DATABASE fss WITH ENCODING='UTF-8';"
}

test_file=/tmp/fss_log_bd

install_bd_postgres() {
    echo -en "$color1b Устанавливаем локальную бд: yes/no?? $color2e"
    read inputval2
    if test "$inputval2" == "no"; then
      echo
    elif test "$inputval2" == "yes"; then
    touch "$test_file"
    env -i apt-get update; env -i apt-get -y dist-upgrade
    env -i apt-get install -y postgresql10-server

    /etc/init.d/postgresql initdb

    echo listen_addresses = "'*'" >> /var/lib/pgsql/data/postgresql.conf
    sed -i 's/5432/5433/g' /lib/systemd/system/postgresql.service
    systemctl daemon-reload

    systemctl enable postgresql; systemctl restart postgresql
    echo -en "$color2b Если нужна была только БД, то можно прервать установку, прерываем? $color2e"
    echo -n " 'cancel' для отмены установки или 'go' для продолжения:"
    read inputvalBD

      if test "$inputvalBD" == "cancel"; then
        exit 1
      elif test "$inputvalBD" == "go"
        then
          echo
      fi

    fi
}

install_bd_for_eln() {
      install_clean_table
      env -i wget -nv --no-cache -P /tmp/ http://10.11.128.115/.pcstuff/test/backup_enl_null.sql
      psql -p 5433 -U postgres -d "fss" -f /tmp/backup_enl_null.sql
      psql -p 5433 -U postgres -c "ALTER DATABASE "fss" OWNER TO "fss";"
}

install_bd_for_ers() {
      install_clean_table
      env -i wget -nv --no-cache -P /tmp/ http://10.11.128.115/.pcstuff/test/backup_ers_empty.sql
      psql -p 5433 -U postgres -d "fss" -f /tmp/backup_ers_empty.sql
      psql -p 5433 -U postgres -c "ALTER DATABASE "fss" OWNER TO "fss";"
}

# Чек установлена ли БД 10:
if rpm -qa | grep postgresql10; then
	echo -en "$color1b База данных postgresql-10 уже установлена! Пропуск шага. $color2e"
else
  install_bd_postgres
  check_bd_table
fi 

##########################################################

install_fss_wine_8() {
    echo -en "$color2b Выберите номер программы: ФСС ЭРС - 1; ФСС ЭЛН - 2: $color2e"
    read inputval5
    if [ "$inputval5" == "1" ]; then
        su - ${user1} -c "cd /home/'$user1'/ && env -i wget --progress=bar:force --no-cache http://10.11.128.115/.pcstuff/test/fss/wine.fss.ers.tar.gz"
        su - ${user1} -c "tar -xf wine.fss.ers.tar.gz"
        if [ -f "$test_file" ]; then
            install_bd_for_ers
        fi
    elif [ "$inputval5" == "2" ]; then
        su - ${user1} -c "cd /home/'$user1'/ && env -i wget --progress=bar:force --no-cache http://10.11.128.115/.pcstuff/test/fss/wine.fss.eln.tar.gz"
        su - ${user1} -c "tar -xf wine.fss.eln.tar.gz"
        if [ -f "$test_file" ]; then
            install_bd_for_eln
        fi
    fi
}

install_fss_wine_10() {
    echo -en "$color2b Выберите номер программы: ФСС ЭРС - 1; ФСС ЭЛН - 2: $color2e"
    read inputval5
    if [ "$inputval5" == "1" ]; then
        su - ${user1} -c "cd /home/'$user1'/ && env -i wget --progress=bar:force --no-cache http://10.11.128.115/.pcstuff/test/fss/wine-10.8.1_fss_ers_x32.tar.gz"
        su - ${user1} -c "tar -xf wine-10.8.1_fss_ers_x32.tar.gz"
        if [ -f "$test_file" ]; then
            install_bd_for_ers
        fi
    elif [ "$inputval5" == "2" ]; then
        su - ${user1} -c "cd /home/'$user1'/ && env -i wget --progress=bar:force --no-cache http://10.11.128.115/.pcstuff/test/fss/wine-10.8.1_fss_eln.tar.gz"
        su - ${user1} -c "tar -xf wine-10.8.1_fss_eln.tar.gz"
        if [ -f "$test_file" ]; then
            install_bd_for_eln
        fi
    fi
}

#чек версии wine
check_wine=$(wine --version | head -n1  | awk '{print $1;}' | cut -d "-" -f2)
check_wine1="8.0.6"
check_wine2="10.8.1"
check_bottle=/home/$user1/.wine.fss

if [[ ${check_wine} == ${check_wine1} ]]; then
  if [[ -d $check_bottle ]]; then
    i=1
    while [ -d $check_bottle$i ]; do
      i=$((i+1))
    done
    mv /home/${user1}/.wine.fss /home/${user1}/.wine.fss.bak$1
  fi
  install_fss_wine_8
fi

if [[ ${check_wine} == ${check_wine2} ]]; then
  if [[ -d $check_bottle ]]; then
    i=1
    while [ -d $check_bottle$i ]; do
      i=$((i+1))
    done
    mv /home/${user1}/.wine.fss /home/${user1}/.wine.fss.bak$1
  fi
  install_fss_wine_10
fi

env -i wget -nv --no-cache -P /tmp/ http://10.11.128.115/.pcstuff/test/fss/run_fss_wine_10.sh
mv /tmp/run_fss_wine_10.sh /usr/bin/run_fss.sh
chmod 755 /usr/bin/run_fss.sh

env -i wget -nv --no-cache http://10.11.128.115/.pcstuff/gui/icons/fsslogo.ico
mv fsslogo.ico /etc/med/desktop/icons/

cat << '_EOF_' >  /home/$user1/Рабочий\ стол/АРМ\ ЛПУ.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=АРМ ЛПУ
Exec=/usr/bin/run_fss.sh
Icon=/etc/med/desktop/icons/fsslogo.ico
StartupNotify=true
Path=/usr/bin/
_EOF_

chown $user1:$user1 /home/$user1/Рабочий\ стол/АРМ\ ЛПУ.desktop
chmod +x /home/$user1/Рабочий\ стол/АРМ\ ЛПУ.desktop

# Cоздаем ярлычки

rm -f "/home/'$user1'/.local/share/applications/wine/Programs/СФР АРМ ЛПУ"
rm -f "/home/'$user1'/.local/share/applications/wine/Programs/СФР АРМ ЛПУ(ЭРС)"
rm -f /home/$user1/.local/share/applications/wine/Programs/wine-Programs-СФР*
rm -f /home/$user1/Рабочий\ стол/СФР\ АРМ\ ЛПУ.desktop
rm -f /home/$user1/wine.fss.*.tar.gz

echo -en "ФСС Установлено!"

