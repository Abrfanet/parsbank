module Parsbank
  class Restfull
    attr_accessor :connection

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

      Rails.logger.info("Received response with status: #{response.status}, body: #{response.body.inspect}")

      if response.success?
        response
      else
        log_and_raise_error(response)
      end
    rescue Faraday::ConnectionFailed => e
      handle_error("Connection failed: #{e.message}", e)
    rescue Faraday::TimeoutError => e
      handle_error("Request timed out: #{e.message}", e)
    rescue StandardError => e
      handle_error("An unexpected error occurred: #{e.message}", e)
    end

    private

    def webhook(_message)
      connection = Faraday.new(Parsbank.configuration.webhook) do |conn|
        conn.request :json if @response_type == :json # Automatically converts payload to JSON
        conn.response :json if @response_type == :json # Automatically parses JSON response
        conn.adapter Faraday.default_adapter
        conn.request :retry, max: 3, interval: 0.05,
                             interval_randomness: 0.5, backoff_factor: 2,
                             exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
        conn.use FaradayMiddleware::FollowRedirects
      end

      case Parsbank.configuration.webhook_method
      when :post
        connection.post('&parsbank') do |req|
          req.headers = headers
          req.body = {}
        end

      when :get
        connection.get('&parsbank')
      end
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error("Webhook Connection failed: #{e.message}", e)
    rescue Faraday::TimeoutError => e
      Rails.logger.error("Webhook Request timed out: #{e.message}", e)
    rescue StandardError => e
      Rails.logger.error("Webhook An unexpected error occurred: #{e.message}", e)
    end

    def setup_connection
      @connection = Faraday.new(@endpoint) do |conn|
        conn.request :json if @response_type == :json # Automatically converts payload to JSON
        conn.response :json if @response_type == :json # Automatically parses JSON response
        conn.adapter Faraday.default_adapter
        conn.request :retry, max: 3, interval: 0.05,
                             interval_randomness: 0.5, backoff_factor: 2,
                             exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
        conn.use FaradayMiddleware::FollowRedirects
      end
    end

    def send_request
      headers = default_headers.merge(@headers)

      case @http_method
      when :post
        perform_post(headers)
      when :get
        perform_get(headers)
      when :options
        perform_options(headers)
      else
        raise ArgumentError, "HTTP Method Not Allowed: #{@http_method}"
      end
    end

    def perform_post(headers)
      @connection.post(@action) do |req|
        req.headers = headers
        req.body = @request_message
      end
    end

    def perform_get(headers)
      @connection.get(@action) do |req|
        req.headers = headers
        req.params = @request_message
      end
    end

    def perform_options(headers)
      @connection.options(@action) do |req|
        req.headers = headers
      end
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'Parsbank-RubyGem' => Parsbank::VERSION
      }
    end

    def log_and_raise_error(response)
      Rails.logger.error("Request to #{@endpoint}/#{@action} failed with status: #{response.status}, error: #{response.body.inspect}")
      raise "API request failed with status #{response.status}: #{response.body}"
    end

    def handle_error(message, exception)
      Rails.logger.error(message)
      webhook(message) if Parsbank.configuration.webhook.present?
      raise exception
    end
  end
end
