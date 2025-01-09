require 'net/http'
require 'uri'
require 'json'

module Parsbank
  class Restfull
    attr_accessor :connection

    MAX_RETRIES = 3
    RETRY_INTERVAL = 1 # In seconds

    def initialize(args = {})
      @endpoint = args.fetch(:endpoint)
      @action = args.fetch(:action)
      @headers = args.fetch(:headers, {})
      @request_message = args.fetch(:request_message, {})
      @http_method = args.fetch(:http_method)
      @response_type = args.fetch(:response_type, :json)

      setup_connection
    end

    def call
      response = send_request
      log_response(response)

      if response.is_a?(Net::HTTPSuccess)
        parse_response(response)
      else
        log_and_raise_error(response)
      end
    rescue Timeout::Error => e
      handle_error("Request timed out: #{e.message}", e)
    rescue StandardError => e
      handle_error("An unexpected error occurred: #{e.message}", e)
    end

    private

    def setup_connection
      @uri = URI.parse(@endpoint)
      @connection = Net::HTTP.new(@uri.host, @uri.port)
      @connection.use_ssl = true if @uri.scheme == 'https'

      # Setting timeouts
      @connection.open_timeout = 10 # Time to wait for the connection to open
      @connection.read_timeout = 10 # Time to wait for a response
    end

    def send_request
      retries = 0
      begin
        request = build_request
        @connection.start do
          response = @connection.request(request)

          # Handling redirects manually (max 5 redirects)
          handle_redirects(response)
          
          return response
        end
      rescue Timeout::Error => e
        retries += 1
        if retries < MAX_RETRIES
          log_to_rails("Timeout occurred. Retrying... (#{retries}/#{MAX_RETRIES})", :warn)
          sleep(RETRY_INTERVAL)
          retry
        else
          raise "Request timed out after #{MAX_RETRIES} retries: #{e.message}"
        end
      rescue StandardError => e
        log_to_rails("Request failed: #{e.message}", :error)
        raise e
      end
    end

    def build_request
      case @http_method
      when :post
        build_post_request
      when :get
        build_get_request
      when :options
        build_options_request
      else
        raise ArgumentError, "HTTP Method Not Allowed: #{@http_method}"
      end
    end

    def build_post_request
      request = Net::HTTP::Post.new(@action, default_headers)
      request.body = @request_message.to_json if @request_message.any?
      request
    end

    def build_get_request
      request = Net::HTTP::Get.new(@action, default_headers)
      request.set_form_data(@request_message) if @request_message.any?
      request
    end

    def build_options_request
      Net::HTTP::Options.new(@action, default_headers)
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'Parsbank-RubyGem' => Parsbank::VERSION
      }.merge(@headers)
    end

    def log_response(response)
      log_to_rails("Received response with status: #{response.code}, body: #{response.body.inspect}", :info)
    end

    def parse_response(response)
      return response.body if @response_type == :raw

      case @response_type
      when :json
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def log_and_raise_error(response)
      log_to_rails("Request to #{@endpoint}/#{@action} failed with status: #{response.code}, error: #{response.body.inspect}", :error)
      raise "API request failed with status #{response.code}: #{response.body}"
    end

    def handle_error(message, exception)
      log_to_rails(message, :error)
      webhook(message) if Parsbank.configuration.webhook.present?
      raise exception
    end

    def log_to_rails(message, level = :info)
      case level
      when :error
        Rails.logger.error(message) if defined?(Rails)
      when :warn
        Rails.logger.warn(message) if defined?(Rails)
      else
        Rails.logger.info(message) if defined?(Rails)
      end
    end

    def webhook(message)
      webhook_url = Parsbank.configuration.webhook
      webhook_url.gsub!('MESSAGE', message) if Parsbank.configuration.webhook_method == :get
      webhook_url.gsub!('TITLE', "Webhook of Connection Error at #{Time.now}") if Parsbank.configuration.webhook_method == :get

      uri = URI.parse(webhook_url)
      connection = Net::HTTP.new(uri.host, uri.port)
      connection.use_ssl = uri.scheme == 'https'

      case Parsbank.configuration.webhook_method
      when :post
        request = Net::HTTP::Post.new(uri.path, default_headers)
        request.body = {}.to_json
        connection.request(request)
      when :get
        request = Net::HTTP::Get.new(uri.path, default_headers)
        connection.request(request)
      end
    rescue StandardError => e
      log_to_rails("Webhook Error: #{e.message}", :error)
    end

    def handle_redirects(response)
      if response.is_a?(Net::HTTPRedirection)
        location = response['Location']
        log_to_rails("Redirecting to: #{location}", :warn)
        redirect_uri = URI.parse(location)
        request = Net::HTTP::Get.new(redirect_uri)
        @connection.request(request)
      end
    end
  end
end
