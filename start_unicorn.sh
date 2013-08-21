#!/bin/sh

export RAILS_ENV=production
export RAILS_ROOT=$(readlink -f `dirname $0`)

PID="$RAILS_ROOT/tmp/pids/unicorn.pid"
PID_OLD="$PID.oldbin"

sig () {
    test -s $PID && kill -$1 `cat $PID`
}

sig_old () {
    test -s $PID_OLD && kill -$1 `cat $PID_OLD`
}

error () {
    echo $1
    exit 1
}

unicorn_start="bundle exec unicorn_rails -D -E $RAILS_ENV -c $RAILS_ROOT/config/unicorn.rb -l 4000"

case "$1" in
    start)
        sig 0 && error "Unicorn already started!"
        $unicorn_start && echo "Unicorn started!" || error "Unicorn failed to start!"
        ;;
    stop)
        sig QUIT && echo "Unicorn stopped" || error "Unicorn not started!"
        ;;
    restart)
        sig 0 || error "Unicorn not started!"
        sig USR2 && sleep 5
        sig_old QUIT && echo "Quit old unicorn" `cat $PID_OLD` || echo "Couldn't quit old unicorn"
        ;;
    status)
        sig 0 && echo "Unicorn started" || echo "Unicorn stopped"
        ;;
    *)
        error "usage: $0 {start|stop|restart|status}"
esac

