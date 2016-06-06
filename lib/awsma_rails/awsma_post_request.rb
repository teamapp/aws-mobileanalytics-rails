module AwsmaRails
  class AwsmaPostRequest < AwsPostRequest
    @aws_signed_request = nil

    def initialize(endpoint_url, analytics_data, user_agent, aws_client_context, cognito_credentials)
      super(endpoint_url, analytics_data, user_agent, nil, aws_client_context)

      @cognito_credentials = cognito_credentials

      @mutex = Mutex.new
    end

    def send_request
      @mutex.synchronize {
        if !@aws_signed_request
          aws_signed_request_v4 = AwsSignedRequestV4.new(@cognito_credentials,
                                                          'mobileanalytics',
                                                          'us-east-1',
                                                          endpoint_uri)

          @aws_signed_request = aws_signed_request_v4.sign(request)
        end

        http_client.request(@aws_signed_request)
      }
    end

    def refresh_credentials(cognito_credentials)
      @mutex.synchronize {
        @cognito_credentials = cognito_credentials
        @aws_signed_request = nil
      }
    end
  end
end
