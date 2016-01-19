require "rack/reverse_proxy"

UPSTREAM_RACK = 'http://localhost:3000$1'
UPSTREAM_WEBPACK = 'http://localhost:3001$1'

use Rack::ReverseProxy do
  reverse_proxy_options matching: :first

  reverse_proxy %r{^(/(?:i/)?api.*)$}, UPSTREAM_RACK
  reverse_proxy %r{^(/.*\.atom)$}, UPSTREAM_RACK
  reverse_proxy %r{^(/.*)$}, UPSTREAM_WEBPACK
end

run proc { [500, {}, "No matching? Bug in devtools/devproxy.ru"] }
