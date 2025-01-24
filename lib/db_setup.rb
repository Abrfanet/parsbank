# frozen_string_literal: true

module ParsBank
  class DBSetup
    def self.establish_connection

      unless Parsbank.configuration.database_url.present?
        return puts("\033[31mParsBank ERROR: database_url not set, Transaction history not stored on database\033[0m")
      end
      
      database_url = Parsbank.configuration.database_url
      model = Parsbank.configuration.model
      raise 'DATABASE_URL environment variable is not set' if database_url.nil?

      supported_databases = {
        'postgresql' => 'pg',
        'mysql2' => 'mysql2',
        'sqlite3' => 'sqlite3',
        'nulldb' => 'nulldb'
      }.freeze

      uri = URI.parse(database_url)

      gem_name = supported_databases[uri.scheme]
      unless gem_name
        raise "Unsupported database adapter: #{uri.scheme}. Supported adapters: #{supported_databases.keys.join(', ')}"
      end

      begin
        require gem_name
      rescue LoadError
        raise "Missing required gem for #{uri.scheme}. Please add `gem '#{gem_name}'` to your Gemfile."
      end

      begin
        ActiveRecord::Base.establish_connection(database_url)
        unless ActiveRecord::Base.connection.table_exists?(model.tableize)
          puts 'Create Transaction Table'
          ActiveRecord::Base.connection.create_table model.tableize do |t|
            t.string :gateway
            t.string :amount
            t.string :unit
            t.string :track_id
            t.string :local_id
            t.string :ip
            t.integer :user_id
            t.integer :cart_id
            t.text :description
            t.string :callback_url
            t.text :gateway_verify_response
            t.text :gateway_response
            t.string :status
            t.timestamps
          end
        end

        unless Object.const_defined?(model)
          Object.const_set(model, Class.new(ActiveRecord::Base) do
            self.table_name = model.tableize
          end)
        end
      rescue StandardError => e
        raise "Failed to connect to the database: #{e.message}"
      end
    end
  end
end
