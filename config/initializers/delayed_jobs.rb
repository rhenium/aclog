Delayed::Worker.logger = Logger.new(STDOUT)
Delayed::Worker.logger.level =
  Rails.env.production? ? Logger::INFO : Logger::DEBUG
ActiveRecord::Base.logger = Delayed::Worker.logger
