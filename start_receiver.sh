#!/bin/sh

export RAILS_ENV=production
receiver="bundle exec rails runner bin/start.rb"

case "$1" in
    start)
        $receiver start
        ;;
    stop)
        $receiver stop
        ;;
    restart)
        $receiver restart
        ;;
    status)
        $receiver status
        ;;
    *)
        echo "usage: $0 {start|stop|restart|status}"
        exit 1
esac
