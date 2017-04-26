require 'net/http'

module AwsmaRails
  class AwsPostRequest
    def initialize(endpoint_url, body, user_agent, custom_aws_target = nil, custom_aws_client_context = nil)
      @endpoint_uri =  URI.parse(endpoint_url)

      @http_client = Net::HTTP.new(@endpoint_uri.host, @endpoint_uri.port)
      @http_client.use_ssl = (@endpoint_uri.scheme == 'https')

      @request = Net::HTTP::Post.new(@endpoint_uri.request_uri)

      @request['User-Agent'] = user_agent
      @request['Content-Type'] = 'application/x-amz-json-1.0'

      if !custom_aws_target.nil?
        @request['X-Amz-Target'] = custom_aws_target
      end

      if !custom_aws_client_context.nil?
        @request['x-amz-Client-Context'] = custom_aws_client_context
      end

      @request.body = body
    end

    def send_request
      @http_client.request(@request)
    end

    protected

    def endpoint_uri
      @endpoint_uri
    end

    def request
      @request
    end

    def http_client
      @http_client
    end
  end
end
