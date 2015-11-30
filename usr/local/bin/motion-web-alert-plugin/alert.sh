#!/bin/sh
if [ -z "$1" ]; then echo "\nEx.\n\t./alert.sh /var/www/Surveillance/2011/09/16/CAMERA1_2011-09-16_23-23.avi\n"; exit; fi
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
   write_log "==== ALERT START ===="
   write_log "file = $1"
. /usr/local/bin/motion-web-alert-plugin/config.sh
   if [ -z "$READ_CONF" ]; then  write_log '==== ALERT END ====' ; exit; fi

#Config path script && img file 
PATH_SCRIPT=' /usr/local/bin/motion-web-alert-plugin'
IMG_DEFAULT='/usr/local/bin/motion-web-alert-plugin/img_default_1.jpg'
IMG_DEFAULT1='/usr/local/bin/motion-web-alert-plugin/img_default_2.jpg'

#Config Value
FILE_VIDEO=$1
CAM_NO=`echo $FILE_VIDEO|awk -F'CAMERA' '{print $2}'|awk -F'_' '{print $1}'`
NAME_VIDEO="CAMERA`echo $FILE_VIDEO|awk -F'CAMERA' '{print $2}'|awk -F'.' '{print $1}'`"
PATH_VIDEO=`echo $FILE_VIDEO|awk -F"/CAMERA" '{print $1}'`
PATH_ALERT='ALERT/INTRU'
PATH_POWER='ALERT/POWER'
FILE_IMG="$PATH_VIDEO/$PATH_ALERT/$NAME_VIDEO.jpg"
FILE_POWER="$PATH_VIDEO/$PATH_POWER/$NAME_VIDEO.txt"

check_power(){
  write_log 'Check power down...'
  STATUS=`cat /etc/motion-web-alert-plugin/alert.power`
  if [ "$STATUS" = "1" ]
  then
    if [ ! -d "$PATH_VIDEO/$PATH_POWER" ]
    then
      write_log "Make DIR = $PATH_VIDEO/$PATH_POWER"
      mkdir -p $PATH_VIDEO/$PATH_POWER 2>/dev/null && write_log "Make DIR Ok" || write_log "Make DIR Failed!"
    else
      write_log "DIR = $PATH_VIDEO/$PATH_POWER"
    fi
    touch $FILE_POWER
  fi
  write_log 'Check power Ok'
}

save_images(){
  write_log 'Save images...'
  if [ ! -d "$PATH_VIDEO/$PATH_ALERT" ]
  then
    write_log "Make DIR = $PATH_VIDEO/$PATH_ALERT"
    mkdir -p $PATH_VIDEO/$PATH_ALERT 2>/dev/null && write_log "Make DIR Ok" || write_log "Make DIR Failed!"
  else
    write_log "DIR = $PATH_VIDEO/$PATH_ALERT"
  fi
  time=`ffmpeg -i $FILE_VIDEO 2>&1 | grep "Duration" | cut -d " " -f 4 -|sed s/,//`
  cut_time=`echo $time | awk -F':' '{print ($2*60+$3)/2}'`
  ffmpeg -i $FILE_VIDEO -f image2 -ss 0:0:$cut_time -vframes 1 $FILE_IMG 2>/dev/null
  write_log "Save picture = $FILE_IMG"
  [ -e "$FILE_IMG" ] && ( write_log 'Save Ok'; echo 0 ) || ( write_log 'Save Failed!'; echo 2 )
}

check_motion(){
  #sleep for check if after $WAIT/2 secound 
  #still have motion assume something wrong
  wait_time=`echo "$WAIT" |gawk '{print $1/2}'`
  write_log "Check Motion..."
  write_log "Movie = $FILE_VIDEO"
  write_log "Sleep = $wait_time sec..."
  sleep $wait_time
  SIZE1=`ls -al $FILE_VIDEO | awk -F' ' '{print $5}'`
  write_log "Size before = $SIZE1"
  write_log "Sleep = $wait_time sec..."
  sleep $wait_time
  SIZE2=`ls -al $FILE_VIDEO | awk -F" " '{print $5}'`
  write_log "Size after = $SIZE2"
  [ $SIZE2 -gt $SIZE1 ] && ( write_log "Detected Motion Ok"; echo 0 ) || \
( write_log "Dont SMS or Tweet: Motion is not continue over $WAIT Sec"; echo 2 )
}

check_day(){
  DAY_NOW=`date +%a`
  [ ! -z `echo $ALERT_DAY | grep $DAY_NOW` ] &&  echo 0 || echo 2
}

change_time () {
  echo `echo $1 |awk -F":" '{print ($1*60)+$2}'`
}

load_all_time(){
  case $1 in
  'Mon') echo $MO_ALL_TIME ;;
  'Tue') echo $TU_ALL_TIME ;;
  'Wed') echo $WE_ALL_TIME ;;
  'Thu') echo $TH_ALL_TIME ;;
  'Fri') echo $FR_ALL_TIME ;;
  'Sat') echo $SA_ALL_TIME ;;
  'Sun') echo $SU_ALL_TIME ;;
  esac 
}

load_time(){
  case $1 in
  'Mon') echo $MO_TIME ;;
  'Tue') echo $TU_TIME ;;
  'Wed') echo $WE_TIME ;;
  'Thu') echo $TH_TIME ;;
  'Fri') echo $FR_TIME ;;
  'Sat') echo $SA_TIME ;;
  'Sun') echo $SU_TIME ;;
  esac 
}

