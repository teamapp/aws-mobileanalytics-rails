require 'net/http'
require 'uri'
require 'json'
require 'time'

require_relative 'aws_rails_analytics/aws_credentials'
require_relative 'aws_rails_analytics/aws_sign_request'

module AwsRailsAnalytics
  class Reporter
    attr_reader :aws_analytics_uri, :sign_v4, :user_agent

    # @param [String] aws_analytics_uri The amazon mobile analytics endpont
    # @param [Hash] options:
    #               [String] user_agent         The user agent to use in the requests to amazon (default is "Rails Server")
    #               [String] access_key_id      The aws access key
    #               [String] secret_access_key  The aws secret access key
    #               [String] session_token      The aws session token for the optional security header (optional)
    #               [String] service            The aws service (default is amazon mobile analytics)
    #               [String] region             The aws region
    #               [String] app_id             The mobile anlaytics app id
    def initialize aws_analytics_uri, options = {}
      default = {
          service: "mobileanalytics",
          user_agent: "Rails Server",
          session_token: nil
      }
      options = default.merge(options)

      @aws_analytics_uri = URI.parse(aws_analytics_uri)
      @sign_v4 = SignV4.new(Credentials.new(options[:access_key_id], options[:secret_access_key], options[:session_token]), options[:service], options[:region], URI.parse(aws_analytics_uri))
      @user_agent = options[:user_agent]
      @app_id = options[:app_id]
    end

    def report_event client_id, app_title, event_name, attributes = {}, metrics = {}

      http = Net::HTTP.new(aws_analytics_uri.host, aws_analytics_uri.port)
      http.use_ssl = (aws_analytics_uri.scheme == "https")

      request = Net::HTTP::Post.new(aws_analytics_uri.request_uri)

      request["User-Agent"] = user_agent
      request["Content-Type"] = "application/json"
      request["x-amz-Client-Context"] = create_client_context(client_id, app_title)
      request.body = create_analytics_data(event_name, "<session_id>", attributes, metrics)

      signed_request = sign_v4.sign(request)

      response = http.request(signed_request)
      puts response.body
    end

    def create_client_context client_id, app_title
      aws_client_context = {
          "client" => {
              "client_id" => client_id,
              "app_title" => app_title
          },
          "env" => {
              "platform" => "SERVER"
          },
          "services" => {
              "mobile_analytics" => {
                  "app_id" => app_id
              }
          }
      }

      return aws_client_context.to_json
    end

    def create_analytics_data event_name, session_id, attributes, metrics
      timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")

      aws_analytics_data = {"events" => [{
                                             "eventType" => event_name,
                                             "timestamp" => timestamp,
                                             "session" => {"id" => session_id, "startTimestamp" => "<session_start_timestamp>"},
                                             "attributes" => attributes,
                                             "metrics" => metrics
                                         }]}

      return aws_analytics_data.to_json
    end

  end
end
