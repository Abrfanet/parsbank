# frozen_string_literal: true

module Parsbank
  class DBSetup
    def self.establish_connection
      if Parsbank.configuration.database_url.present?
        setup_db
      else
        simulate_db
        puts("\033[31mParsBank ERROR: database_url not set, Transaction history not stored on database\033[0m")
      end
    end

    def self.simulate_db
      model_name = Parsbank.configuration.model || 'Transaction'
      simulated_model = Class.new do
        attr_accessor :description, :amount, :gateway, :callback_url, :status,
                      :user_id, :cart_id, :local_id, :ip, :gateway_verify_response, :gateway_response, :track_id, :unit, :created_at, :updated_at

        def initialize(attributes = {})
          build_attrs attributes.merge({created_at: Time.now})
        end

        def update!(attributes = {})
          build_attrs attributes.merge({updated_at: Time.now})
        end

        def build_attrs attributes = {}
          attributes.each do |key, value|
            send("#{key}=", value)
          end
        end
        def save
          # Simulate saving (e.g., print or log the data)
          @id = Time.now.to_i # Simulate an ID assignment
          true
        end

        attr_reader :id
      end

      # Set the simulated class as a constant
      Object.const_set(model_name.camelcase, simulated_model)
    end

    def self.setup_db
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
