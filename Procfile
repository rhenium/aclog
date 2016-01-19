web: bundle exec rails server
collector: bundle exec rake collector:run
delayed_job: bundle exec bin/delayed_job run
frontend: cd frontend && node_modules/.bin/gulp watch
worker_node: cd worker_node && bundle exec rake worker_node:run
devproxy: bundle exec puma -w 0 -b tcp://localhost:3002 devtools/devproxy.ru
