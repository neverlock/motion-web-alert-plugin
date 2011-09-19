#!/bin/sh
if [ -z $1 ]
  then
    echo "\nEx.\n    ./tweet.sh twitter_user twitter_pass photo_file type_alert 'your message tweet'\n"
    return 0
fi
. ./write_log.sh
  write_log "Tweet..."
  NOW=`date '+[%d/%m/%Y-%H:%M:%S]'`

  UPLOAD_URL="http://twitpic.com/api/uploadAndPost"
  TWITTER_USER=$1
  shift
  TWITTER_PW=$1
  shift
  PHOTO=$1
  shift
  STATUS=$1
  shift
  TWEET_MSG="$NOW[$STATUS] $*"
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
