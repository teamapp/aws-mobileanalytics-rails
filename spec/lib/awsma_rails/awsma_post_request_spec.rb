require 'spec_helper'

describe AwsmaRails::AwsmaPostRequest do
  describe '#new' do
    before(:each) do
      @host = 'host.com'

      @port = 1234

      @request_uri = '/a/b/c/d'

      @analytics_data = { :a => :b }.to_json
      @user_agent = 'user_agent'
      @aws_client_context = { :c => :d }.to_json
      @cognito_credentials = double()

      @http_client_mock = instance_double(Net::HTTP)
      allow(@http_client_mock).to receive(:use_ssl=)

      allow(Net::HTTP).to receive(:new).and_return(@http_client_mock)

      @http_post_request_mock = instance_double(Net::HTTP::Post)
      allow(@http_post_request_mock).to receive(:[]=)
      allow(@http_post_request_mock).to receive(:body=)
      allow(Net::HTTP::Post).to receive(:new).and_return(@http_post_request_mock)
    end

    shared_context 'common_logic' do
      context 'common' do
        it 'should create an HTTP client with the endpoint host and port' do
          expect(Net::HTTP).to receive(:new).with(@host, @port).and_return(@http_client_mock)

          AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
        end

        it 'should set the HTTP client SSL setting according to the given endpoint URL scheme' do
          expect(@http_client_mock).to receive(:use_ssl=).with(@scheme == 'https')

          AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
        end

        it 'should create an HTTP post request' do
          expect(Net::HTTP::Post).to receive(:new).with(@request_uri).and_return(@http_post_request_mock)

          AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
        end

        it 'should set the HTTP request user agent' do
          expect(@http_post_request_mock).to receive(:[]=).with('User-Agent', @user_agent)

          AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
        end

         it 'should set the HTTP request content type' do
           expect(@http_post_request_mock).to receive(:[]=).with('Content-Type', 'application/x-amz-json-1.0')

           AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
         end

        it 'should set the client the context in the request header' do
          expect(@http_post_request_mock).to receive(:[]=).with('x-amz-Client-Context', @aws_client_context)

          AwsmaRails::AwsmaPostRequest.new(@endpoint_url, @analytics_data, @user_agent, @aws_client_context, @cognito_credentials)
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

      @http_post_request_mock = instance_double(Net::HTTP::Post)
      allow(@http_post_request_mock).to receive(:[]=)
      allow(@http_post_request_mock).to receive(:body=)
      allow(Net::HTTP::Post).to receive(:new).and_return(@http_post_request_mock)

      @endpoint_url = 'http://www.thumzap.com:3000/a/b/c/d'
      @analytics_data = { :a => :b }.to_json
      @user_agent = 'user_agent'
      @aws_client_context = { :c => :d }.to_json
      @cognito_credentials = double()

      @awsma_post_request = AwsmaRails::AwsmaPostRequest.new(@endpoint_url,
                                                           @analytics_data,
                                                           @user_agent,
                                                           @aws_client_context,
                                                           @cognito_credentials)

      @aws_signed_request_mock = double()
      @aws_signed_request_v4_mock = instance_double(AwsmaRails::AwsSignedRequestV4)
      allow(@aws_signed_request_v4_mock).to receive(:sign).and_return(@aws_signed_request_mock)
      allow(AwsmaRails::AwsSignedRequestV4).to receive(:new).and_return(@aws_signed_request_v4_mock)
    end

    shared_context 'common_logic' do
      it 'should send the signed request using the HTTP client' do
        expect(@http_client_mock).to receive(:request).with(@aws_signed_request_mock)

        @awsma_post_request.send_request
      end
    end

    context 'request was not signed' do
      it 'should sign the request' do
        expect(AwsmaRails::AwsSignedRequestV4).to receive(:new).with(@cognito_credentials,
                                                                     'mobileanalytics',
                                                                     'us-east-1',
                                                                     URI.parse(@endpoint_url)).and_return(@aws_signed_request_v4_mock)

        expect(@aws_signed_request_v4_mock).to receive(:sign).with(@http_post_request_mock).and_return(@aws_signed_request_mock)

        @awsma_post_request.send_request
      end

      include_context 'common_logic'
    end

    context 'request was already signed' do
      before(:each) do
        @awsma_post_request.send_request
      end

      it 'should not sign the request again' do
        expect(AwsmaRails::AwsSignedRequestV4).to_not receive(:new)
        expect(@aws_signed_request_v4_mock).to_not receive(:sign)

        @awsma_post_request.send_request
      end

      include_context 'common_logic'
    end
  end

  describe '#refresh_credentials' do
    before(:each) do
      @http_client_mock = instance_double(Net::HTTP)
      allow(@http_client_mock).to receive(:use_ssl=)
      allow(@http_client_mock).to receive(:request)
      allow(Net::HTTP).to receive(:new).and_return(@http_client_mock)

      @http_post_request_mock = instance_double(Net::HTTP::Post)
      allow(@http_post_request_mock).to receive(:[]=)
      allow(@http_post_request_mock).to receive(:body=)
      allow(Net::HTTP::Post).to receive(:new).and_return(@http_post_request_mock)

      @endpoint_url = 'http://www.thumzap.com:3000/a/b/c/d'
      @analytics_data = { :a => :b }.to_json
      @user_agent = 'user_agent'
      @aws_client_context = { :c => :d }.to_json
      @cognito_credentials = double()

      @awsma_post_request = AwsmaRails::AwsmaPostRequest.new(@endpoint_url,
                                                             @analytics_data,
                                                             @user_agent,
                                                             @aws_client_context,
                                                             @cognito_credentials)

      @new_cognito_crendentials = double()
    end

    it 'should set the new credentials' do
      expect(@awsma_post_request.instance_variable_get(:@cognito_credentials)).to eq(@cognito_credentials)

      @awsma_post_request.refresh_credentials(@new_cognito_crendentials)

      expect(@awsma_post_request.instance_variable_get(:@cognito_credentials)).to eq(@new_cognito_crendentials)
    end

    it 'should set the signed AWS request to nil' do
      @awsma_post_request.instance_variable_set(:@aws_signed_request, double())

      @awsma_post_request.refresh_credentials(@new_cognito_crendentials)

      expect(@awsma_post_request.instance_variable_get(:@aws_signed_request)).to be_nil
    end
  end
end
