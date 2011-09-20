#!/bin/sh
if [ -z $1 ]
  then
    echo "\nEx.\n    ./sms_send.sh username password 'your message' 0812345678,0987654321\n"
    return 0
fi
. ./write_log.sh
  USERNAME=$1
  PASSWORD=$2
  MESSAGE=$3
  PHONES=$4
  write_log "SMS Send..."
  write_log "Massage : $MESSAGE"
  MESSAGE=`echo $MESSAGE | tr " " "+"`
  COUNT_FIELD=`echo $PHONES |awk -F"," '{print NF}'`
  i=1
  write_log "Phone : $COUNT_FIELD Number"
  echo $PHONES | tr ',' "\n" | while read PhoneNO
  do
    write_log "  $i.Sending sms to $PhoneNO"
    result=`curl -s -d "Username=$USERNAME&Password=$PASSWORD&Text=$MESSAGE&PhoneNumber=$PhoneNO&SMSMode=E&SName=CCTV" http://www.inanosms.com/API_NANO_NAME_V2.asp`
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
write_line
