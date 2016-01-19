# Installing aclog

## Application (backend)

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

## Application (frontend)

```sh
cd /var/webapps/aclog/frontend
npm install
node_modules/gulp/bin/gulp.js build

# and edit your nginx configuration like example/nginx.conf
```

## Collector worker node(s)

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

