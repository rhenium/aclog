#!/usr/bin/env ruby
require "./worker"
require "./settings"

$stdout.sync = true
$stderr.sync = true

logger = Logger.new(STDOUT)
logger.level = Aclog::Collector::Settings.env == "development" ? Logger::DEBUG : Logger::INFO

worker = Aclog::Collector::Worker.new(logger)
worker.start

