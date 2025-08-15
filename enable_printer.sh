#!/bin/bash

#crontab -l
#*/2 * * * * /bin/bash /root/enable_printer.sh

if lpstat -v | awk '{print $3}' | cut -d ':' -f1 | xargs -I {} lpstat -p {} | grep -q 'отключен'; then
    lpstat -v | awk '{print $3}' | cut -d ':' -f1 | xargs -L 1 -I {} lpadmin -p {} -E
fi

exit 0