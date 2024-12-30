# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
module Parsbank
  class Zibal
    attr_accessor :amount, :description, :email, :mobile, :merchant, :callbackUrl, :orderId, :allowedCards, :ledgerId,
                  :nationalCode, :checkMobileWithCard

    attr_reader :response, :status, :status_message, :ref_id, :logo

    def initialize(args = {})
      @amount = args.fetch(:amount)
      @description = args.fetch(:description, nil)
      @email = args.fetch(:email, nil)
      @mobile = args.fetch(:mobile, nil)
      @merchant = args.fetch(:merchant, default_config(:merchant))
      @callbackUrl = args.fetch(:callbackUrl, (default_config(:callback_url) || Parsbank.configuration.callback_url))
      @orderId = args.fetch(:orderId, nil)
      @allowedCards = args.fetch(:allowedCards, nil)
      @ledgerId = args.fetch(:ledgerId, nil)
      @nationalCode = args.fetch(:nationalCode, nil)
      @checkMobileWithCard = args.fetch(:checkMobileWithCard, nil)
    rescue KeyError => e
      raise ArgumentError, "Missing required argument: #{e.message}"
    end

    def self.logo
      file_path = "#{__dir__}/logo.svg"
      return [404, { 'Content-Type' => 'text/plain' }, ['File not found']] unless File.exist?(file_path)

      [
        200,
        { 'Content-Type' => 'image/svg+xml' },
        File.open(file_path, 'r')
      ]
    end

    def validate(response = nil)
      @response = response
      @ref_id = @response['trackId']
      @status = @response['result'].present? ? @response['result'] : 'FAILED'

      perform_validation
      self
    end

    def valid?
      @valid
    end

    def ref_id
      @ref_id.to_s
    end

    def call
      create_rest_client
    rescue Savon::Error => e
      raise "SOAP request failed: #{e.message}"
    end

    def redirect_form
      "
        <script type='text/javascript' charset='utf-8'>
  function postRefId (refIdValue) {
        var form = document.createElement('form');
        form.setAttribute('method', 'POST');
        form.setAttribute('action', 'https://gateway.zibal.ir/start/#{ref_id}');
        form.setAttribute('target', '_self');
        var hiddenField = document.createElement('input');
        hiddenField.setAttribute('name', 'RefId');
        hiddenField.setAttribute('value', refIdValue);
        form.appendChild(hiddenField);
        document.body.appendChild(form);
        form.submit();
        document.body.removeChild(form);
      }


        postRefId('#{ref_id}') %>')
      </script>
          "
    end

    private

    def default_config(key)
      Parsbank.load_secrets_yaml[self.class.name.split('::').last.downcase][key.to_s]
    end

    def create_rest_client
      connection = Parsbank::Restfull.new(
        endpoint: default_config(:endpoint) || 'https://gateway.zibal.ir',
        action: '/v1/request',
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{default_config(:access_token)}"
        },
        request_message: build_request_message,
        http_method: :post,
        response_type: :json
      )

      response = connection.call

      Rails.logger.info "Received response with status: #{response.status}, body: #{response.body.inspect}"

      if response.valid?
        validate(response.body)
      else
        @valid = false
        Rails.logger.error "POST request to #{BASE_URL}/#{endpoint} failed with status: #{response.status}, error: #{response.body.inspect}"
        raise "API request failed with status #{response.status}: #{response.body}"
      end
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error "Connection failed: #{e.message}"
      raise "Connection to API failed: #{e.message}"
    rescue Faraday::TimeoutError => e
      Rails.logger.error "Request timed out: #{e.message}"
      raise "API request timed out: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "An error occurred: #{e.message}"
      raise "An unexpected error occurred: #{e.message}"

      JSON.parse response.body
    end

    def build_request_message
      {
        'amount' => @amount,
        'description' => @description,
        'email' => @email,
        'mobile' => @mobile,
        'merchant' => @merchant,
        'callbackUrl' => @callbackUrl,
        'orderId' => @orderId,
        'allowedCards' => @allowedCards,
        'ledgerId' => @ledgerId,
        'nationalCode' => @nationalCode,
        'checkMobileWithCard' => @checkMobileWithCard
      }
    end

    def perform_validation
      # Logic for validation should be implemented here.
      # Update @valid, @status, and @status_message based on @response.
      @valid = @response['result'] == '100'
    end
  end
end
