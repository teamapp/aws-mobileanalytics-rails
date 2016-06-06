require 'spec_helper'

describe AwsmaRails::AwsPostRequest do
  describe '#new' do
    before(:each) do
      @host = 'host.com'

      @port = 1234

      @request_uri = '/a/b/c/d'

      @body = { :a => :b }.to_json
      @user_agent = 'user_agent'

      @http_client_mock = instance_double(Net::HTTP)
      allow(@http_client_mock).to receive(:use_ssl=)

      allow(Net::HTTP).to receive(:new).and_return(@http_client_mock)

      @request_mock = instance_double(Net::HTTP::Post)
      allow(@request_mock).to receive(:[]=)
      allow(@request_mock).to receive(:body=)
      allow(Net::HTTP::Post).to receive(:new).and_return(@request_mock)
    end

    shared_context 'common_logic' do
      context 'common' do
        it 'should create an HTTP client with the endpoint host and port' do
          expect(Net::HTTP).to receive(:new).with(@host, @port).and_return(@http_client_mock)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
        end

        it 'should set the HTTP client SSL setting according to the given endpoint URL scheme' do
          expect(@http_client_mock).to receive(:use_ssl=).with(@scheme == 'https')

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
        end

        it 'should create an HTTP post request' do
          expect(Net::HTTP::Post).to receive(:new).with(@request_uri).and_return(@request_mock)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
        end

        it 'should set the HTTP request user agent' do
          expect(@request_mock).to receive(:[]=).with('User-Agent', @user_agent)
          
          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
        end

         it 'should set the HTTP request content type' do
           expect(@request_mock).to receive(:[]=).with('Content-Type', 'application/x-amz-json-1.0')

           AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
         end
      end

      context 'custom AWS target was given' do
        before(:each) do
          @custom_aws_target = 'custom_aws_target'
        end

        it 'should set the target in the request header' do
          expect(@request_mock).to receive(:[]=).with('X-Amz-Target', @custom_aws_target)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent, @custom_aws_target)
        end
      end

      context 'custom AWS target was not given' do
        it 'should not set the target in the request header' do
          expect(@request_mock).to_not receive(:[]=).with('X-Amz-Target', anything)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
        end
      end

      context 'custom AWS client context was given' do
        before(:each) do
          @custom_aws_client_context = 'custom_aws_client_context'
        end

        it 'should set the client the context in the request header' do
          expect(@request_mock).to receive(:[]=).with('x-amz-Client-Context', @custom_aws_client_context)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent, nil, @custom_aws_client_context)
        end
      end

      context 'custom AWS client context was not given' do
        it 'should not set the client the context in the request header' do
          expect(@request_mock).to_not receive(:[]=).with('x-amz-Client-Context', anything)

          AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent, nil, nil)
        end
      end
    end

    context 'HTTPS URL' do
      before(:each) do
        @scheme = 'https'

        @endpoint_url = "#{@scheme}://#{@host}:#{@port}#{@request_uri}"
      end

      include_context 'common_logic'
    end

    context 'HTTP URL' do
      before(:each) do
        @scheme = 'http'

        @endpoint_url = "#{@scheme}://#{@host}:#{@port}#{@request_uri}"
      end

      include_context 'common_logic'
    end
  end

  describe '#send_request' do
    before(:each) do
      @http_client_mock = instance_double(Net::HTTP)
      allow(@http_client_mock).to receive(:use_ssl=)
      allow(@http_client_mock).to receive(:request)
      allow(Net::HTTP).to receive(:new).and_return(@http_client_mock)

      @request_mock = instance_double(Net::HTTP::Post)
      allow(@request_mock).to receive(:[]=)
      allow(@request_mock).to receive(:body=)
      allow(Net::HTTP::Post).to receive(:new).and_return(@request_mock)

      @endpoint_url = 'http://www.thumzap.com:3000/a/b/c/d'
      @body = {}
      @user_agent = 'user_agent'

      @aws_post_request = AwsmaRails::AwsPostRequest.new(@endpoint_url, @body, @user_agent)
    end

    it 'should send the generated request using the internal HTTP client' do
      expect(@http_client_mock).to receive(:request).with(@request_mock)

      @aws_post_request.send_request
    end
  end
end
