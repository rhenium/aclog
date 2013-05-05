require "unicorn_killer"
require ::File.expand_path('../config/environment',  __FILE__)

use UnicornKiller::Oom, 144 * 1024
use UnicornKiller::MaxRequests, 1000

run Aclog::Application

