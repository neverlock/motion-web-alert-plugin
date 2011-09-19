#!/bin/sh
PATH_LOG='/var/log/motion/motion-web-alert-plugin.log'
write_log(){
  NOW=`date '+[%d/%m/%Y-%H:%M:%S] : '` 
  echo "$NOW$*" | tee -a $PATH_LOG  >&2
}

write_line(){
  echo "" | tee -a $PATH_LOG  >&2
}
