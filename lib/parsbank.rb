# frozen_string_literal: true

require 'yaml'
require 'uri'
require 'erb'
require 'i18n'
require 'active_support'
require 'parsbank/version'
require 'db_setup'
require 'parsbank/restfull'
require 'parsbank/soap'
require 'parsbank/binance/binance'
require 'parsbank/mellat/mellat'
require 'parsbank/zarinpal/zarinpal'
require 'parsbank/zibal/zibal'
require 'parsbank/nobitex/nobitex'
require 'configuration'
require 'parsbank/transaction_request'
require 'parsbank/transaction_verify'

module Parsbank
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end

  def self.supported_psp
    JSON.parse(File.read(File.join(__dir__, 'psp.json')))
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
    I18n.load_path += Dir.glob(File.join(__dir__, 'locales', '*.yml'))
    I18n.available_locales = %i[en fa]
    I18n.enforce_available_locales = false

    Parsbank::DBSetup.establish_connection
  end

  def self.load_secrets_yaml
    # Load the YAML file specified by the secrets_path
    secrets = YAML.load_file(Parsbank.configuration.secrets_path)
    raise "Error: Invalid format in #{Parsbank.configuration.secrets_path}." unless secrets.is_a?(Hash)

    secrets.each_key do |bank_key|
      unless supported_psp.keys.include?(bank_key.to_s)
        raise "#{bank_key.capitalize} in #{Parsbank.configuration.secrets_path} is not supported by ParsBank. \nSupported Banks: #{supported_psp.keys.join(', ')}"
      end
    end
    secrets
  rescue Errno::ENOENT
    raise "Error: Secrets file not found at #{Parsbank.configuration.secrets_path}."
  rescue Psych::SyntaxError => e
    raise "Error: YAML syntax issue in #{Parsbank.configuration.secrets_path}: #{e.message}"
  end

  def self.gateways_list_shortcode(args = {})
    ERB.new(File.read(File.join(__dir__, 'tmpl', 'bank_list.html.erb'))).result(binding).gsub(/(?:\n\r?|\r\n?)/, '').gsub(/>\s+</, '><').gsub(
      /\s+/, ' '
    ).strip
  end
end

Parsbank.initialize_in_rails
