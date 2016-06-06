require 'spec_helper'

describe AwsmaRails::AwsCognitoManager do
  before(:each) do
    @user_agent = 'user_agent'
    @cognito_pool_id = 'cognito_pool_id'
  end

  describe '#generate_credentials' do
    before(:each) do
      @aws_cognito_manager = AwsmaRails::AwsCognitoManager.new(@user_agent, @cognito_pool_id)

      @cognito_id = 'cognito_id'

      @cognito_get_id_response_body = {
          'IdentityId' => 'cognito_id'
      }

      @cognito_get_id_response_mock = double()
      allow(@cognito_get_id_response_mock).to receive(:body).and_return(@cognito_get_id_response_body.to_json)

      @cognito_get_id_request_mock = double(AwsmaRails::AwsPostRequest)
      allow(@cognito_get_id_request_mock).to receive(:send_request).and_return(@cognito_get_id_response_mock)

      @cognito_get_credentials_response_body = {
          'Credentials' => {
              'AccessKeyId' => 'access_key_id',
              'SecretKey' => 'secret_key',
              'SessionToken' => 'session_token'
          }
      }

      @cognito_get_credentials_response_mock = double()
      allow(@cognito_get_credentials_response_mock).to receive(:body).and_return(@cognito_get_credentials_response_body.to_json)

      @cognito_get_credentials_request_mock = double(AwsmaRails::AwsPostRequest)
      allow(@cognito_get_credentials_request_mock).to receive(:send_request).and_return(@cognito_get_credentials_response_mock)

      allow(AwsmaRails::AwsPostRequest).to receive(:new).with('https://cognito-identity.us-east-1.amazonaws.com',
                                                              instance_of(String),
                                                              @user_agent,
                                                              'AWSCognitoIdentityService.GetId').and_return(@cognito_get_id_request_mock)

      allow(AwsmaRails::AwsPostRequest).to receive(:new).with('https://cognito-identity.us-east-1.amazonaws.com',
                                                              instance_of(String),
                                                              @user_agent,
                                                              'AWSCognitoIdentityService.GetCredentialsForIdentity').and_return(@cognito_get_credentials_request_mock)

      @aws_credentials_mock = instance_double(AwsmaRails::AwsCredentials)
      allow(AwsmaRails::AwsCredentials).to receive(:new).and_return(@aws_credentials_mock)
    end

    it 'should get an AWS Cognito ID' do
      expected_body = {
          'IdentityPoolId' => @cognito_pool_id,
          'Logins' => {}
      }.to_json

      expect(AwsmaRails::AwsPostRequest).to receive(:new).with('https://cognito-identity.us-east-1.amazonaws.com',
                                                               expected_body,
                                                               @user_agent,
                                                               'AWSCognitoIdentityService.GetId').and_return(@cognito_get_id_request_mock)

      @aws_cognito_manager.generate_credentials
    end

     it 'should create an AWS Cognito credentials for the returned ID' do
       expected_body = {
           'IdentityId' => @cognito_get_id_response_body['IdentityId'],
           'Logins' => {}
       }.to_json

       expect(AwsmaRails::AwsPostRequest).to receive(:new).with('https://cognito-identity.us-east-1.amazonaws.com',
                                                                expected_body,
                                                                @user_agent,
                                                                'AWSCognitoIdentityService.GetCredentialsForIdentity').and_return(@cognito_get_credentials_request_mock)

       @aws_cognito_manager.generate_credentials
     end

    it 'should create an AWS Credentials using the AWS Cognito credential creation response' do
      expect(AwsmaRails::AwsCredentials).to receive(:new).with(@cognito_get_credentials_response_body['Credentials']['AccessKeyId'],
                                                               @cognito_get_credentials_response_body['Credentials']['SecretKey'],
                                                               @cognito_get_credentials_response_body['Credentials']['SessionToken']).and_return(@aws_credentials_mock)

      @aws_cognito_manager.generate_credentials
    end

    it 'should return the created credentials' do
      expect(@aws_cognito_manager.generate_credentials).to eq(@aws_credentials_mock)
    end
  end
end
