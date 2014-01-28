# Rails 4.0.2, activerecord/lib/active_record/connection_adapters/abstract_adapter.rb
module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      protected
      def log(sql, name = "SQL", binds = [])
        @instrumenter.instrument(
          "sql.active_record",
          :sql           => sql,
          :name          => name,
          :connection_id => object_id,
          :binds         => binds) { yield }
      rescue => e
        message = "#{e.class.name}: #{e.message}: #{sql}"
        # @logger.error message if @logger
        exception = translate_exception(e, message)
        exception.set_backtrace e.backtrace
        raise exception
      end
    end
  end
end
