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
* Ruby >= 2.2.3
* MySQL/MariaDB >= 5.5.14 (utf8mb4 support is required)
* memcached
* Node.js >= 4.0

## Installation
Aclog has 3 components:

* / : application backend (Rails, requires MySQL and memcached)
* /frontend : client side code (Node.js)
* /worker_node: event collecter node (plain Ruby, requires memcached)

### Application (backend)

```sh
# installing aclog at /var/webapps/aclog
git clone https://github.com/rhenium/aclog.git /var/webapps/aclog
cd /var/webapps/aclog

bundle install

# Copy the example aclog config
cp config/settings.yml.example config/settings.yml
vi config/settings.yml

# Copy the example aclog database config
cp config/database.yml.example config/database.yml
vi config/database.yml

# Set random secret_token
cp config/secrets.yml.example config/secrets.yml
sed -i s/replace_here/$(rake secret)/g config/secrets.yml

# Setup database. This will create database and tables on MySQL server.
RAILS_ENV=production bundle exec rake db:setup

# start your aclog:
# with Rake
RAILS_ENV=production bundle exec rake web:start
RAILS_ENV=production bundle exec rake collector:start
RAILS_ENV=production bundle exec bin/delayed_job start

# or, with systemd
cp example/systemd/aclog-{webserver,collector,delayed_job}.service /usr/lib/systemd/system/
systemctl start aclog-webserver.service
systemctl start aclog-collector.service
systemctl start aclog-delayed_job.service
```

### Application (frontend)

```sh
cd /var/webapps/aclog/frontend
npm install
node_modules/gulp/bin/gulp.js build

# and edit your nginx configuration like example/nginx.conf
```

### Collector worker node(s)

```sh
git clone https://github.com/rhenium/aclog.git /var/webapps/aclog
cd /var/webapps/aclog/worker_node

bundle install

# Copy the example collector config
cp settings.yml.example settings.yml
vi settings.yml

# start a node:
# with Rake
bundle exec rake worker_node:run

# or, with systemd
cp example/systemd/aclog-worker-node.service /usr/lib/systemd/system/
systemctl start aclog-worker-node.service
```

## Special Thanks
* KOBA789 ([@KOBA789](https://twitter.com/KOBA789) / [koba789.com](http://koba789.com)) - Hosting aclog.koba789.com
* rot ([@aayh](https://twitter.com/aayh)) - UI design

## License
MIT License. See the LICENSE file for details.
