# Aclog [![Build Status](https://travis-ci.org/rhenium/aclog.png?branch=master)](https://travis-ci.org/rhenium/aclog) [![Coverage Status](https://coveralls.io/repos/rhenium/aclog/badge.png)](https://coveralls.io/r/rhenium/aclog)
is a web application that tracks users' retweeting and favoriting on Twitter in real-time.

* is powered by Ruby, EventMachine, Ruby on Rails and Vue.js
* is completely free and open source ([The MIT License](https://github.com/rhenium/aclog/blob/master/LICENSE.txt))
* has scalable structure: capable of handling over 6k users = 6k simultaneous UserStream connections.

## Status
* Working on [aclog.koba789.com](http://aclog.koba789.com)

## Features
* Collecting likes and retweets via Twitter Streaming API
* Protected accounts support
* JSON API (with OAuth Echo)
* Atom feed

## Requirements
* Linux (WorkerNode optionally needs epoll)
* Ruby 2.3.0
* MySQL/MariaDB >= 5.5.14 (utf8mb4 support is required)
* memcached
* Node.js >= 4.0

## Installation
Aclog has 3 components:

* `/` - application backend (Rails, requires MySQL and memcached)
* `/frontend` - client side code (Node.js)
* `/worker_node` - event collecter node (plain Ruby, requires memcached)

So, there are some files you have to configure:

* `/config/settings.yml`      - Main configuration
* `/config/database.yml`      - Database user / password
* `/config/secrets.yml`       - Rails's `secret_key_base`
* `/frontend/settings.js`     - Frontend configuration
* `/worker_node/settings.yml` - WorkerNode configuration

For production, read `INSTALL.md` for details.  
For development, you can run aclog on your machine with foreman, after configuration.

```sh
cd /path/to/aclog
bundle install
bundle exec rake db:setup

cd worker_node && bundle install && cd ..
cd frontend && npm install && cd ..

foreman run
# will run all components in foreground (this currently listens tcp/3000 (backend), tcp/3001 (frontend), tcp/3002 (reverse proxy)
# you will be able to access your aclog at http://localhost:8001/
```

## Special Thanks
* KOBA789 ([@KOBA789](https://twitter.com/KOBA789) / [koba789.com](http://koba789.com)) - Hosting aclog.koba789.com
* rot ([@aayh](https://twitter.com/aayh)) - UI design

## License
MIT License. See the `LICENSE` file for details.
