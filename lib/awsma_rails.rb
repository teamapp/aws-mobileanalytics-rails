require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'awsma_rails/version'

require_relative 'awsma_rails/aws_credentials'
require_relative 'awsma_rails/aws_sign_request'

module AwsmaRails
  class Reporter
    attr_reader :aws_analytics_uri, :user_agent, :app_id, :cognito_pool_id, :cognito_credentials

    # @param [String] aws_analytics_uri  The amazon mobile analytics endpont
    # @param [String] user_agent         The user agent to use in the requests to amazon (default is "Rails Server")
    # @param [String] app_id             The mobile anlaytics app id
    # @param [String] cognito_pool_id    The cognito identity pool id
    def initialize aws_analytics_uri, app_id, cognito_pool_id, user_agent = "Rails Server"
      @aws_analytics_uri = URI.parse(aws_analytics_uri)
      @user_agent = user_agent
      @app_id = app_id
      @cognito_pool_id = cognito_pool_id
      @cognito_credentials = get_cognito_credentials
    end

    # @param  [String]  client_id   The users mobile analytics client id
    # @param  [String]  session_id  The users mobile analytics current session id (if there is no session just enter an empty string or something like "no-session")
    # @param  [String]  app_title   The app title (ex: Fun Game)
    # @param  [String]  app_package_name  The app package name (ex: com.example.fungame)
    # @param  [String]  event_name  The name of the custom event to be reported to amazon
    # @param  [Hash]    attributes  The custom events attributes (optional)
    # @param  [Hash]    metrics     The custom events metrics (optional)
    # @return [Net::HTTP] response of analytics report (response code should be 202 if successful)
    def report_event client_id, session_id, app_title, app_package_name, event_name, attributes = {}, metrics = {}
      sign_v4 = SignV4.new(cognito_credentials, "mobileanalytics", "us-east-1", aws_analytics_uri)

      http = Net::HTTP.new(aws_analytics_uri.host, aws_analytics_uri.port)
      http.use_ssl = (aws_analytics_uri.scheme == "https")

      request = Net::HTTP::Post.new(aws_analytics_uri.request_uri)

      request["User-Agent"] = user_agent
      request["Content-Type"] = "application/x-amz-json-1.0"
      request["x-amz-Client-Context"] = create_client_context(client_id, app_title, app_package_name)
      request.body = create_analytics_data(event_name, session_id, attributes, metrics)

      signed_request = sign_v4.sign(request)

      response = http.request(signed_request)


      if response.code === "403" && JSON.parse(response.body)["message"] === "The security token included in the request is expired"
        @cognito_credentials = get_cognito_credentials
        return report_event(client_id, session_id, app_title, event_name, attributes, metrics)
      end

      response
    end

    # @return [AwsmaRails::Reporter::Credentials]  The newly generated cognito credentials
    def get_cognito_credentials
      aws_cognito_uri = URI.parse("https://cognito-identity.us-east-1.amazonaws.com")

      getid_response = cognito_getid(aws_cognito_uri)
      identityid = JSON.parse(getid_response.body)["IdentityId"]

      getcredentials_response = cognito_getcredentials(aws_cognito_uri, identityid)

      parsed_credentials = JSON.parse(getcredentials_response.body)["Credentials"]
      Credentials.new(parsed_credentials["AccessKeyId"], parsed_credentials["SecretKey"], parsed_credentials["SessionToken"])
    end

    def create_client_context client_id, app_title, app_package_name
      aws_client_context = {
          "client" => {
              "client_id" => client_id,
              "app_title" => app_title,
              "app_package_name" => app_package_name
          },
          "env" => {
              "platform" => "linux",
              "model" => "SERVER"
          },
          "services" => {
              "mobile_analytics" => {
                  "app_id" => app_id,
                  "sdk_name" => "awsma_rails",
                  "sdk_version" => AwsmaRails::VERSION
              }
          }
      }

      aws_client_context.to_json
    end

    def create_analytics_data event_name, session_id, attributes, metrics
      timestamp = Time.now.utc.iso8601

      aws_analytics_data = {"events" => [{
                                             "eventType" => event_name,
                                             "timestamp" => timestamp,
                                             "version" => "v2.0",
                                             "session" => {"id" => session_id,
                                                           "startTimestamp" => timestamp},
                                             "attributes" => attributes,
                                             "metrics" => metrics
                                         }]}

      aws_analytics_data.to_json
    end

    def cognito_getid aws_cognito_uri
      http = Net::HTTP.new(aws_cognito_uri.host, aws_cognito_uri.port)
      http.use_ssl = (aws_cognito_uri.scheme == "https")

      request = Net::HTTP::Post.new(aws_cognito_uri.request_uri)

      request["User-Agent"] = user_agent
      request["Content-Type"] = "application/x-amz-json-1.0"
      request["X-Amz-Target"] = "AWSCognitoIdentityService.GetId"
      request.body = {
          "IdentityPoolId" => cognito_pool_id,
          "Logins" => {}
      }.to_json

      http.request(request)
    end

    def cognito_getcredentials aws_cognito_uri, identityid
      http = Net::HTTP.new(aws_cognito_uri.host, aws_cognito_uri.port)
      http.use_ssl = (aws_cognito_uri.scheme == "https")

      request = Net::HTTP::Post.new(aws_cognito_uri.request_uri)

      request["User-Agent"] = user_agent
      request["Content-Type"] = "application/x-amz-json-1.0"
      request["X-Amz-Target"] = "AWSCognitoIdentityService.GetCredentialsForIdentity"
      request.body = {
        "IdentityId" => identityid,
        "Logins" => {}
      }.to_json

      http.request(request)
    end

  end
end
