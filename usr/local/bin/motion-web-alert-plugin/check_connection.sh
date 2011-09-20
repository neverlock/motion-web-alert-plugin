#!/bin/sh
. ./write_log.sh  
  write_log "Check Internet Connection..."
  wget --spider http://google.com 2>/dev/null
  result=$?
  if [ $result -eq 0 ]
  then
    write_log "Connection : Ok"
  else
    write_log "Connection : Failed!"
  fi
write_line
echo $result
