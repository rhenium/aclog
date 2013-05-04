# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require "unicorn_killer"
use UnicornKiller::Oom, 144 * 1024
use UnicornKiller::MaxRequests, 1000
run Aclog::Application

