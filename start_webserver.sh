#!/bin/sh

export RAILS_ENV=production
export RAILS_ROOT=$(readlink -f `dirname $0`)

PID="$RAILS_ROOT/tmp/pids/puma.pid"

sig () {
    test -s $PID && kill -$1 `cat $PID`
}

error () {
    echo $1
    exit 1
}

puma_start="bundle exec -d -e $RAILS_ENV -C $RAILS_ROOT/config/puma.rb --pidfile $PID"

case "$1" in
    start)
        sig 0 && error "Puma already started!"
        $puma_start && echo "Puma started!" || error "Puma failed to start!"
        ;;
    stop)
        sig TERM && echo "Puma stopped!" || error "Puma not started!"
        ;;
    restart)
        sig 0 || error "Puma not started!"
        sig USR2 && echo "Puma restarted!" `cat $PID` || echo "Puma failed to restart!"
        ;;
    status)
        sig 0 && echo "Puma is started!" || echo "Puma is stopped!"
        ;;
    *)
        error "usage: $0 {start|stop|restart|status}"
esac
