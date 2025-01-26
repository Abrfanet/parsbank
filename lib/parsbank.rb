# frozen_string_literal: true

require 'yaml'
require 'savon'
require 'uri'
require 'active_support'
require 'parsbank/version'
require 'db_setup'
require 'parsbank/restfull'
require 'parsbank/bsc-bitcoin/bsc-bitcoin'
require 'parsbank/mellat/mellat'
require 'parsbank/zarinpal/zarinpal'
require 'parsbank/zibal/zibal'
require 'configuration'
require 'parsbank/transaction_request'

module Parsbank
  class Error < StandardError; end

  $SUPPORTED_PSP = JSON.parse(File.read(File.join(__dir__, 'psp.json')))

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
    Parsbank::DBSetup.establish_connection
  end

  def self.load_secrets_yaml
    # Load the YAML file specified by the secrets_path
    secrets = YAML.load_file(Parsbank.configuration.secrets_path)

    unless secrets.is_a?(Hash)
      raise "Error: Invalid format in #{Parsbank.configuration.secrets_path}. Expected a hash of bank secrets."
    end

    supported_banks = $SUPPORTED_PSP.keys

    secrets.each_key do |bank_key|
      unless supported_banks.include?(bank_key.to_s)
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
    "<ul class='parsbank_selector'>#{banks_list}</ul>".gsub(/(?:\n\r?|\r\n?)/, '')
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
        <input type='radio' id='#{bank}' name='bank' value='#{bank}' /><label for='#{bank}'>#{begin
          File.read(body)
        rescue StandardError
          ''
        end}#{bank.camelcase}</label>
      </li>
    HTML
  end
end

Parsbank.initialize_in_rails