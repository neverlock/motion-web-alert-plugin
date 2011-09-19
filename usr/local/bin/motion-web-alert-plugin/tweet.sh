#!/bin/sh
if [ -z $1 ]
  then
    echo "\nEx.\n    ./tweet.sh alert 'your message tweet'\n"
    return 0
fi
. ./write_log.sh
  write_log "Tweet..."
  NOW=`date '+[%d/%m/%Y-%H:%M:%S]'`
  STATUS=$1
  shift
  STR="$NOW[$STATUS] $*" 
  write_log "Massage : $STR"
  ./ttytter.pl -script -keyf=$HOME/.ttytterkey -status="$STR"
  result=$?
   if [ $result -eq 0 ]
    then
      write_log "Tweet : Ok"
    else
      write_log "Tweet : Error!"
  fi
write_line
echo $result
