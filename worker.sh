#!/bin/sh

bundle exec rails runner Receiver::Worker.new.start


