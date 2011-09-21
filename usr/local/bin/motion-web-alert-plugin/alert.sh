#!/bin/sh
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
if [ -z $1 ]
then 
  echo "Ex."
  echo "     ./alert.sh /var/www/Surveillance/2011/09/16/CAMERA1_2011-09-16_23-23.avi\n"
  exit
fi
write_log "==== ALERT $1 ===="
write_line

#Config path && Read configuration
CONF='/etc/motion-web-alert-plugin'
FILE_CONF='motion-web-alert-plugin.conf'
RUN_SCRIPT=' /usr/local/bin/motion-web-alert-plugin'
IMG_DEFAULT='/usr/local/bin/motion-web-alert-plugin/img_default_1.jpg'
READ_ALL_CONF=`cat $CONF/$FILE_CONF`

#Return value Configuration
get_val_config(){
  echo $READ_ALL_CONF | tr " " "\\n" | grep "$1" | awk -F"=" '{print $2}'
}

#System 1 = 'ON' , 0 = 'OFF'
ALERT_ON=`get_val_config "ALERT_ON="`
TWEET_ON=`get_val_config "TWEET_ON="`
SMS_ON=`get_val_config "SMS_ON="`

#Phone number
PHONES=`get_val_config "PHONES="`

#API KEY Imgur Upload Images
IMGUR_KEY=`get_val_config "IMGUR_KEY="`

#Username && Password API Send SMS www.inanosms.com
SMS_SEND_USER=`get_val_config "SMS_SEND_USER="`
SMS_SEND_PASSWORD=`get_val_config "SMS_SEND_PASSWORD="`
SMART_PHONES=`get_val_config "SMART_PHONES="`
SMS_PHONES="$PHONES"

#VIDEO Name && MSG && Type Alert 
VIDEO_NAME=$1
TYPE_ALERT=`get_val_config "TYPE_ALERT="`
MSG_ALERT=`get_val_config "MSG_ALERT=" | tr "+" " "`

#Username && Password Twitter
twitter_user=`get_val_config "twitter_user="`
twitter_pass=`get_val_config "twitter_pass="`

#Username && Key API bit.ly
SHORT_URL_USER=`get_val_config "SHORT_URL_USER="`
SHORT_URL_KEY=`get_val_config "SHORT_URL_KEY="`

#Config Value
WAIT=`get_val_config "WAIT="`
CAM_NO=`echo $VIDEO_NAME|awk -F"CAMERA" '{print $2}'|awk -F"_" '{print $1}'`
NAME=`echo $VIDEO_NAME|awk -F"/" '{print $8}'|awk -F"." '{print $1}'`
VIDEO_PATH=`echo $1|awk -F"/CAMERA" '{print $1}'`
ALERT_PATH='ALERT/INTRU'
IMG_SEC=`get_val_config "IMG_SEC="`
IMG_PATH="$VIDEO_PATH/$ALERT_PATH/$NAME.jpg"

save_images(){
  write_log "Save images..."
  if [ ! -d "$VIDEO_PATH/$ALERT_PATH" ]
  then
    write_log "Make DIR : $VIDEO_PATH/$ALERT_PATH"
    mkdir -p $VIDEO_PATH/$ALERT_PATH 2>/dev/null && write_log "Make DIR Ok" || write_log "Make DIR Failed!"
  else
    write_log "DIR : $VIDEO_PATH/$ALERT_PATH"
  fi
  ffmpeg -i $VIDEO_NAME -f image2 -ss 0:0:$IMG_SEC -vframes 1 $IMG_PATH 2>/dev/null
  write_log "Save picture : $IMG_PATH"
  [ -e "$IMG_PATH" ] && ( write_log "Save Ok"; echo 0 ) || ( write_log "Save Failed!"; echo 2 )
write_line
}

check_motion(){
  write_log "Check Motion..."
  write_log "Movie : $VIDEO_NAME"
  write_log "Sleep : $WAIT sec..."
  #sleep for delay write video file
  sleep $WAIT
  SIZE1=`ls -al $VIDEO_NAME | awk -F" " '{print $5}'`
  write_log "Size : $SIZE1"
  write_log "Sleep : $WAIT sec..."
  #sleep for check if after $WAIT*2 secound 
  #still have motion assume something wrong
  sleep $WAIT
  SIZE2=`ls -al $VIDEO_NAME | awk -F" " '{print $5}'`
  write_log "Size : $SIZE2"
  [ $SIZE2 -gt $SIZE1 ] && ( write_log "Detected Motion Ok"; echo 0 ) || \
( write_log "Dont SMS or Tweet: Motion is not continue over $WAIT x 2 Sec"; echo 2 )
write_line
}

