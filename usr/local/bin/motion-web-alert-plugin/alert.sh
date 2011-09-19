#!/bin/sh
. ./write_log.sh
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

#Username && Password API Send SMS www.inanosms.com
SMS_SEND_USER=`get_val_config "SMS_SEND_USER="`
SMS_SEND_PASSWORD=`get_val_config "SMS_SEND_PASSWORD="`
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

#val status
CON='Failed!'
UPLOAD='Failed!'
SHORT='Failed!'
TWEET='Failed!'
SMS='Failed!'

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

alert(){
  img=$1
  #====check day
  [ `check_day` -eq 0 ] || write_log "Today Not Alert!"; return 0
  write_log "Pass"
  #====check time
  [ `check_time` -eq 0 ] || write_log "This Time Not Alert!"; return 0
  #====check tweet&&sms on,off
  [ ! $TWEET_ON -eq 1 ] && [ ! $SMS_ON -eq 1 ] && ( write_log "TWEET && SMS = 'OFF'"; return 0 )
  #====check internet connection
  [ `./check_connection.sh` -eq 2 ] && return 0 || CON='Ok'
  #====resize images
  URL=''
  img_resize=''
  if [ $img -eq 0 ]
  then
    img_resize=`./images_resize $IMG_PATH`
    if [ $SMS_ON -eq 0 ]
    then
      #====upload images return url 
      url_l=`./images_upload.sh $img_resize`
      if [ $url_l != "-" ]
      then
        UPLOAD='Ok'
        url_s=`./short_url.sh $SHORT_URL_USER $SHORT_URL_KEY $url_l`
        if [ $url_s != "-" ]
        then
          SHORT='Ok'
          URL=$url_s
        else
          URL=$url_l
        fi
      fi
      #____upload images
    fi
  fi
  #====check tweet on,off
  if [ $TWEET_ON -eq 1 ]
  then
    if [ `./tweet.sh $twitter_user $twitter_pass $img_resize $TYPE_ALERT $MSG_ALERT` -eq 0 ]
    then
      TWEET='Ok'
    fi
  else
    write_log "TWEET OFF"
  fi
  #====check sms on,off
  if [ $SMS_ON -eq 1 ]
  then
    `./sms_send.sh $SMS_SEND_USER $SMS_SEND_PASSWORD "$MSG_ALERT $URL" $PHONES`
    if [ $? -eq 0 ]
    then
      SMS='Ok'
    fi
  else
    write_log "SMS OFF"
  fi 
}

#======= MAIN ========
if [ `check_motion` -eq 2 ]
then
  IMG_SAVE=`save_images`
  [ $ALERT_ON -eq 0 ] && ( write_log "System Alert 'OFF'"; write_line ) ||\
 ( write_log "System Alert 'ON'"; alert $IMG_SAVE )
fi
#_______ MAIN _______

write_log ":: CON=$CON , UPLOAD=$UPLOAD , SHORT=$SHORT , TWEET=$TWEET , SMS=$SMS"
write_log "==== ALERT END ===="
write_line

