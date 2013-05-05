#!/usr/bin/env ruby
require "./worker"

$stdout.sync = true
$stderr.sync = true

worker = Worker.new
worker.start

