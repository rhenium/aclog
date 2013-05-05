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
* Set consumer keys, base URL, ..

        cp config/settings.yml.example config/settings.yml
        vi config/settings.yml

* Setup database

        cp config/database.yml.example config/database.yml
        vi config/database.yml
        rake db:setup

* Set secret token

        cp config/initializers/secret_token.rb.example config/initializers/secret_token.rb
        sed -i s/replace_here/$(rake secret)/g config/initializers/secret_token.rb


