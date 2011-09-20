#!/bin/sh
if [ -z $1 ]; then echo "\nEx.\n    ./tweet.sh twitter_user twitter_pass @photo type_alert 'your message'\n";  return 0; fi

. /usr/local/bin/motion-web-alert-plugin/write_log.sh
  write_log "Tweet..."
  NOW=`date '+[%d/%m/%Y-%H:%M:%S]'`
  UPLOAD_URL="http://twitpic.com/api/uploadAndPost"
  TWITTER_USER=$1
  TWITTER_PW=$2
  PHOTO=$3
  STATUS=$4
  TWEET_MSG="$NOW[$STATUS] $5"
  write_log "Massage : $TWEET_MSG @URL"
  
  run=`curl \
  --form username=$TWITTER_USER \
  --form password=$TWITTER_PW \
  --form media=@"$PHOTO" \
  --form message="$TWEET_MSG" $UPLOAD_URL 2>/dev/null`
 
  result=`echo $run | awk -F'status="' '{print $2}' | awk -F'"' '{print $1}'`
  url=`echo $run | awk -F'<mediaurl>' '{print $2}' | awk -F'</mediaurl>' '{print $1}'`
  if [ ! -z $url ]; then write_log "@URL = $url"; fi
  [ ! -z $result ] && [ $result = "ok" ] && ( write_log "Tweet : Ok" ; echo $url) || ( write_log "Tweet : Error!"; echo '')
write_line
