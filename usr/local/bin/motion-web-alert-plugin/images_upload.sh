#!/bin/sh
if [ -z $1 ]
  then
    echo "\nEx.\n    ./images_upload.sh /home/user/Desktop/picture.jpg\n"
    return 0
fi
. ./write_log.sh
  write_log "Uploading Images..."
  write_log "  Resize images"
  convert -resize 320x240 -quality 80 $1 /tmp/temp_pic_$$.jpg 2>/dev/null \
 && write_log "  Resize : Ok" || write_log "  Resize : Failed!"  
  IMAGESHACK_URL=`./shag.py /tmp/temp_pic_$$.jpg` 2>/dev/null
  STATUS=`echo $IMAGESHACK_URL |awk -F"://" '{print NF}'`
  if [ $STATUS != 2 ]
  then 
    write_log "Upload : Failed!"
    echo "-"
  else
    write_log "Upload : Ok"
    write_log "Images URL : $IMAGESHACK_URL"
    echo "$IMAGESHACK_URL"
  fi
 rm /tmp/temp_pic_$$.jpg 2>/dev/null
write_line
