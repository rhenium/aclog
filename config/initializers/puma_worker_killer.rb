PumaWorkerKiller.config do |config|
  config.ram = 1024
  config.frequency = 5 # sec
  config.percent_usage = 0.98
end

PumaWorkerKiller.start
