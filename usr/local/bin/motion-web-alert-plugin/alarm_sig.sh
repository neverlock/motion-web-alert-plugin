#!/bin/sh
alarm_sig (){
if [ -z $2 ]
then
	echo "Plese use: $0 [start/stop] 1"
	exit
fi
stty -F /dev/ttyS0 ospeed 9600
stty -F /dev/ttyS0 ispeed 9600
if [ "$1" = "stop" ]
then
" > /dev/ttyS0\$\$O*$2
fi
if [ "$1" = "start" ]
then
" > /dev/ttyS0\$\$I*$2
fi
}

as () {
if [ -z $2 ]
then
	echo "Plese use: $0 [start/stop] 1"
	exit
fi
stty -F /dev/ttyS0 ospeed 9600
stty -F /dev/ttyS0 ispeed 9600
if [ "$1" = "stop" ]
then
echo '$$O*'$2 > /dev/ttyS0
fi
if [ "$1" = "start" ]
then
echo '$$I*'$2 > /dev/ttyS0
fi

}

#alarm_sig $1 $2
as $1 $2
