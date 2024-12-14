# frozen_string_literal: true

require 'yaml'
require_relative 'parsbank/version'
require_relative 'parsbank/mellat/mellat'

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

  def self.redirect_to_gateway(amount:, bank:)
    selected_bank = available_gateways_list.select { |k| k == bank }
    raise 'Bank not enabled or not found' unless selected_bank.present?

    Parsbank.send(bank)
  end

  class Configuration
    attr_accessor :callback_url, :debug, :sandbox,
                  :webhook,
                  :webhook_method,
                  :mitm_server,
                  :secrets_path,
                  :min_amount,
                  :webpanel_path,
                  :username,
                  :password,
                  :allowed_ips,
                  :allow_when,
                  :captcha,
                  :model

    def initialize; end
  end

  def self.load_secrets_yaml
    cogs = YAML.load_file(Parsbank.configuration.secrets_path)
    cogs.keys.map do |k|
      raise "#{k.capitalize} on #{Parsbank.configuration.secrets_path} not supported by ParsBank \n Supported Banks: #{$SUPPORTED_PSP[0].keys.join(', ')}" unless $SUPPORTED_PSP[0].keys.include?(k.to_sym)
    end
    cogs
  rescue Errno::ENOENT
    raise 'Error: Secrets file of banks not found.'
  rescue Psych::SyntaxError => e
    raise "Secret bank YAML syntax error: #{e.message}"
  end
end
