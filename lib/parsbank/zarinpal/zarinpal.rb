# frozen_string_literal: true

module Parsbank
  class Zarinpal
    attr_accessor :amount, :description, :email, :mobile, :merchant_id
    attr_reader :response, :status, :status_message, :ref_id, :logo

    def initialize(args = {})
      @mobile = args.fetch(:mobile, nil)
      @email = args.fetch(:email, nil)
      @amount = args.fetch(:amount)
      @description = args.fetch(:description, ' ')
      @callback_url = args.fetch(:callback_url,
                                 (default_config(:callback_url) || Parsbank.configuration.callback_url))
      @merchant_id = args.fetch(:merchant_id, default_config(:merchant_id))
      @wsdl = create_wsdl_client
    rescue KeyError => e
      raise ArgumentError, "Missing required argument: #{e.message}"
    end

    def self.logo
      file_path = "#{__dir__}/logo.svg"
      return [404, { 'Content-Type' => 'text/plain' }, ['File not found']] unless File.exist?(file_path)

      File.read file_path
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

    def redirect_form(ref_id)
      javascript_tag = <<-JS
        <script type='text/javascript' charset='utf-8'>
          function postRefId(refIdValue) {
            var form = document.createElement('form');
            form.setAttribute('method', 'POST');
            form.setAttribute('action', 'https://www.zarinpal.com/pg/StartPay/' + refIdValue);
            form.setAttribute('target', '_self');
            var hiddenField = document.createElement('input');
            hiddenField.setAttribute('name', 'RefId');
            hiddenField.setAttribute('value', refIdValue);
            form.appendChild(hiddenField);
            document.body.appendChild(form);
            form.submit();
            document.body.removeChild(form);
          }
          postRefId('#{ref_id}');
        </script>
      JS
    
      "#{javascript_tag}#{t('actions.redirect_to_gate')}".html_safe
    end
    

    private

    def default_config(key)
      Parsbank.load_secrets_yaml[self.class.name.split('::').last.downcase][key.to_s]
    end

    def create_wsdl_client
      Savon.client(
        wsdl: default_config(:wsdl) || 'https://de.zarinpal.com/pg/services/WebGate/wsdl',
        pretty_print_xml: (Parsbank.configuration.debug ? true : false),
        namespace: 'http://interfaces.core.sw.bps.com/',
        log: (Parsbank.configuration.debug ? true : false),
        logger: Rails.logger,
        log_level: (Parsbank.configuration.debug ? :debug : :fatal)
      )
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
      @valid = @response[:status] == '100'
    end
  end
end
