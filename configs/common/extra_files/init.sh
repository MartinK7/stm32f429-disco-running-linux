#!/bin/sh
banner
mount -t proc none /proc
cd /root
exec /bin/sh
