# Aclog [![Build Status](https://travis-ci.org/rhenium/aclog.png?branch=master)](https://travis-ci.org/rhenium/aclog) [![Coverage Status](https://coveralls.io/repos/rhenium/aclog/badge.png)](https://coveralls.io/r/rhenium/aclog)
Collects favs and retweets in real time by UserStreams.

## Aclog is
* powered by Ruby on Rails
* completely free and open source ([The MIT License](https://github.com/rhenium/aclog/blob/master/LICENSE.txt))
* designed by rot([@aayh](https://twitter.com/aayh))

## Status
* *unstable*
* Working on [aclog.koba789.com](http://aclog.koba789.com)

## Features
* Collecting favorites and retweets from Twitter Streaming API
* Protected account support
* JSON API (OAuth Echo)
* Atom feed

### Not yet / will be implemented
* Import tweets from Favstar / Favotter / tweets.zip / ..

## Requirements
* Ruby 2.0.0+
* MySQL/MariaDB 5.5.14+ (needs utf8mb4 support)

## Installation
### Database
* Create MySQL user

### Aclog (Application Server)
* Clone the source

        $ # We'll install aclog into /var/webapps/aclog
        $ cd /var/webapps
        $ git clone https://github.com/rhenium/aclog.git
        $ cd /var/webapps/aclog

* Configure it

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
        $ rake db:setup

* Install Gems

        $ bundle install

* Start your aclog

        $ # Start Puma (Web server)
        $ rake web:start
        $ # Start Background worker
        $ rake collector:start

### Aclog (Collector worker nodes)
* Chdir

        $ cd /var/webapps/worker_nodes

* Configure it

        $ # Copy the example collector config
        $ cp settings.yml.example settings.yml
        $ # Edit it
        $ vi settings.yml

* Install Gems

        $ bundle install

* Start collector

        $ RAILS_ENV=production bundle exec ./start.rb


## Contributing
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

