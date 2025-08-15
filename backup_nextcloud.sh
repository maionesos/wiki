#!/bin/bash

#crontab
#0 4 * * 0 /bin/bash /root/backup_nextcloud.sh
#cron logs:
#grep CRON /var/log/syslog

lable=$(findfs LABEL="storage_d3")

if [[ $(df -h $lable | awk 'NR==2 {print $5}' | tr -d '%') -ge 99 ]]; then
	printf "Cannot backup nextcloud, requre more disck space.\nTotal: $(df -h $lable | awk ' NR==2 {print $2}')\nAvailable: $(df -h $lable | awk ' NR==2 {print $4}')" | mail -s "Nextcloud backup!" faizov@cg.ru
	exit 1
fi

test_bak=/backup/data
if [[ -d "$test_bak" ]]; then
	rsync -a --delete /nextcloud/data /backup/
else
	rsync -a /nextcloud/data /backup/
fi

if [[ $(ls /backup/data_* | wc -l) -gt 2 ]]; then
	cd /backup/ && ls -t data_* | tail -n +2 | xargs rm -f
fi

tar -czf /backup/data_$(date +%d.%m.%Y-%H.%M.%S).tar.gz -C /backup data

exit 0
