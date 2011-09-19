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

#config path
CONF='/etc/motion-web-alert-plugin'
PHONES=`cat $CONF/alert.sms`

#System 1 = 'ON' , 0 = 'OFF'
ALERT_ON=`cat $CONF/alert.on`
TWEET_ON=`cat $CONF/tweet.on`
SMS_ON=`cat $CONF/sms.on`

#video name , msg and type alert 
VIDEO_NAME=$1
TYPE_ALERT='Alert'
MSG_ALERT=`cat $CONF/alert.msg`

#api short url bit.ly
SHORT_URL_USER='chagridsada'
SHORT_URL_KEY='R_6e1997870f4320a119a9ed589bd52ef1'

#api send sms www.inanosms.com
SMS_SEND_USER='user'
SMS_SEND_PASSWORD='password'
SMS_PHONES="$PHONES"

#config val
WAIT=`cat $CONF/waits.time`
CAM_NO=`echo $VIDEO_NAME|awk -F"CAMERA" '{print $2}'|awk -F"_" '{print $1}'`
NAME=`echo $VIDEO_NAME|awk -F"/" '{print $8}'|awk -F"." '{print $1}'`
VIDEO_PATH=`echo $1|awk -F"/CAMERA" '{print $1}'`
ALERT_PATH='ALERT/INTRU'
IMG_SEC=`cat $CONF/images_sec.time`
IMG_PATH="$VIDEO_PATH/$ALERT_PATH/$NAME.jpg"

#val status
STATUS=['Ok','','Failed!']
CON=2
UPLOAD=2
SHORT=2
TWEET=2
SMS=2

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
  if [ -e "$IMG_PATH" ]
  then
    write_log "Save Ok"
    echo 0
  else
    write_log "Save Failed!"
    echo 2
  fi
write_line
}

check_motion(){
  write_log "Check Motion..."
  write_log "Movie : $VIDEO_NAME"
  write_log "Sleep : $WAIT sec..."
  #sleep for delay write video file
  sleep $WAIT
  SIZE1=`ls -al $VIDEO_NAME|awk -F" " '{print $5}'`
  write_log "Size : $SIZE1"
  write_log "Sleep : $WAIT sec..."
  #sleep for check if after $WAIT*2 secound 
  #still have motion assume something wrong
  sleep $WAIT
  SIZE2=`ls -al $VIDEO_NAME|awk -F" " '{print $5}'`
  write_log "Size : $SIZE2"
  if [ $SIZE2 -gt $SIZE1 ]
  then
    write_log "Detected Motion Ok"
    echo 0
  else
    write_log "Dont SMS or Tweet: Motion is not continue over $WAIT x 2 Sec"
    echo 2
  fi
write_line
}

check_day(){
  c_d=2
  for i in `tail -1 $CONF/alert.day`
  do
    DAY_NOW=`date +%a`
    if [ "$DAY_NOW" = "$i" ]
    then
      c_d=0
      break
    fi
  done
  echo $c_d
}

change_time () {
  HR=`echo $1 |awk -F":" '{print $1}'`
  MIN=`echo $1 |awk -F":" '{print $2}'`
  ALL=`expr \( $HR \* 60 \) + $MIN`
  echo $ALL
}

check_time(){
  c_t=2
  HR_NOW=`date +%H`
  MIN_NOW=`date +%M`
  NOW=`change_time $HR_NOW:$MIN_NOW`
  START=`head -1 $CONF/alert.time |awk -F"|" '{print $1}'`
  START=`change_time $START`
  END=`head -1 $CONF/alert.time |awk -F"|" '{print $2}'`
  END=`change_time $END`
  if [ $NOW -ge $START ] && [ $NOW -le $END ]
  then
   c_t=0
  fi
  echo $c_t
}

alert(){
  day=$1
  img=$2
  time=$3
  #====check day
  if [ $day -eq 2 ]
  then
    write_log "Today Not Alert!"
    return 0
  fi
  #====check time
  if [ $time -eq 2 ]
  then
    write_log "This Time Not Alert!"
    return 0
  fi
  #====check tweet&&sms on,off
  if [ ! $TWEET_ON -eq 1 ] && [ ! $SMS_ON -eq 1 ]
  then
    write_log "TWEET && SMS = 'OFF'"
    return 0
  fi
  #====check internet connection
  if [ `./check_connection.sh` -eq 2 ]
  then
    return 0
  else
    CON=0
  fi
  #====upload images return url 
  URL=''
  url_l=`./images_upload.sh $IMG_PATH`
  if [ $url_l != "-" ]
  then
    UPLOAD=0
    url_s=`./short_url.sh $SHORT_URL_USER $SHORT_URL_KEY $url_l`
    if [ $url_s != "-" ]
    then
      SHORT=0
      URL=$url_s
    else
      URL=$url_l
    fi
  fi
  #====check tweet on,off
  if [ $TWEET_ON -eq 1 ]
  then
    if [ `./tweet.sh $TYPE_ALERT "$MSG_ALERT $URL"` ]
    then
      TWEET=0
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
      SMS=0
    fi
  else
    write_log "SMS OFF"
  fi 
}

#======= MAIN ========
TIME=`check_time`
CHECK_DAY=`check_day`
if [ `check_motion` -eq 0 ]
then 
  IMG_SAVE=`save_images`
  if [ $ALERT_ON -eq 0 ]
  then
    write_log "System Alert 'OFF'"
    write_line
  else
    write_log "System Alert 'ON'"
    alert $CHECK_DAY $IMG_SAVE $TIME
  fi
fi
write_log "==== ALERT END ===="
write_line
