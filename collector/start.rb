#!/usr/bin/env ruby
require "./worker"

$stdout.sync = true
$stderr.sync = true

worker = Aclog::Collector::Worker.new
worker.start

