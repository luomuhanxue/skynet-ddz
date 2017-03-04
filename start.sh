#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)
export TEMP_DIR=$(cd `dirname $ROOT`; pwd)
export SKYNET_ROOT=$(cd `dirname $TEMP_DIR`; pwd)
export DAEMON=false

echo $ROOT
echo $SKYNET_ROOT
while getopts "Dk" arg
do
	case $arg in
		D)
			export DEAMON=true
			;;
		k)
			kill `cat $ROOT/run/skynet.pid`
			exit 0;
			;;
	esac
done

$SKYNET_ROOT/skynet/skynet $ROOT/config
