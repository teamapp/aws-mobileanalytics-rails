module AwsmaRails
  class AwsmaPostRequest < AwsPostRequest
    @aws_signed_request_v4 = nil

    def initialize(endpoint_url, analytics_data, user_agent, aws_client_context, cognito_credentials)
      super(endpoint_url, analytics_data, user_agent, nil, aws_client_context)

      @cognito_credentials = cognito_credentials
    end

    def send_request
      if !@aws_signed_request_v4
        @aws_signed_request_v4 = AwsSignedRequestV4.new(@cognito_credentials,
                                                        'mobileanalytics',
                                                        'us-east-1',
                                                        endpoint_uri)

        @aws_signed_request_v4.sign(request)
      end

      http_client.request(@aws_signed_request_v4)
    end
  end
end
