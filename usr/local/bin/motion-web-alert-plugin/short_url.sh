#!/bin/sh
if [ -z $1 ]; then echo "\nEx.\n    ./short_url.sh user apikey http://www.your-url.com\n"; return 0; fi

. /usr/local/bin/motion-web-alert-plugin/write_log.sh
  write_log "Short URL..."
  wget -O /tmp/short_url_$$.txt "http://api.bit.ly/v3/shorten?login=$1&apiKey=$2&longUrl=$3&format=txt" 2>/dev/null
  if [ $? -eq 0 ]
  then
    URL=`cat /tmp/short_url_$$.txt`
    write_log "Short URL : $URL"
    echo $URL
  else
    write_log "Short URL : Error!"
    echo "-"
  fi
  write_line
rm /tmp/short_url_$$.txt
