class MySqlChangeCharset < ActiveRecord::Migration
  def change
    if /^mysql2?$/i =~ ActiveRecord::Base.connection.adapter_name
      charset = "utf8mb4"
      collation = "utf8mb4_general_ci"

      # database
      execute "ALTER DATABASE #{connection.current_database} DEFAULT CHARACTER SET #{charset} COLLATE #{collation}"

      # schema_migrations
      execute "ALTER TABLE schema_migrations CHANGE version version VARCHAR(191) CHARACTER SET #{charset} COLLATE #{collation}"

      # table
      connection.tables.each do |table|
        execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET #{charset} COLLATE #{collation}"
      end
    else
      raise ActiveRecord::IrreversibleMigration.new("Migration error: Unsupported database for migration to utf8mb4 support.")
    end
  end
end
