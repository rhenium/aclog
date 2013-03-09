# Load the rails application.
require File.expand_path('../application', __FILE__)

require 'active_record/connection_adapters/mysql2_adapter'
ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT UNSIGNED DEFAULT NULL auto_increment PRIMARY KEY"

# Initialize the rails application.
Aclog::Application.initialize!


