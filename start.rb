#!/usr/bin/env ruby

require ::File.expand_path('../web/config/application',  __FILE__)
Rails.application.require_environment!

require ::File.expand_path('../worker/receiver',  __FILE__)
Receiver::Worker.new.start

