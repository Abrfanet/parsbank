# frozen_string_literal: true

require_relative 'parsbank/version'

module Parsbank
  class Error < StandardError; end
  class << self
    attr_accessor :configuration
  end
  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
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
end
