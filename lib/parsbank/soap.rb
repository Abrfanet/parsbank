require 'net/http'
require 'uri'
require 'rexml/document'
module Parsbank
  # Soap Class
  class SOAP
    attr_reader :endpoint, :namespace

    def initialize(endpoint, namespace)
      @endpoint = URI.parse(endpoint)
      @namespace = namespace
    end

    def call(action, body, headers = {})
      xml = build_envelope(action, body.map { |k, v| "<s:#{k}>#{v}</#{k}>" }.join(''))

      http = Net::HTTP.new(@endpoint.host, @endpoint.port)
      http.use_ssl = (@endpoint.scheme == 'https')

      request = Net::HTTP::Post.new(@endpoint.request_uri)
      request.content_type = 'text/xml; charset=utf-8'
      request['SOAPAction'] = "#{@namespace}/#{action}"

      headers.store('Parsbank-RubyGem', Parsbank::VERSION)

      headers.each { |key, value| request[key] = value }
      request.body = xml

      response = http.request(request)
      parse_response(response)
    rescue Timeout::Error
      { error: 'Request timed out' }
    rescue SocketError
      { error: 'Network connection failed' }
    rescue Errno::ECONNREFUSED
      { error: 'Connection refused by server' }
    rescue StandardError => e
      { error: "Unexpected error: #{e.message}" }
    end

    private

    def build_envelope(action, body)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:s="#{@namespace}">
          <soap:Body>
            <s:#{action}>
              #{body}
            </s:#{action}>
          </soap:Body>
        </soap:Envelope>
      XML
    end

    def parse_response(response)
      case response
      when Net::HTTPSuccess
        parse_xml(response.body)
      else
        { error: "HTTP Error #{response.code}: #{response.message}" }
      end
    end

    def parse_xml(xml)
      doc = Hash.from_xml(xml)
      { success: true, body: doc }
    rescue
      {success: false, message: 'Invalid SOAP response' }
    end
  end
end
