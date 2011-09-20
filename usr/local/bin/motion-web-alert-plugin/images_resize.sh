#!/bin/sh
if [ -z $1 ]
  then
    echo "\nEx.\n    ./images_resize.sh /home/user/Desktop/picture.jpg\n"
    return 0
fi
. ./write_log.sh
  write_log "Resize images..."
  convert -resize 320x240 -quality 80 $1 /tmp/temp_pic_$$.jpg 2>/dev/null \
 && ( write_log "  Resize : Ok"; echo "/tmp/temp_pic_$$.jpg" ) || ( write_log "  Resize : Failed!"; echo "-" )  
write_line
