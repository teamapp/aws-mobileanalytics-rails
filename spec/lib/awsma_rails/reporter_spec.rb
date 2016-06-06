require 'spec_helper'

describe AwsmaRails::Reporter do
  describe '#new' do
    before(:each) do
      @awsma_endpoint_url = 'http://www.thumzap.com:3000/a/b/c'
      @awsma_app_id = 'awsma_app_id'
      @cognito_pool_id = 'cognito_pool_id'

      @cognito_credentials = instance_double(AwsmaRails::AwsCredentials)

      @aws_cognito_manager_mock = instance_double(AwsmaRails::AwsCognitoManager)
      allow(@aws_cognito_manager_mock).to receive(:generate_credentials).and_return(@cognito_credentials)

      allow(AwsmaRails::AwsCognitoManager).to receive(:new).and_return(@aws_cognito_manager_mock)
    end

    context 'no custom user agent was given' do
      it 'should create an AWS Cognito manager using the default user agent (Rails Server)' do
        expect(AwsmaRails::AwsCognitoManager).to receive(:new).with('Rails Server', @cognito_pool_id)

        AwsmaRails::Reporter.new(@awsma_endpoint_url, @awsma_app_id, @cognito_pool_id)
      end

      it 'should generate the cognito credentials' do
        expect(@aws_cognito_manager_mock).to receive(:generate_credentials).and_return(@cognito_credentials)

        AwsmaRails::Reporter.new(@awsma_endpoint_url, @awsma_app_id, @cognito_pool_id)
      end
    end

    context 'custom user agent was given' do
      before(:each) do
        @user_agent = 'custom_user_agent'
      end

      it 'should create an AWS Cognito manager using the default user agent (Rails Server)' do
        expect(AwsmaRails::AwsCognitoManager).to receive(:new).with(@user_agent, @cognito_pool_id)

        AwsmaRails::Reporter.new(@awsma_endpoint_url, @awsma_app_id, @cognito_pool_id, @user_agent)
      end

      it 'should generate the cognito credentials' do
        expect(@aws_cognito_manager_mock).to receive(:generate_credentials).and_return(@cognito_credentials)

        AwsmaRails::Reporter.new(@awsma_endpoint_url, @awsma_app_id, @cognito_pool_id)
      end
    end
  end

  describe '#report_event' do
    before(:each) do
      @awsma_endpoint_url = 'http://www.thumzap.com:3000/a/b/c'
      @awsma_app_id = 'awsma_app_id'
      @cognito_pool_id = 'cognito_pool_id'

      @cognito_credentials_1 = instance_double(AwsmaRails::AwsCredentials)
      @cognito_credentials_2 = instance_double(AwsmaRails::AwsCredentials)

      @aws_cognito_manager_mock = instance_double(AwsmaRails::AwsCognitoManager)

      @aws_cognito_credentials_counter = 0

      allow(@aws_cognito_manager_mock).to receive(:generate_credentials) do
        @aws_cognito_credentials_counter += 1

        if @aws_cognito_credentials_counter == 1
          @cognito_credentials_1
        else
          @cognito_credentials_2
        end
      end

      allow(AwsmaRails::AwsCognitoManager).to receive(:new).and_return(@aws_cognito_manager_mock)

      @current_time = Time.now
      allow(Time).to receive(:now).and_return(@current_time)

      @awsma_post_response_mock = double()
      allow(@awsma_post_response_mock).to receive(:code).and_return('200')

      @awsma_post_request_mock = instance_double(AwsmaRails::AwsmaPostRequest)
      allow(@awsma_post_request_mock).to receive(:send_request).and_return(@awsma_post_response_mock)
      allow(@awsma_post_request_mock).to receive(:refresh_credentials)
      allow(AwsmaRails::AwsmaPostRequest).to receive(:new).and_return(@awsma_post_request_mock)

      @awsma_reporter = AwsmaRails::Reporter.new(@awsma_endpoint_url, @awsma_app_id, @cognito_pool_id)

      @client_id = 'client_id'
      @session_id = 'session_id'
      @app_title = 'app_title'
      @app_package_name = 'app_package_name'
      @event_name = 'event_name'
    end

    shared_context 'test_common_logic' do
      it 'should create an AWS Mobile Analytics post request' do
        expected_analytics_data = {'events' => [{
                                                    'eventType' => @event_name,
                                                    'timestamp' => @current_time.utc.iso8601,
                                                    'version' => 'v2.0',
                                                    'session' => {'id' => @session_id,
                                                                  'startTimestamp' => @current_time.utc.iso8601},
                                                    'attributes' => @event_attributes,
                                                    'metrics' => @event_metrics
                                                }]}.to_json

        expected_aws_client_context = {
            'client' => {
                'client_id' => @client_id,
                'app_title' => @app_title,
                'app_package_name' => @app_package_name
            },
            'env' => {
                'platform' => 'linux',
                'model' => 'SERVER'
            },
            'services' => {
                'mobile_analytics' => {
                    'app_id' => @awsma_app_id,
                    'sdk_name' => 'awsma_rails',
                    'sdk_version' => AwsmaRails::VERSION
                }
            }
        }.to_json

        expect(AwsmaRails::AwsmaPostRequest).to receive(:new).with(@awsma_endpoint_url,
                                                                   expected_analytics_data,
                                                                   'Rails Server',
                                                                   expected_aws_client_context,
                                                                   @cognito_credentials_1).and_return(@awsma_post_request_mock)

        report_event
      end

      it 'should send the AWS Mobile Analytics post request' do
        expect(@awsma_post_request_mock).to receive(:send_request).and_return(@awsma_post_response_mock)

        report_event
      end

      it 'should return the AWS Mobile Analytics post response' do
        expect(report_event).to eq(@awsma_post_response_mock)
      end
    end

    shared_context 'test_main_logic' do
      context 'event was reported successfully' do
        include_context 'test_common_logic'
      end

      context 'event reporting failed due to invalid credentials' do
        before(:each) do
          allow(@awsma_post_response_mock).to receive(:code).and_return('403')

          invalid_credentials_response_body = {
              'message' => 'The security token included in the request is expired'
          }
          allow(@awsma_post_response_mock).to receive(:body).and_return(invalid_credentials_response_body.to_json)
        end

        include_context 'test_common_logic'

        it 'should generate new AWS Cognito credentials' do
          expect(@aws_cognito_manager_mock).to receive(:generate_credentials).and_return(@cognito_credentials_2)

          report_event
        end

        it 'should refresh the AWS Cognito credentials that were used in the AWS Mobile Analytics post request' do
          expect(@awsma_post_request_mock).to receive(:refresh_credentials).with(@cognito_credentials_2)

          report_event
        end

        it 'should send the AWS Mobile Analytics post request again with the refreshed credentials' do
          expect(@awsma_post_request_mock).to receive(:send_request).twice

          report_event
        end
      end
    end

    context 'no event attributes were given' do
      let(:report_event) {
        @awsma_reporter.report_event(@client_id,
                                     @session_id,
                                     @app_title,
                                     @app_package_name,
                                     @event_name)
      }

      before(:each) do
        @event_attributes = {}
        @event_metrics = {}
      end

      include_context 'test_main_logic'
    end

    context 'no event metrics were given' do
      before(:each) do
        @event_attributes = { :a => :b }
        @event_metrics = {}
      end

      let(:report_event) {
        @awsma_reporter.report_event(@client_id,
                                     @session_id,
                                     @app_title,
                                     @app_package_name,
                                     @event_name,
                                     @event_attributes)
      }

      include_context 'test_main_logic'
    end

    context 'event metrics were given' do
      before(:each) do
        @event_attributes = { :a => :b }
        @event_metrics = { :c => :d }
      end

      let(:report_event) {
        @awsma_reporter.report_event(@client_id,
                                     @session_id,
                                     @app_title,
                                     @app_package_name,
                                     @event_name,
                                     @event_attributes,
                                     @event_metrics)
      }

      include_context 'test_main_logic'
    end
  end
end
