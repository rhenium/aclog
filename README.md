# Aclog [![Build Status](https://travis-ci.org/rhenium/aclog.png?branch=master)](https://travis-ci.org/rhenium/aclog) [![Coverage Status](https://coveralls.io/repos/rhenium/aclog/badge.png)](https://coveralls.io/r/rhenium/aclog)
Collects favs and retweets in real time by UserStreams.

## Aclog is
* powered by Ruby on Rails and EventMachine
* completely free and open source ([The MIT License](https://github.com/rhenium/aclog/blob/master/LICENSE.txt))
* Scalable structure

        |------------|           |-----------| (MsgPack) |---------|   |---|
        |            -------------           ------------- Worker  =====   |
        | Web Server (MsgPack-RPC)           -------------    Node ===== T |
        |            -------------           |           |---------|   | w |
        |-----| |----|           |           ------------- Worker  ===== i |
              | |                | Collector -------------    Node ===== t |
        |-----| |----|           |           |           |---------|   | t |
        |            -------------           ------------- Worker  ===== e |
        | DB (MySQL)                         -------------    Node ===== r |
        |            -------------           |    :      |---------|   |   |
        |------------|           |-----------|    :           :        |---|

## Status
* Working on [aclog.koba789.com](http://aclog.koba789.com)

## Features
* Collecting favorites and retweets from Twitter Streaming API
* Protected account support
* JSON API (with OAuth Echo)
* Atom feed

## Requirements
* Linux (WorkerNode optionally needs epoll)
* Ruby 2.2+
* MySQL/MariaDB 5.5.14+ (needs utf8mb4 support)
* memcached
* JavaScript runtime (see https://github.com/rails/execjs)

## Installation
### Database
* Create MySQL user

### Application Server
* Clone the source

        $ # We'll install aclog into /var/webapps/aclog
        $ cd /var/webapps
        $ git clone https://github.com/rhenium/aclog.git
        $ cd /var/webapps/aclog

* Install Gems

        $ bundle install

* Configure

        $ # Copy the example aclog config
        $ cp config/settings.yml.example config/settings.yml
        $ # Edit it
        $ vi config/settings.yml

        $ # Copy the example aclog database config
        $ cp config/database.yml.example config/database.yml
        $ vi config/database.yml

        $ # Set random secret_token
        $ cp config/secrets.yml.example config/secrets.yml
        $ sed -i s/replace_here/$(rake secret)/g config/secrets.yml

        $ # Setup database. This will create database and tables on MySQL server.
        $ RAILS_ENV=production bundle exec rake db:setup

* Start your aclog

    * Rake

            $ RAILS_ENV=production bundle exec rake web:start
            $ RAILS_ENV=production bundle exec rake collector:start
            $ RAILS_ENV=production bundle exec bin/delayed_job start

    * systemd

            $ cp example/systemd/aclog-{webserver,collector,delayed_job}.service /usr/lib/systemd/system/
            $ systemctl start aclog-webserver.service
            $ systemctl start aclog-collector.service
            $ systemctl start aclog-delayed_job.service

### Collector worker nodes
* Copy the source

        $ cd /var/webapps
        $ git clone https://github.com/rhenium/aclog.git
        $ cd /var/webapps/aclog/worker_node

* Install Gems

        $ bundle install

* Configure it

        $ # Copy the example collector config
        $ cp settings.yml.example settings.yml
        $ # Edit it
        $ vi settings.yml

* Start worker

    * Rake

            $ bundle exec rake worker_node:run

    * systemd

            $ cp example/systemd/aclog-worker-node.service /usr/lib/systemd/system/
            $ systemctl start aclog-worker-node.service

## Special Thanks
* KOBA789 ([@KOBA789](https://twitter.com/KOBA789) / [koba789.com](http://koba789.com)) - Hosting aclog.koba789.com
* rot ([@aayh](https://twitter.com/aayh)) - Web UI design

## Contributing
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
