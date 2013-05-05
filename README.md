# Aclog
Collects favs and retweets in real time by UserStreams.
A web service like Favstar.

## Aclog is
* Powered by Ruby on Rails
* Free and open source (MIT License)

## Status
* *unstable*
* Working on [aclog.koba789.com](http://aclog.koba789.com)

## Features
* Register with a Twitter account
* Collect favorites and retweets by UserStreams
* List user's best/newest favorited or retweeted tweets
* Show how many favorited/retweeted by specified user
* JSON API

### Not yet / will be implemented
* New UI
* Protected users support
* User settings (favorites notification)

## Requirements
* Ruby 1.9.3
* MySQL/MariaDB 5.5.14+

## Setup
### MySQL
Add to `my.cnf`

    [mysqld]
    innodb_file_format = Barracuda
    innodb_file_per_table = 1
    innodb_large_prefix

Create MySQL user
### aclog configuration
* Rename `config/settings.yml.example` to `config/settings.yml` and set consumer key, ...
* Rename `env.sh.example` to `env.sh` and set `DATABASE_URL`.
* Setup database

        source env.sh
        rake db:setup

* Set secret token. Rename `config/initializers/secret_token.rb.example` to `config/initializers/secret_token.rb`. Run `rake secret` and set the result to `config/initializers/secret_token.rb`.

