#!/bin/bash
#
# kaiser This starts and stops kaiser
#
# chkconfig: 2345 12 88
# description: Kaiser is a simple command-line Gmail client, integrated into your favorite text editor.
# processname: kaiser
# pidfile: /var/run/kaiser.pid
### BEGIN INIT INFO
# Provides: $kaiser
### END INIT INFO

# Source function library.
. /etc/init.d/functions

binary="/usr/local/etc/kaiser-gmail/kaiser.perl"

[ -x $binary ] || exit 0

RETVAL=0

start() {
    echo -n "Starting kaiser: "
    daemon $binary
    RETVAL=$?
    PID=$!
    echo
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/kaiser

    echo $PID > /var/run/kaiser.pid
}

stop() {
    echo -n "Shutting down kaiser: "
    killproc kaiser
    RETVAL=$?
    echo
    if [ $RETVAL -eq 0 ]; then
        rm -f /var/lock/subsys/kaiser
        rm -f /var/run/kaiser.pid
    fi
}

restart() {
    echo -n "Restarting kaiser: "
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    status)
        status kaiser
    ;;
    restart)
        restart
    ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
    ;;
esac

exit 0
