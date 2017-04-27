module AwsmaRails
  class Reporter
    # @param [String] awsma_endpoint_url The aws mobile analytics endpoint URL
    # @param [String] awsma_app_id       The aws mobile analytics app id
    # @param [String] cognito_pool_id    The aws cognito identity pool id
    # @param [String] user_agent         The user agent to use in the requests to amazon (default is 'Rails Server')
    def initialize(awsma_endpoint_url, awsma_app_id, cognito_pool_id, user_agent = 'Rails Server')
      @awsma_endpoint_url = awsma_endpoint_url
      @app_id = awsma_app_id
      @cognito_pool_id = cognito_pool_id
      @user_agent = user_agent

      @aws_cognito_manager = AwsCognitoManager.new(@user_agent, @cognito_pool_id)

      @cognito_credentials = @aws_cognito_manager.generate_credentials
    end

    # @param  [String]  client_id   The users mobile analytics client id
    # @param  [String]  session_id  The users mobile analytics current session id (if there is no session just enter an empty string or something like 'no-session')
    # @param  [String]  app_title   The app title (ex: Fun Game)
    # @param  [String]  app_package_name  The app package name (ex: com.example.fungame)
    # @param  [String]  event_name  The name of the custom event to be reported to amazon
    # @param  [Hash]    attributes  The custom events attributes (optional)
    # @param  [Hash]    metrics     The custom events metrics (optional)
    # @return [Net::HTTP] response of analytics report (response code should be 202 if successful)
    def report_event(client_id, session_id, app_title, app_package_name, event_name, platform, model, attributes = {}, metrics = {})
      events = [{
                  'event_name' => event_name,
                  'session_id' => session_id,
                  'attributes' => attributes,
                  'metrics' => metrics
                }]

      self.report_events(client_id, app_title, app_package_name, platform, model, events)
    end

    # @param  [String]  client_id   The users mobile analytics client id
    # @param  [String]  app_title   The app title (ex: Fun Game)
    # @param  [String]  app_package_name  The app package name (ex: com.example.fungame)
    # @return [Net::HTTP] response of analytics report (response code should be 202 if successful)
    def report_events(client_id, app_title, app_package_name, platform, model, events = [{'event_name' => '', 'session_id' => '', 'attributes' => {}, 'metrics' => {}}])
      awsma_request = AwsmaPostRequest.new(@awsma_endpoint_url,
                                           create_analytics_data(events),
                                           @user_agent,
                                           create_client_context(client_id, app_title, app_package_name, platform, model),
                                           @cognito_credentials)

      response = awsma_request.send_request

      if response.code === '403' &&
          (JSON.parse(response.body)['message'] === 'The security token included in the request is expired')
        awsma_request.refresh_credentials(@aws_cognito_manager.generate_credentials)
        response = awsma_request.send_request
      end

      response
    end

    private

    def create_analytics_data(events)
      request_events = events.inject([]) do |request_events, event|
        event = event.symbolize_keys
        timestamp = Time.now.utc.iso8601

        request_events << {
            'eventType' => event[:event_name],
            'timestamp' => timestamp,
            'version' => 'v2.0',
            'session' => {
                'id' => event[:session_id],
                'startTimestamp' => timestamp
            },
            'attributes' => event[:attributes],
            'metrics' => event[:metrics]
        }
      end

      aws_analytics_data = {
          'events' => request_events
      }

      aws_analytics_data.to_json
    end

    def create_client_context(client_id, app_title, app_package_name, platform = 'linux', model = 'SERVER')
      aws_client_context = {
          'client' => {
              'client_id' => client_id,
              'app_title' => app_title,
              'app_package_name' => app_package_name
          },
          'env' => {
              'platform' => platform,
              'model' => model
          },
          'services' => {
              'mobile_analytics' => {
                  'app_id' => @app_id,
                  'sdk_name' => 'awsma_rails',
                  'sdk_version' => AwsmaRails::VERSION
              }
          }
      }

      aws_client_context.to_json
    end
  end
end