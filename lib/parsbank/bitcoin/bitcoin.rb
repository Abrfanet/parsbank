require 'faraday'
require 'json'
require 'openssl'
require 'base64'

class BinancePaymentGateway
  API_BASE_URL = 'https://api.binance.com'

  attr_accessor :api_key, :secret_key

  def initialize(args = {})
    @api_key = args.fetch(:api_key)
    @secret_key = args.fetch(:secret_key)
    @connection = Faraday.new(API_BASE_URL) do |conn|
      conn.request :json
      conn.response :json, content_type: 'application/json'
      conn.adapter Faraday.default_adapter
    end
  end

  # Generate a payment address for a given cryptocurrency
  def generate_payment_address(asset:, network: nil)
    endpoint = '/sapi/v1/capital/deposit/address'
    params = {
      asset: asset,
      network: network
    }
    response = signed_request(:get, endpoint, params)
    response_body(response)
  end

  # Verify a transaction by checking its status
  def verify_transaction(tx_id:, asset:)
    endpoint = '/sapi/v1/capital/deposit/hisrec'
    params = {
      txId: tx_id,
      asset: asset
    }
    response = signed_request(:get, endpoint, params)
    transactions = response_body(response)

    transaction = transactions.find { |t| t['txId'] == tx_id }
    transaction && transaction['status'] == 1
  end

  # Get the latest transactions for a given asset
  def latest_transactions(asset:, limit: 10)
    endpoint = '/sapi/v1/capital/deposit/hisrec'
    params = {
      asset: asset,
      limit: limit
    }
    response = signed_request(:get, endpoint, params)
    response_body(response)
  end

  private

  # Helper method to handle signed requests
  def signed_request(http_method, endpoint, params = {})
    params[:timestamp] = current_timestamp
    query_string = URI.encode_www_form(params)
    signature = generate_signature(query_string)
    headers = {
      'X-MBX-APIKEY' => @api_key
    }

    @connection.send(http_method) do |req|
      req.url endpoint
      req.params = params.merge(signature: signature)
      req.headers = headers
    end
  end

  # Generate HMAC SHA256 signature
  def generate_signature(query_string)
    OpenSSL::HMAC.hexdigest('SHA256', @secret_key, query_string)
  end

  # Helper method to parse response
  def response_body(response)
    if response.success?
      JSON.parse(response.body)
    else
      raise "Binance API Error: #{response.status} - #{response.body}"
    end
  end

  # Current timestamp in milliseconds
  def current_timestamp
    (Time.now.to_f * 1000).to_i
  end
end