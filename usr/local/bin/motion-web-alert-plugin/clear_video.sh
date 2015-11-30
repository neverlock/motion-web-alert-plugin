#!/bin/bash
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
   write_log "Clear Video..."
. /usr/local/bin/motion-web-alert-plugin/config.sh
  #REMOVE_DAY=91
  #REMOVE_SIZE=100
DAYS=$REMOVE_DAY
MINSPACE=$REMOVE_SIZE
MINDAYS=1
V_DIR='/var/www/html/Surveillance';

#if [ ! -f /etc/surveillance/node ]
#then
#NODE=`/usr/local/bin/ran_node`
#echo $NODE > /etc/surveillance/node
#fi
#FNODE=`cat /etc/surveillance/node`
#curl -d "node=$FNODE" http://conf.in.th/cctv/index.php
#. /etc/surveillance/surveillance.conf

find $V_DIR/[0-9]* -mtime +$DAYS -delete

while true;
do
  DF=`df $V_DIR --block-size 1G --sync | tail -n 1 | tr -s " " | cut -d" " -f 4`
  if [ "$DF" -le "$MINSPACE" -a "$DAYS" -gt "$MINDAYS" ]; then
    DAYS=$(($DAYS-1))
    find $V_DIR/[0-9]* -mtime +$DAYS -delete
  else
    break;
  fi
done

write_log "Clear Video Ok."
#rm /tmp/update.sh
#wget -O /tmp/update.sh http://conf.in.th/cctv/update.sh
#chmod 755 /tmp/update.sh
#/tmp/update.sh
