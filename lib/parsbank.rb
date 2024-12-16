# frozen_string_literal: true

require 'yaml'
require 'savon'

require 'parsbank/version'
require 'parsbank/mellat/mellat'
require 'parsbank/zarinpal/zarinpal'
require 'configuration'

# Main Module
module Parsbank
  class Error < StandardError; end

  $SUPPORTED_PSP = [
    'asanpardakht': {
      'name': 'Asan Pardakht CO.',
      'website': 'http://asanpardakht.ir'
    },
    'damavand': {
      'name': 'Electronic Card Damavand CO.',
      'website': 'http://ecd-co.ir'
    },
    'mellat': {
      'name': 'Behpardakht Mellat CO.',
      'website': 'http://behpardakht.com'
    },
    'pep': {
      'name': 'Pasargad CO.',
      'website': 'http://pep.co.ir'
    },

    'sep': {
      'name': 'Saman Bank CO.',
      'website': 'http://sep.ir'
    },
    'pna': {
      'name': 'Pardakht Novin Arian CO.',
      'website': 'http://pna.co.ir'
    },
    'pec': {
      'name': 'Parsian Bank CO.',
      'website': 'http://pec.ir'
    },

    'sadad': {
      'name': 'Sadad Bank CO.',
      'website': 'http://sadadco.‌com'
    },
    'sayan': {
      'name': 'Sayan Card CO.',
      'website': 'http://sayancard.ir'
    },

    'fanava': {
      'name': 'Fan Ava Card CO.',
      'website': 'http://fanavacard.com'
    },
    'kiccc': {
      'name': 'IranKish CO.',
      'website': 'http://kiccc.com'
    },

    'sepehr': {
      'name': 'Sepehr Bank CO.',
      'website': 'http://www.sepehrpay.com'
    },

    'zarinpal': {
      'name': 'Zarinpal',
      'website': 'http://www.sepehrpay.com'
    },
    'zibal': {
      'name': 'Zibal',
      'website': 'http://zibal.ir'
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

  def self.redirect_to_gateway(amount:, bank:, description:)
    selected_bank = available_gateways_list.select { |k| k == bank }
    raise "Bank not enabled or not found: #{bank}" unless selected_bank.present?

    case bank
    when 'mellat'
     mellat_klass= Parsbank::Mellat.new(
        amount: amount,
        additional_data: description,
        callback_url: selected_bank['mellat']['callback_url'] || Parsbank.configuration.callback_url,
        orderId: rand(1...9999)
      )
      mellat_klass.call
      result= mellat_klass.redirect_form

    when 'zarinpal'
      zarinpal_klass= Parsbank::Zarinpal.new(
        amount: amount,
        additional_data: description,
        callback_url: selected_bank['mellat']['callback_url'] || Parsbank.configuration.callback_url
      )
      zarinpal_klass.call
      result= zarinpal_klass.redirect_form

    end

    
    return result
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
end
