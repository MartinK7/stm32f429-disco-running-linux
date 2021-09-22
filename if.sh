#!/bin/bash
if test $(wc -c < $1) -ge $(printf "%d\n" $2)
	then
	echo $3
	exit -1
fi
exit 0
