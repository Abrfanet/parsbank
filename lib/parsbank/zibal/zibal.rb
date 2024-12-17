require 'faraday'
require 'faraday_middleware'
module Parsbank
    class Zibal
      attr_accessor :amount, :description, :email, :mobile, :merchant,:callbackUrl, :orderId, :allowedCards, :ledgerId, :nationalCode, :checkMobileWithCard

      attr_reader :response, :status, :status_message, :ref_id, :logo
  
      def initialize(args = {})
        @mobile = args.fetch(:mobile, nil)
        @email = args.fetch(:email, nil)
        @amount = args.fetch(:amount)
        @description = args.fetch(:description, ' ')
        @callback_url = args.fetch(:callback_url, (default_config(:callback_url) || Parsbank.configuration.callback_url ))
        @merchant_id = args.fetch(:merchant_id, default_config(:merchant_id))
        @wsdl = create_rest_client
      rescue KeyError => e
        raise ArgumentError, "Missing required argument: #{e.message}"
      end

      def self.logo
        file_path = "#{File.expand_path File.dirname(__FILE__)}/logo.svg"
        return [404, { "Content-Type" => "text/plain" }, ["File not found"]] unless File.exist?(file_path)
        [
          200,
          { "Content-Type" => "image/svg+xml" },
          File.open(file_path, "r")
        ]
      end
  
      def validate(response = nil)
        @response = response[:payment_request_response] || response[:payment_verification_response] || response
        @ref_id = @response[:authority]
        @status = @response[:status].present? ? @response[:status] : 'FAILED'

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
        response = @wsdl.call(:payment_request, message: build_request_message)
        validate(response.body)
      rescue Savon::Error => e
        raise "SOAP request failed: #{e.message}"
      end
  
      def redirect_form
        "
        <script type='text/javascript' charset='utf-8'>
  function postRefId (refIdValue) {
        var form = document.createElement('form');
        form.setAttribute('method', 'POST');
        form.setAttribute('action', 'https://www.zarinpal.com/pg/StartPay/#{ref_id}');
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
        Parsbank.load_secrets_yaml[self.class.name.split("::").last.downcase][key.to_s]
      end
  
      def create_rest_client
        response = Faraday.new(url: default_config(:endpoint) || 'https://gateway.zibal.ir') do |conn|
          conn.request :json # Automatically converts payload to JSON
          conn.response :json # Automatically parses JSON response
          conn.adapter Faraday.default_adapter
        end.post('/v1/request') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{default_config(:access_token)}" # Optional if API requires authentication
          req.headers['User-Ajent'] = "ParsBank #{Parsbank::VERSION}"

          req.body = build_request_message
        end


        Rails.logger.info "Received response with status: #{response.status}, body: #{response.body.inspect}"

        if response.success?
          response.body # Parsed JSON response
        else
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



        


      
      response_json = JSON.parse response.body
      

        
      end
  
      def build_request_message
        {
          'MerchantID' => @merchant_id,
          'Mobile' => @mobile,
          'Email' => @email,
          'Amount' => @amount,
          'Description' => @description,
          'CallbackURL' => @callback_url
        }
      end
  
      def perform_validation
        # Logic for validation should be implemented here.
        # Update @valid, @status, and @status_message based on @response.
        @valid = @response[:status] == '100' ? true : false
      end
    end
  end
  