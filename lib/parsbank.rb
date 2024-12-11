# frozen_string_literal: true

require 'yaml'
require_relative 'parsbank/version'
require_relative 'parsbank/mellat/mellat'

module Parsbank
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end

  def self.gateways_list
    return self.load_secrets_yaml
  end

  def self.available_gateways_list
    self.load_secrets_yaml.select { |_, value| value['enabled'] }
  end

  def self.redirect_to_gateway(amount:, bank:)
      selected_bank = self.available_gateways_list.select {|k| k == bank}
      raise 'Bank not enabled or not found' unless selected_bank.present?

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
      return YAML.load_file(Parsbank.configuration.secrets_path)
    rescue Errno::ENOENT
      raise 'Error: Secrets file of banks not found.'
    rescue Psych::SyntaxError => e
      raise "Secret bank YAML syntax error: #{e.message}"
  end
end
