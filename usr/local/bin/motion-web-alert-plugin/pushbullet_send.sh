#!/bin/sh
if [ -z $1 ]; then echo "\nEx.\n\t./pushbullet_send.sh 'INTRUDE_PUSHBULLET_MSG' 'INTRUDE_PUSHBULLET_TOKEN' 'INTRUDE_PUSHBULLET_CHANNEL' 'URL_IMAGE'\n"; return 0; fi
. /usr/local/bin/motion-web-alert-plugin/write_log.sh
  MESSAGE=$1; TOKEN=$2; CHANNEL=$3; URL_IMAGE=$4
  MESSAGE="$MESSAGE $URL_IMAGE"
  write_log "PUSHBULLET Send..."
  write_log "Massage : $MESSAGE"
#  MESSAGE=`echo $MESSAGE | tr " " "+"`
curl --header "Access-Token: $TOKEN" \
     --header 'Content-Type: application/json' \
     --data-binary "{\"body\":\"$MESSAGE\",\"title\":\"Alert\",\"type\":\"note\",\"channel_tag\":\"c3p\"}" \
    --request POST \
    https://api.pushbullet.com/v2/pushes

    write_log "Post to Pushbullet"
