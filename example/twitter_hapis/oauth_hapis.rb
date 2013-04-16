require 'base64'

TwitterKeys = YAML.load_file('example/twitter_hapis/oauth.yml')

def application_authenticate
  params = { 'grant_type' => 'client_credentials' }
  token = TwitterKeys['consumer_key'] + ':' + TwitterKeys['consumer_secret']
  encoded_token = Base64.strict_encode64(token)
  response = twitter.post_form '/oauth2/token', params,
   base_uri: '',
   additional_headers: {
     'Authorization' => "Basic " + encoded_token,
     'Accept' => '*/*',  # I think this is a bug that I have to set it to this:  https://dev.twitter.com/discussions/16348#comment-36465
   }
   twitter.headers['Authorization'] = "Bearer #{response['access_token']}"
   true
end

def authenticate
  application_authenticate
end
