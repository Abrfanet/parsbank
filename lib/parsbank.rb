# frozen_string_literal: true

require 'yaml'
require 'savon'
require 'active_support'
require 'parsbank/version'
require 'parsbank/restfull'
require 'parsbank/bsc-bitcoin/bsc-bitcoin'
require 'parsbank/mellat/mellat'
require 'parsbank/zarinpal/zarinpal'
require 'parsbank/zibal/zibal'
require 'configuration'

# Main Module
module Parsbank
  class Error < StandardError; end

  $SUPPORTED_PSP = [
    'asanpardakht': {
      'name': 'Asan Pardakht CO.',
      'website': 'http://asanpardakht.ir',
      'tags': %w[iranian-psp ir rial]
    },
    'damavand': {
      'name': 'Electronic Card Damavand CO.',
      'website': 'http://ecd-co.ir',
      'tags': %w[iranian-psp ir rial]
    },
    'mellat': {
      'name': 'Behpardakht Mellat CO.',
      'website': 'http://behpardakht.com',
      'tags': %w[iranian-psp ir rial]
    },
    'pep': {
      'name': 'Pasargad CO.',
      'website': 'http://pep.co.ir',
      'tags': %w[iranian-psp ir rial]
    },

    'sep': {
      'name': 'Saman Bank CO.',
      'website': 'http://sep.ir',
      'tags': %w[iranian-psp ir rial]
    },
    'pna': {
      'name': 'Pardakht Novin Arian CO.',
      'website': 'http://pna.co.ir',
      'tags': %w[iranian-psp ir rial]
    },
    'pec': {
      'name': 'Parsian Bank CO.',
      'website': 'http://pec.ir',
      'tags': %w[iranian-psp ir rial]
    },

    'sadad': {
      'name': 'Sadad Bank CO.',
      'website': 'http://sadadco.‌com',
      'tags': %w[iranian-psp ir rial]
    },
    'sayan': {
      'name': 'Sayan Card CO.',
      'website': 'http://sayancard.ir',
      'tags': %w[iranian-psp ir rial]
    },

    'fanava': {
      'name': 'Fan Ava Card CO.',
      'website': 'http://fanavacard.com',
      'tags': %w[iranian-psp ir rial]
    },
    'kiccc': {
      'name': 'IranKish CO.',
      'website': 'http://kiccc.com',
      'tags': %w[iranian-psp ir rial]
    },

    'sepehr': {
      'name': 'Sepehr Bank CO.',
      'website': 'http://www.sepehrpay.com',
      'tags': %w[iranian-psp ir rial]
    },

    'zarinpal': {
      'name': 'Zarinpal',
      'website': 'http://www.sepehrpay.com',
      'tags': %w[iranian-psp ir rial]
    },
    'zibal': {
      'name': 'Zibal',
      'website': 'http://zibal.ir',
      'tags': %w[iranian-psp ir rial]
    },
    'bscbitcoin': {
      'name': 'Binance Bitcoin',
      'website': 'https://bitcoin.org',
      'tags': %w[btc bitcoin binance bsc crypto]
    }
  ]
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end

  def self.gateways_list
    load_secrets_yaml
  end

  def self.available_gateways_list
    load_secrets_yaml.select { |_, value| value['enabled'] }
  end


  def self.initialize_in_rails
    return unless defined?(Rails)

    ActiveSupport.on_load(:after_initialize) do
      Parsbank.initialize!
    end
  end

  def self.initialize!
    if Parsbank.configuration.database_url.present?
      establish_connection
    else    
      puts "\033[31mERROR: database_url not enabled, Transaction history not stored on database\033[0m"
    end
  end

  def self.establish_connection
    database_url = Parsbank.configuration.database_url
    raise "DATABASE_URL environment variable is not set" if database_url.nil?
    begin
      ActiveRecord::Base.establish_connection(database_url)
      unless ActiveRecord::Base.connection.table_exists?('transactions')
        puts 'Create Transaction Table'
        # This line will raise an exception if the table doesn't exist
        ActiveRecord::Base.connection.create_table :transactions do |t|
          t.string :gateway
          t.string :amount
          t.string :unit
          t.string :track_id
          t.string :local_id
          t.integer :user_id
          t.text :description
          t.string :status
          t.timestamps
        end
      end
    rescue => e
      raise "Failed to connect to the database: #{e.message}"
    end

  end

  def self.redirect_to_gateway(args = {})
    bank = args.fetch(:bank, available_gateways_list.keys.sample)
    selected_bank = available_gateways_list.select { |k| k == bank }
    unless selected_bank.present?
      raise "Bank not enabled or not exists in #{Parsbank.configuration.secrets_path}: #{bank}"
    end

    description = args.fetch(:description)
    default_callback = "#{selected_bank[bank.to_s]['callback_url'] || Parsbank.configuration.callback_url}&bank_name=#{bank}"

    crypto_amount = args.fetch(:crypto_amount) if args.key?(:crypto_amount)
    fiat_amount = args.fetch(:fiat_amount) if args.key?(:fiat_amount)
    real_amount = args.fetch(:real_amount) if args.key?(:real_amount)

    if crypto_amount.nil? && fiat_amount.nil? && real_amount.nil?
      raise 'Amount fileds is emptey: crypto_amount OR fiat_amount OR real_amount'
    end

    if $SUPPORTED_PSP[bank.to_s]['tags'].include? 'crypto' && [crypto_amount, real_amount].compact.empty?
      raise "#{bank} needs crypto_amount or real_amount"
    end

    if $SUPPORTED_PSP[bank.to_s]['tags'].include? 'rial' && [fiat_amount, real_amount].compact.empty?
      raise "#{bank} needs fiat_amount or real_amount"
    end

    transaction = Object.const_get(Parsbank.configuration.model).create(
      description: description,
      getway: bank
      )

    puts transaction.id
    case bank
    when 'mellat'
      mellat_klass = Parsbank::Mellat.new(
        amount: args.fetch(:amount),
        additional_data: description,
        callback_url: default_callback,
        orderId: transaction.id
      )
      mellat_klass.call
      result = mellat_klass.redirect_form

    when 'zarinpal'
      zarinpal_klass = Parsbank::Zarinpal.new(
        amount: amount,
        additional_data: description,
        callback_url: default_callback
      )
      zarinpal_klass.call
      result = zarinpal_klass.redirect_form

    when 'zibal'
      Parsbank::Zibal.new(
        amount: amount,
        additional_data: description,
        callback_url: default_callback
      )
      zarinpal_klass.call
      result = zarinpal_klass.redirect_form
    when 'bscbitcoin'
      bscbitcoin_klass = Parsbank::BscBitcoin.new(
        additional_data: description
      )
      convert_real_amount_to_assets if crypto_amount.nil? && args.key?(:real_amount)

      result = bscbitcoin_klass.generate_payment_address(amount: amount)
    end

    result
  end

  def self.load_secrets_yaml
    # Load the YAML file specified by the secrets_path
    secrets = YAML.load_file(Parsbank.configuration.secrets_path)

    unless secrets.is_a?(Hash)
      raise "Error: Invalid format in #{Parsbank.configuration.secrets_path}. Expected a hash of bank secrets."
    end

    supported_banks = $SUPPORTED_PSP[0].keys

    secrets.each_key do |bank_key|
      unless supported_banks.include?(bank_key.to_sym)
        raise "#{bank_key.capitalize} in #{Parsbank.configuration.secrets_path} is not supported by ParsBank. \nSupported Banks: #{supported_banks.join(', ')}"
      end
    end

    secrets
  rescue Errno::ENOENT
    raise "Error: Secrets file not found at #{Parsbank.configuration.secrets_path}."
  rescue Psych::SyntaxError => e
    raise "Error: YAML syntax issue in #{Parsbank.configuration.secrets_path}: #{e.message}"
  end

  def self.gateways_list_shortcode
    banks_list = available_gateways_list.keys.map { |bank| render_bank_list_item(bank) }.join
    "<ul class='parsbank_selector'>#{banks_list}</ul>"
  end

  def self.render_bank_list_item(bank)
    bank_klass = Object.const_get("Parsbank::#{bank.capitalize}")
    _, _, body = begin
      bank_klass.logo
    rescue StandardError
      nil
    end
    <<~HTML
      <li class='parsbank_radio_wrapper #{bank}_wrapper'>
      #{'  '}
        <input type='radio' id='#{bank}' name='bank' value='#{bank}' />
        <label for='#{bank}'>#{begin
          File.read(body)
        rescue StandardError
          ''
        end} #{bank.upcase}</label>
      </li>
    HTML
  end
end



Parsbank.initialize_in_rails