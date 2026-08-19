 #!/bin/bash

LOGFILE=/tmp/fss_install.log
exec > >(tee -a $LOGFILE)

user1=$(who | grep '(:0)' | cut -d " " -f1)

color1b="\033[37;1;41m"
color1e="\033[0m"
color2b="\033[37;1;42m"
color2e="\033[0m"

echo -e "Установка АРМ ФСС на Астра Линукс!"
echo -en "$color2b Введите 'yes' для продолжения: $color2e\n"
read inputval
if test "$inputval" != "yes"; then
	echo -en "$color1b Установка отменена :с $color1e\n"
	exit 0
fi

if [ $(whoami) = root ]; then
    echo
else
    echo -en "$color1b Нужно открыть скрипт рутом! Установка прервана. $color1e\n"
    exit 1
fi

# Установка только для wine 10!
# wine --version | awk '{print $1}'
# wine-10.10.6-eter1astra | wine-10.10.8-eter1astra

# Файл с установщиком ФСС x64 должен лежать в загрузках пользователя.
fss_files=$(ls /home/$user1/Загрузки/fss_*_setup_*_x64.exe | wc -l)
if (("$fss_files" <= 0)); then
	echo -en "$color1e Программа для установки не скачана! Введите 'yes' для продолжения. $color2e\n"
	read inputval
	if test "$inputval" != "yes"; then
		echo -en "$color1b Установка отменена :с $color1e\n"
		exit 0
	fi
fi

# Установка корневого
if ! test -d /opt/certs; then
	mkdir /opt/certs
	chmod 777 /opt/certs
fi

date_pc=$(date +%s)
date_fsr_cert_end='1790974800'

if [[ "$date_pc" -le "$date_fsr_cert" ]]; then
	env -i wget -nv --no-cache -P /tmp/ http://lk.fss.ru/sfr_certs_2025/sfr_prod_cert_2025.cer
	mv /tmp/sfr_prod_cert_2025.cer /opt/certs/cert.cer
fi

# Установка БД
test_file=/tmp/fss_log_bd

install_bd_postgres() {
  echo -en "$color1b Устанавливаем локальную бд: yes/no?? $color2e\n"
  read inputval2
  if test "$inputval2" == "no"; then
    echo
  elif test "$inputval2" == "yes"; then
    touch "$test_file"
    env -i apt-get update
    env -i apt-get install -y postgresql-11 postgresql-client-11

    /etc/init.d/postgresql initdb
    systemctl stop postgresql

    sed -i 's/5432/5433/' /etc/postgresql/11/main/postgresql.conf
    sed -i '/postgres/s/peer/trust/' /etc/postgresql/11/main/pg_hba.conf

    systemctl daemon-reload
    systemctl enable --now postgresql

    echo -en "$color2b Если нужна была только БД, то можно прервать установку, прерываем? $color2e\n"
    echo -en "$color2b (cancel) $color2e для отмены установки или $color2b (go) $color2e для продолжения:\n"
    read inputvalBD

    if test "$inputvalBD" == "cancel"; then
      exit 0
    elif test "$inputvalBD" == "go"; then
      echo
    fi
  fi
}

check_bd_table () {
    if psql -p 5433 -U postgres -lqt | grep -qw fss; then
      echo -en "$color2b Таблица ФСС уже существует в БД, сносить(del) или оставить её(go)?$color2e\n"
      read inputval_table_check
      if test "$inputval_table_check" == "del"; then
        psql -p 5433 -U postgres -c "DROP DATABASE fss;"
      fi
    fi
}

# Чек установлена ли БД
bd_check_install=$(dpkg-query -f='${Status}\n' -W postgresql-client-11)

if [ "$bd_check_install" == "install ok installed" ]; then
  echo -en "$color1b База данных postgresql-11 уже установлена! Пропуск шага. $color2e\n"
else
  install_bd_postgres
  check_bd_table
fi

install_clean_table() {
	psql -p 5433 -U postgres -c "CREATE USER fss SUPERUSER LOGIN PASSWORD 'fss';"
	psql -p 5433 -U postgres -c "CREATE DATABASE fss WITH ENCODING='UTF-8';"
}

install_bd_for_eln() {
	env -i wget -nv --no-cache -P /tmp/ https://med-repo.tatar.ru/.pcstuff/test/backup_enl_null.sql
  install_clean_table
	psql -p 5433 -U postgres -d "fss" -f /tmp/backup_enl_null.sql
	psql -p 5433 -U postgres -c "ALTER DATABASE "fss" OWNER TO "fss";"
  rm -f /tmp/backup_enl_null.sql
}