check_day(){
  day=`get_val_config "ALERT_DAY="`
  DAY_NOW=`date +%a`
  [ ! -z `echo $day | grep $DAY_NOW` ] &&  echo 0 || echo 2
}

change_time () {
  HR=`echo $1 |awk -F":" '{print $1}'`
  MIN=`echo $1 |awk -F":" '{print $2}'`
  ALL=`expr \( $HR \* 60 \) + $MIN`
  echo $ALL
}

check_time(){
  HR_NOW=`date +%H`
  MIN_NOW=`date +%M`
  NOW=`change_time $HR_NOW:$MIN_NOW`
  START=`get_val_config "ALERT_TIME=" | awk -F"|" '{print $1}'`
  START=`change_time $START`
  END=`get_val_config "ALERT_TIME=" | awk -F"|" '{print $2}'`
  END=`change_time $END`
  [ $NOW -ge $START ] && [ $NOW -le $END ] &&  echo 0 ||  echo 2
}

images_resize(){
  write_log "Resize images..."
  convert -resize 320x240 -quality 80 $1 /tmp/temp_pic_$$.jpg 2>/dev/null \
 && ( write_log "  Resize : Ok"; echo "/tmp/temp_pic_$$.jpg" ) || ( write_log "  Resize : Failed!"; echo "-" )
  write_line
}

alert(){
  img=$1
  #====check day
  if [ `check_day` -eq 2 ]; then write_log "Today Not Alert!"; return 0; fi 
  #====check time
  if [ `check_time` -eq 2 ]; then write_log "This Time Not Alert!"; return 0; fi
  #====check tweet&&sms on,off
  if [ ! $TWEET_ON -eq 1 ] && [ ! $SMS_ON -eq 1 ]; then write_log "TWEET && SMS = 'OFF'"; return 0; fi
  #====check internet connection
  [ `$RUN_SCRIPT/check_connection.sh` -eq 0 ] || return 0
  #====resize images
  URL=""
  r_pic=""
  img_resize="$IMG_DEFAULT"
  if [ $img -eq 0 ]
  then
    #====check resize
    r_pic=`images_resize "$IMG_PATH"`
    [ ! $r_pic = "-" ] && img_resize=$r_pic
    if [ $SMS_ON -eq 1 ]
    then
      if [ $SMART_PHONES -eq 0 ] || [ $TWEET_ON -eq 0 ]
      then
        #====upload images return url 
        url_l=`$RUN_SCRIPT/images_upload.sh $IMGUR_KEY $img_resize`
        if [ $url_l != "-" ]
          then
            url_s=`$RUN_SCRIPT/short_url.sh $SHORT_URL_USER $SHORT_URL_KEY $url_l`
          if [ $url_s != "-" ]
          then
            URL=$url_s
          else
            URL=$url_l
          fi
        fi
        #____upload images
      fi
    fi
  fi
  #====check tweet on,off
  url_tweet=''
  if [ $TWEET_ON -eq 1 ]
  then
     url_tweet=`$RUN_SCRIPT/tweet.sh $twitter_user $twitter_pass $img_resize $TYPE_ALERT "$MSG_ALERT"`
  else
    write_log "TWEET OFF"
  fi
  #====delete images temp
  if [ ! -z $r_pic ]; then `rm $r_pic` ; fi
  #====check sms on,off
  if [ $SMS_ON -eq 1 ]
  then
    if [ $SMART_PHONES -eq 1 ] && [ $TWEET_ON -eq 1 ]
    then
      url_sms="$url_tweet/full"
      url_sms_s=`$RUN_SCRIPT/short_url.sh $SHORT_URL_USER $SHORT_URL_KEY "$url_sms"`
      [ $url_sms_s != "-" ] && url_sms=$url_sms_s
      `$RUN_SCRIPT/sms_send.sh $SMS_SEND_USER $SMS_SEND_PASSWORD "$MSG_ALERT $url_sms" $PHONES`
    else
      `$RUN_SCRIPT/sms_send.sh $SMS_SEND_USER $SMS_SEND_PASSWORD "$MSG_ALERT $URL" $PHONES`	
    fi
  else
    write_log "SMS OFF"
  fi 
}

#======= MAIN ========
if [ `check_motion` -eq 0 ]
then
  IMG_SAVE=`save_images`
  [ $ALERT_ON -eq 0 ] && ( write_log "System Alert 'OFF'"; write_line ) ||\
 ( write_log "System Alert 'ON'"; alert $IMG_SAVE )
fi
#_______ MAIN _______

write_log "==== ALERT END ===="
write_line
exit
