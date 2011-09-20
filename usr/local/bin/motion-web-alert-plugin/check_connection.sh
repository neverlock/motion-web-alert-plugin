#!/bin/sh
. /usr/local/bin/motion-web-alert-plugin/write_log.sh  
  write_log "Check Internet Connection..."
  wget --spider http://google.com 2>/dev/null
  result=$?
  [ $result -eq 0 ] && write_log "Connection : Ok" || write_log "Connection : Failed!"
echo $result
write_line