install_bd_for_ers() {
	env -i wget -nv --no-cache -P /tmp/ https://med-repo.tatar.ru/.pcstuff/test/backup_ers_empty.sql
  install_clean_table
	psql -p 5433 -U postgres -d "fss" -f /tmp/backup_ers_empty.sql
	psql -p 5433 -U postgres -c "ALTER DATABASE "fss" OWNER TO "fss";"
  rm -f /tmp/backup_ers_empty.sql
}

# Чек версии wine
check_wine=$(wine --version | head -n1  | awk '{print $1;}' | cut -d "-" -f2)
check_wine_10_6="10.10.6"
check_wine_10_8="10.10.8"
check_bottle=/home/$user1/.wine.fss
destop_base=/home/$user1/Рабочий\ стол/
date_bak=$(date +%H:%M:%S-%d.%m.%Y)

check_bottle_10() {
if [[ "$check_wine" == "$check_wine_10_6" || "$check_wine_10_8" ]]; then
  if [[ -d "$check_bottle" ]]; then
    mv /home/${user1}/.wine.fss /home/${user1}/.wine.fss_"$date_bak"
  fi
  su - ${user1} -c "cp -vr /etc/skel/.wine /home/'$user1'/.wine.fss && rm -rf /home/'$user1'/.wine.fss/drive_c/Vitacore" || exit 1
fi
}

# Установка ФСС
install_fss_wine_10_ers() {
  check_bottle_10
  su - ${user1} -c "DISPLAY=:0.0 XAUTHORITY=/var/run/lightdm/'$user1'/xauthority WINEPREFIX=~/.wine.fss wine '$selected_program' >/dev/null 2>&1"
  su - ${user1} -c "cd ~/.wine.fss/drive_c/Fss* && WINEPREFIX=~/.wine.fss wine ~/.wine.fss/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/RegAsm.exe /registered GostCryptography.dll >/dev/null 2>&1"
  desktop_ers=СФР\ АРМ\ ЛПУ\(ЭРС\).desktop
  sed -i -e '/Exec/s/^/#/' -e '/Path/s/^/#/' "$destop_base$desktop_ers"
  printf 'Exec=/usr/bin/run_fss.sh\nPath=/usr/bin/\n' >> "$destop_base$desktop_ers"
  if [ -f "$test_file" ]; then
    install_bd_for_ers
  fi
}

install_fss_wine_10_eln() {
  check_bottle_10
  su - ${user1} -c "DISPLAY=:0.0 XAUTHORITY=/var/run/lightdm/'$user1'/xauthority WINEPREFIX=~/.wine.fss wine '$selected_program' >/dev/null 2>&1"
  su - ${user1} -c "cd ~/.wine.fss/drive_c/Fss* && WINEPREFIX=~/.wine.fss wine ~/.wine.fss/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319/RegAsm.exe /registered GostCryptography.dll >/dev/null 2>&1"
  desktop_eln=СФР\ АРМ\ ЛПУ.desktop
  sed -i -e '/Exec/s/^/#/' -e '/Path/s/^/#/' "$destop_base$desktop_eln"
  printf 'Exec=/usr/bin/run_fss.sh\nPath=/usr/bin/\n' >> "$destop_base$desktop_eln"
  if [ -f "$test_file" ]; then
    install_bd_for_eln
  fi
}

programs=(/home/"$user1"/Загрузки/fss_*.exe)

for ((i=0; i<${#programs[@]}; i++)); do
  echo "$((i+1)). ${programs[i]}"
done

text_install=$(echo -en "$color2b Указываем какую программу необходимо установить (прописать цифру)$color2e\n")
read -p "$text_install" choice

if [[ $choice =~ ^[1-${#programs[@]}]$ ]]; then
  selected_program="${programs[$((choice-1))]}"
  echo "Выбранная программа: $selected_program"
else
  echo "Некорректный выбор."
fi

if echo $selected_program | grep 'ers' >/dev/null 2>&1; then
  install_fss_wine_10_ers
else
  install_fss_wine_10_eln
fi

env -i wget -nv --no-cache -P /tmp/ https://med-repo.tatar.ru/.pcstuff/test/fss/run_fss_wine_10.sh
rm -f /usr/bin/run_fss.sh
mv /tmp/run_fss_wine_10.sh /usr/bin/run_fss.sh
chmod 755 /usr/bin/run_fss.sh

echo -en "$color1b ФСС Установлено! $color1e\n"
