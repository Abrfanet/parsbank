# frozen_string_literal: true

require 'yaml'
require 'savon'
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


  def self.redirect_to_gateway(args = {})
    amount = args.fetch(:amount)
    bank = args.fetch(:bank, 'random-irr-gates')
    description = args.fetch(:description, '')

    selected_bank = available_gateways_list.select { |k| k == bank }
    raise "Bank not enabled or not exists on bank_secrets.yml: #{bank}" unless selected_bank.present?

    default_callback = Parsbank.configuration.callback_url + "&bank_name=#{bank}"

    case bank
    when 'mellat'
      mellat_klass = Parsbank::Mellat.new(
        amount: amount,
        additional_data: description,
        callback_url: selected_bank['mellat']['callback_url'] || default_callback,
        orderId: rand(1...9999)
      )
      mellat_klass.call
      result = mellat_klass.redirect_form

    when 'zarinpal'
      zarinpal_klass = Parsbank::Zarinpal.new(
        amount: amount,
        additional_data: description,
        callback_url: selected_bank['zarinpal']['callback_url'] || default_callback
      )
      zarinpal_klass.call
      result = zarinpal_klass.redirect_form

    when 'zibal'
      Parsbank::Zibal.new(
        amount: amount,
        additional_data: description,
        callback_url: selected_bank['zibal']['callback_url'] || default_callback
      )
      zarinpal_klass.call
      result = zarinpal_klass.redirect_form
    when 'bscbitcoin'
      bscbitcoin_klass = Parsbank::BscBitcoin.new(
        additional_data: description
      )
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

  private 
  def self.render_bank_list_item(bank)
    bank_klass=Object.const_get("Parsbank::#{bank.capitalize}")
    status, headers, body = bank_klass.logo rescue nil
    <<~HTML
      <li class='parsbank_radio_wrapper #{bank}_wrapper'>
        #{File.read(body) rescue ''}
        <input type='radio' id='#{bank}' name='bank' value='#{bank}' />
        <label for='#{bank}'>#{bank.upcase}</label>
      </li>
    HTML
  end

end
