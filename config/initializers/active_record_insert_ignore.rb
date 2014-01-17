# Adds ActiveRecord::Base#save_ignore!
# This will enable executing such a SQL: "INSERT IGNORE INTO tweets ..."
# See MySQL Manual for INSERT IGNORE: https://dev.mysql.com/doc/refman/5.1/en/insert.html

# ActiveRecord 4.0.2 / Arel 4.0.1

module Arel
  # lib/arel/nodes/insert_statement.rb
  module Nodes
    class InsertStatement
      attr_accessor :ignore

      alias orig_initialize initialize
      def initialize
        orig_initialize
        @ignore = false
      end

      def hash
        [@relation, @columns, @values, @ignore].hash
      end

      alias orig_eql? eql?
      def eql? other
        orig_eql? && self.ignore == other.ignore
      end
      alias :== :eql?
    end
  end

  # lib/arel/visitors/to_sql.rb
  module Visitors
    class ToSql
      private
      def visit_Arel_Nodes_InsertStatement o, a
        st = o.ignore ? "INSERT IGNORE INTO " :
                         "INSERT INTO "
        [
          "#{st}#{visit o.relation, a}",

          ("(#{o.columns.map { |x|
          quote_column_name x.name
        }.join ', '})" unless o.columns.empty?),

          (visit o.values, a if o.values),
        ].compact.join ' '
      end
    end
  end

  # lib/arel/insert_manager.rb
  class InsertManager
    def ignore; @ast.ignore end
    def ignore= val; @ast.ignore = val end
  end
end

# insert_ignore
module ActiveRecord
  # activerecord/lib/active_record/relation.rb
  class Relation
    def insert_ignore(values)
      primary_key_value = nil

      if primary_key && Hash === values
        primary_key_value = values[values.keys.find { |k|
          k.name == primary_key
        }]

        if !primary_key_value && connection.prefetch_primary_key?(klass.table_name)
          primary_key_value = connection.next_sequence_value(klass.sequence_name)
          values[klass.arel_table[klass.primary_key]] = primary_key_value
        end
      end

      im = arel.create_insert
      im.ignore = true # added
      im.into @table

      conn = @klass.connection

      substitutes = values.sort_by { |arel_attr,_| arel_attr.name }
      binds       = substitutes.map do |arel_attr, value|
        [@klass.columns_hash[arel_attr.name], value]
      end

      substitutes.each_with_index do |tuple, i|
        tuple[1] = conn.substitute_at(binds[i][0], i)
      end

      if values.empty? # empty insert
        im.values = Arel.sql(connection.empty_insert_statement_value)
      else
        im.insert substitutes
      end

      conn.insert(
        im,
        'SQL',
        primary_key,
        primary_key_value,
        nil,
        binds)
    end
  end
end

# save!
module ActiveRecord
  # activerecord/lib/active_record/transactions.rb
  module Transactions
    def save_ignore!(*)
      with_transaction_returning_status { super }
    end
  end

  # activerecord/lib/active_record/attribute_methods/dirty.rb
  module AttributeMethods
    module Dirty
      def save_ignore!(*)
        super.tap do
          @previously_changed = changes
          @changed_attributes.clear
        end
      end
    end
  end

  # activerecord/lib/active_record/validations.rb
  module Validations
    def save_ignore!(options={})
      perform_validations(options) ? super : raise(RecordInvalid.new(self))
    end
  end

  # activerecord/lib/active_record/persistence.rb
  module Persistence
    def save_ignore!(*)
      create_ignore_or_update || raise(RecordNotSaved)
    end
  end
end

# create_ignore_or_update / create_record_ignore
module ActiveRecord
  # activerecord/lib/active_record/callbacks.rb
  module Callbacks
    private
    def create_ignore_or_update
      run_callbacks(:save) { super }
    end

    def create_record_ignore
      run_callbacks(:create) { super }
    end
  end

  # activerecord/lib/active_record/timestamp.rb
  module Timestamps
    private
    def create_record_ignore
      if self.record_timestamps
        current_time = current_time_from_proper_timezone

        all_timestamp_attributes.each do |column|
          if respond_to?(column) && respond_to?("#{column}=") && self.send(column).nil?
            write_attribute(column.to_s, current_time)
          end
        end
      end

      super
    end
  end

  # activerecord/lib/active_record/persistence.rb
  module Persistence
    private
    def create_ignore_or_update
      raise ReadOnlyRecord if readonly?
      result = new_record? ? create_record_ignore : update_record
      result != false
    end

    def create_record_ignore(attribute_names = @attributes.keys)
      attributes_values = arel_attributes_with_values_for_create(attribute_names)

      new_id = self.class.unscoped.insert_ignore attributes_values
      self.id ||= new_id if self.class.primary_key

      @new_record = false
      id
    end
  end
end
