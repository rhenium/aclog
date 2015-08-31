begin
  require "active_record/connection_adapters/mysql2_adapter"

  # MySQL / change primary_key from INT to BIGINT
  ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT UNSIGNED DEFAULT NULL AUTO_INCREMENT PRIMARY KEY"
rescue LoadError
end

begin
  require "active_record/connection_adapters/postgresql_adapter"

  # PostgreSQL / change primary_key from INT to BIGINT
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "bigserial primary key"
rescue LoadError
end

# MySQL / utf8mb4
ActiveRecord::Base.connection.initialize_schema_migrations_table
