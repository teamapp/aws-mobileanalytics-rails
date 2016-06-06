require 'json'

module AwsmaRails
  class AwsCognitoManager
    def initialize(user_agent, cognito_pool_id)
      @user_agent = user_agent
      @cognito_pool_id = cognito_pool_id
    end

    # @return [AwsmaRails::AwsCredentials] The newly generated AWS Cognito credentials
    def generate_credentials
      get_id_response =
          send_cognito_request('AWSCognitoIdentityService.GetId',
                               {
                                   'IdentityPoolId' => @cognito_pool_id,
                                   'Logins' => {}
                               }.to_json)

      identity_id = JSON.parse(get_id_response.body)['IdentityId']

      get_credentials_response = send_cognito_request('AWSCognitoIdentityService.GetCredentialsForIdentity',
                                                      {
                                                          'IdentityId' => identity_id,
                                                          'Logins' => {}
                                                      }.to_json)

      parsed_credentials = JSON.parse(get_credentials_response.body)['Credentials']

      AwsCredentials.new(parsed_credentials['AccessKeyId'],
                         parsed_credentials['SecretKey'],
                         parsed_credentials['SessionToken'])
    end

    private

    def send_cognito_request(target, body)
      aws_request = AwsPostRequest.new('https://cognito-identity.us-east-1.amazonaws.com',
                                       body,
                                       @user_agent,
                                       target)

      aws_request.send_request
    end
  end
end
