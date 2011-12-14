#!/bin/sh
if [ -z $1 ]; then echo "\nEx.\n\t./sms_send.sh 'SMS_GATEWAY_USER' 'SMS_GATEWAY_PASSWORD' 'SMS_GATEWAY_URL' 'SMS_GATEWAY_POST' 'INTRUDE_SMS_MSG' 'URL_IMAGE' 'INTRUDE_SMS_PHONE'\n"; return 0; fi
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
  USERNAME=$1; PASSWORD=$2; URL_POST=$3; POST=$4; MESSAGE=$5; URL_IMAGE=$6; PHONES=$7
  MESSAGE="$MESSAGE $URL_IMAGE"
  write_log "SMS Send..."
  write_log "Massage : $MESSAGE"
  MESSAGE=`echo $MESSAGE | tr " " "+"`
  POST=`echo "$POST" | sed -e 's/$USERNAME/'$USERNAME/g|sed -e 's/$PASSWORD/'$PASSWORD/g|sed -e 's/$MESSAGE/'$MESSAGE/g`
  COUNT_FIELD=`echo $PHONES |awk -F"," '{print NF}'`
  i=1
  write_log "Phone : $COUNT_FIELD Number"
  echo $PHONES | tr ',' "\n" | while read PhoneNO
  do
    write_log "  $i.Sending sms to $PhoneNO"
    NEW_POST=`echo "$POST" | sed -e 's/$PhoneNO/'$PhoneNO/g`
    result=`curl -s -d "$NEW_POST" $URL_POST`
    if [ -z $result  ]
    then 
      write_log "  Send Failed!"
    else
      if [ $result -gt 0 ]
      then
        write_log "  Send : Ok"
      else
        write_log "  Send : Failed!"
      fi
    fi
    i=$(($i+1)) 
  done
