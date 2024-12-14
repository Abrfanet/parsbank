module Parsbank
    class Mellat
      attr_accessor :order_id, :amount, :local_date, :local_time, :additional_data, :payer_id, :callback_url
      attr_reader :response, :status, :status_message, :ref_id
  
      def initialize(args = {})
        @order_id = args.fetch(:orderId)
        @amount = args.fetch(:amount)
        @local_date = args.fetch(:localDate, Time.now.strftime('%Y%m%d'))
        @local_time = args.fetch(:localTime, Time.now.strftime('%H%M%S'))
        @additional_data = args.fetch(:additionalData, ' ')
        @payer_id = args.fetch(:payerId, 0)
        @callback_url = args.fetch(:callBackUrl, default_config(:callBackUrl))
        @terminal_id = args.fetch(:terminalId, default_config(:terminalId))
        @username = args.fetch(:userName, default_config(:userName))
        @user_password = args.fetch(:userPassword, default_config(:userPassword))
        @wsdl = create_wsdl_client
      rescue KeyError => e
        raise ArgumentError, "Missing required argument: #{e.message}"
      end
  
      def validate(response = nil)
        @response = response
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
        response = @wsdl.call(:bp_pay_request, message: build_request_message)
        validate(response.body)
      rescue Savon::Error => e
        raise "SOAP request failed: #{e.message}"
      end
  
      private
  
      def default_config(key)
        Mellat.configuration.public_send(key)
      end
  
      def create_wsdl_client
        Savon.client(
          wsdl: default_config(:wsdl),
          pretty_print_xml: true,
          namespace: 'http://interfaces.core.sw.bps.com/'
        )
      end
  
      def build_request_message
        {
          'terminalId' => @terminal_id,
          'userName' => @username,
          'userPassword' => @user_password,
          'orderId' => @order_id,
          'amount' => @amount,
          'localDate' => @local_date,
          'localTime' => @local_time,
          'additionalData' => @additional_data,
          'payerId' => @payer_id,
          'callBackUrl' => @callback_url
        }
      end
  
      def perform_validation
        # Logic for validation should be implemented here.
        # Update @valid, @status, and @status_message based on @response.
      end
    end
  end
  