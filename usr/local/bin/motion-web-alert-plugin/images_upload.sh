#!/bin/sh
#upload image from image path 
#return image URL(not shot URL)
if [ -z "$1" ]; then echo "\nEx.\n\t./images_upload.sh 'api kay' 'images path'\n"; return 0; fi
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
  img_path=$2
  api_key=$1
  url='http://api.imgur.com/2/upload.xml'
  write_log "Uploading Images..."
  result=`curl -F "image=@$img_path" -F "key=$api_key" $url 2>/dev/null`
  result=`echo $result | awk -F '<original>' '{print $2}' | awk -F '</original>' '{print $1}'`
  [ -z $result ] && ( write_log "Upload : Failed!"; echo "-" ) ||\
 ( write_log "Upload : Ok"; write_log "Images URL : $result"; echo $result; )
