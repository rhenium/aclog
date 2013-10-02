require 'active_record/connection_adapters/mysql2_adapter'

# MySQL / change primary_key from INT to BIGINT
ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT UNSIGNED DEFAULT NULL AUTO_INCREMENT PRIMARY KEY"

# MySQL / utf8mb4
ActiveRecord::Base.connection.initialize_schema_migrations_table


