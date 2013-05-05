#!/bin/sh
set -e

export RAILS_ENV=production

APP_ROOT=$(readlink -f `dirname $0`)
PID="$APP_ROOT/tmp/pids/unicorn.pid"
PID_OLD="$PID.oldbin"
cd $APP_ROOT || exit 1

sig () {
  test -s $1 && kill -$2 `cat $1`
}

unicorn="bundle exec unicorn_rails -D -E $RAILS_ENV -c $APP_ROOT/config/unicorn.rb -l 4000"
receiver="bundle exec rails runner script/start.rb"
 
case $1 in
start)
  case $2 in
  unicorn)
    sig $PID 0 && echo >&2 "Already running unicorn" || $unicorn
    ;;
  receiver)
    $receiver start
    ;;
  *)
    sig $PID 0 && echo >&2 "Already running unicorn" || $unicorn
    $receiver start
    ;;
  esac
  ;;
stop)
  case $2 in
  unicorn)
    sig $PID QUIT || echo >&2 "Not running unicorn"
    ;;
  receiver)
    $receiver stop
    ;;
  *)
    sig $PID QUIT || echo >&2 "Not running unicorn"
    $receiver stop
    ;;
  esac
  ;;
reload)
  case $2 in
  unicorn)
    sig $PID USR2 && sleep 5 && sig $PID_OLD QUIT && echo "Quit old master" `cat $PID_OLD` && return
    echo >&2 "Couldn't quit old master"
    ;;
  receiver)
    $receiver restart
    ;;
  *)
    sig $PID USR2 && sleep 5 && sig $PID_OLD QUIT && echo "Quit old master" `cat $PID_OLD` && return
    echo >&2 "Couldn't quit old master"
    $receiver restart
    ;;
  esac
  ;;
*)
  echo >&2 "Usage $0 <start|stop|reload> <unicorn|receiver>"
  exit 1
  ;;
esac

