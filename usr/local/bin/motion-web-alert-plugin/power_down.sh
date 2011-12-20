#!/bin/sh
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
   write_log "==== POWER DOWN START ===="
. /usr/local/bin/motion-web-alert-plugin/config.sh
   if [ -z "$READ_CONF" ]; then  write_log '==== POWER DOWN END ====' ; exit; fi

#Config path script 
PATH_SCRIPT=' /usr/local/bin/motion-web-alert-plugin'
IMG_DEFAULT1='/usr/local/bin/motion-web-alert-plugin/img_default_2.jpg'


NOW_PATH=`date +%Y/%m/%d`
NAME=`date "+%Y-%m-%d_%H-%M.txt"`
if [ ! -d "/var/www/Surveillance/$NOW_PATH/ALERT/POWER" ]
then
  mkdir -p /var/www/Surveillance/$NOW_PATH/ALERT/POWER
  chown -R motion:motion /var/www/Surveillance/$NOW_PATH
  fi
  echo "`date +%R`" >> /var/www/Surveillance/$NOW_PATH/ALERT/POWER/$NAME
#  touch /var/www/Surveillance/$NOW_PATH/ALERT/POWER/$NAME

power(){
  #====check tweet&&sms on,off
  if [ "$SMS_ON" != "1" ] || [ "$POWERDOWN_SMS_ON" != "1" ]
  then 
    if [ "$TWITTER_ON" != "1" ] || [ "$POWERDOWN_TWITTER_ON" != "1" ]
    then write_log "TWEET && SMS = 'OFF'" ; return 0
    fi 
  fi
  #====check internet connection
  [ `$PATH_SCRIPT/check_connection.sh` -eq 0 ] || return 0
  #====check tweet on,off
  if [ "$TWITTER_ON" = "1" ] && [ "$POWERDOWN_TWITTER_ON" = "1" ] 
  then
     url_tweet=`$PATH_SCRIPT/tweet.sh "$POWERDOWN_TWITTER_USER" "$POWERDOWN_TWITTER_PASS" "$IMG_DEFAULT1" "$TYPE_POWER" "$POWERDOWN_TWITTER_MSG"`
  else
    write_log "TWEET OFF"
  fi
  #====check sms on,off
  if [ "$SMS_ON" = "1" ] && [ "$POWERDOWN_SMS_ON" = "1" ]
  then
    #====send sms
    `$PATH_SCRIPT/sms_send.sh "$SMS_GATEWAY_USER" "$SMS_GATEWAY_PASSWORD" "$SMS_GATEWAY_URL" "$SMS_GATEWAY_POST" "$POWERDOWN_SMS_MSG" "-" "$POWERDOWN_SMS_PHONE"`
  else
    write_log "SMS OFF"
  fi 
}

#======= MAIN ========
  [ "$ALERT_ON" = "1" ] && [ "$POWERDOWN_ON" = "1" ] && ( write_log "System Alert power down 'ON'"; power "" ) ||\
 ( write_log "System Alert power down 'OFF'" )
#_______ MAIN _______

write_log "==== POWER DOWN END   ===="
write_line
exit