check_time(){
  DAY_NOW=`date +%a`
  if [ "`load_all_time "$DAY_NOW"`" = "1" ]; then echo 0; return 0; fi
  START_END=`load_time $DAY_NOW`
  NOW=`date +%R`; NOW=`change_time "$NOW"`
  START=`echo $START_END|awk -F'-' '{print $1}'` ; START=`change_time "$START"`
  END=`echo $START_END|awk -F'-' '{print $2}'` ; END=`change_time "$END"`
  if [ $START -gt $END ]
  then 
    if [ $NOW -ge $START ] || [ $NOW -le $END ]; then echo 0; return 0; fi 
  else
    if [ $NOW -ge $START ] && [ $NOW -le $END ]; then echo 0; return 0; fi 
  fi ; echo 2
}

images_resize(){
  write_log 'Resize images...'
  convert -resize 320x240 -quality 80 $1 /tmp/temp_pic_$$.jpg 2>/dev/null \
 && ( write_log "  Resize Ok"; echo "/tmp/temp_pic_$$.jpg" ) || ( write_log "  Resize Failed!"; echo "-" )
}

alert(){
  img=$1
  #====check day
  if [ "`check_day`" != "0" ]; then write_log "Today Not Alert!"; return 0; fi 
  #====check time
  if [ "`check_time`" != "0" ]; then write_log "This Time Not Alert!"; return 0; fi
  #====send alarm sig
  `$PATH_SCRIPT/alarm_sig.sh start 1`
  #====check tweet&&sms on,off
  if [ "$SMS_ON" != "1" ] || [ "$INTRUDE_SMS_ON" != "1" ]
  then 
    if [ "$TWITTER_ON" != "1" ] || [ "$INTRUDE_TWITTER_ON" != "1" ]
    then
      if [ "$PUSHBULLET_ON" != "1" ] || [ "$INTRUDE_PUSHBULLET_ON" != "1" ]
       then write_log "TWEET && SMS = 'OFF'" ; return 0
      fi
    fi 
  fi
  #====check internet connection
  [ `$PATH_SCRIPT/check_connection.sh` -eq 0 ] || return 0
  #====resize images
  img_resize="$IMG_DEFAULT"
  if [ "$img" = "0" ]
  then
    r_pic=`images_resize "$FILE_IMG"`
    [ "$r_pic" != "-" ] && img_resize="$r_pic"
  fi
  #====check tweet on,off
  if [ "$TWITTER_ON" = "1" ] && [ "$INTRUDE_TWITTER_ON" = "1" ] 
  then
     url_tweet=`$PATH_SCRIPT/tweet.sh "$INTRUDE_TWITTER_USER" "$INTRUDE_TWITTER_PASS" "$img_resize" "$TYPE_ALERT" "$INTRUDE_TWITTER_MSG"`
  else
    write_log "TWEET OFF"
  fi
  #====check sms on,off
  if [ "$SMS_ON" = "1" ] && [ "$INTRUDE_SMS_ON" = "1" ]
  then
    #====upload images return url 
    URL_IMAGE=''
    url_long=`$PATH_SCRIPT/images_upload.sh "$IMGUR_KEY" $img_resize`
    if [ "$url_long" != "-" ]
    then
      url_short=`$PATH_SCRIPT/short_url.sh $SHORT_URL_USER $SHORT_URL_KEY "$url_long"`
      [ "$url_short" != "-" ] && URL_IMAGE=$url_short || URL_IMAGE=$url_long
    fi
    #====send sms
    `$PATH_SCRIPT/sms_send.sh "$SMS_GATEWAY_USER" "$SMS_GATEWAY_PASSWORD" "$SMS_GATEWAY_URL" "$SMS_GATEWAY_POST" "$INTRUDE_SMS_MSG" "$URL_IMAGE" "$INTRUDE_SMS_PHONE"`
  else
    write_log "SMS OFF"
  fi 
  #=== pushbullet 
  if [ "$PUSHBULLET_ON" = "1" ] && [ "$INTRUDE_PUSHBULLET_ON" = "1" ]
  then
    #====upload images return url 
    URL_IMAGE=''
    url_long=`$PATH_SCRIPT/images_upload.sh "$IMGUR_KEY" $img_resize`
    if [ "$url_long" != "-" ]
    then
      url_short=`$PATH_SCRIPT/short_url.sh $SHORT_URL_USER $SHORT_URL_KEY "$url_long"`
      [ "$url_short" != "-" ] && URL_IMAGE=$url_short || URL_IMAGE=$url_long
    fi
    #====pushbullet send
    `$PATH_SCRIPT/pushbullet_send.sh "$INTRUDE_PUSHBULLET_MSG" "$INTRUDE_PUSHBULLET_TOKEN" "$INTRUDE_PUSHBULLET_CHANNEL" "$URL_IMAGE"`
  else
    write_log "PUSHBULLET OFF"
  fi 
  #====delete images temp
  if [ "$img_resize" != "$IMG_DEFAULT" ]; then `rm $img_resize` ; fi
}

#======= MAIN ========
check_power
if [ "`check_motion`" = "0" ]
then
  IMG_SAVE=`save_images`
  [ "$ALERT_ON" = "1" ] && [ "$INTRUDE_ON" = "1" ] && ( write_log "System Alert 'ON'"; alert $IMG_SAVE ) ||\
 ( write_log "System Alert 'OFF'" )
fi
#_______ MAIN _______

write_log "==== ALERT END   ===="
write_line
exit
