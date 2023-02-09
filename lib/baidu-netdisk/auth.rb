require 'rest-client'
require 'json'

class BaiduNetDisk::Auth
  class << self
    def get_auth_code(redirect_uri = 'oob')
      check_required_configs

      url = "https://openapi.baidu.com/oauth/2.0/authorize?response_type=code&client_id=#{BaiduNetDisk.app_key}&redirect_uri=#{redirect_uri}&scope=basic,netdisk&device_id=#{BaiduNetDisk.app_id}"

      if redirect_uri == 'oob'
        system("open \"#{url}\"")
      else
        RestClient.get url
      end
    end

    def get_token(auth_code, redirect_uri = 'oob')
      response = RestClient.get "https://openapi.baidu.com/oauth/2.0/token?grant_type=authorization_code&code=#{auth_code}&client_id=#{BaiduNetDisk.app_key}&client_secret=#{BaiduNetDisk.secret_key}&redirect_uri=#{redirect_uri}"

      response_body = JSON.parse response.body
    end

    def refresh_access_token(refresh_token)
      response = RestClient.get "https://openapi.baidu.com/oauth/2.0/token?grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{BaiduNetDisk.app_key}&client_secret=#{BaiduNetDisk.secret_key}"

      response_body = JSON.parse response.body

      access_token, refresh_token = response_body.fetch_values('access_token', 'refresh_token')

      if BaiduNetDisk.after_token_refreshed&.respond_to? :call
        BaiduNetDisk.after_token_refreshed.call(access_token, refresh_token)
      end

      [access_token, refresh_token]
    rescue RestClient::BadRequest
      $stdout.puts "Refresh token failed."
      raise BaiduNetDisk::Exception::RefreshTokenFailed
    end

    private

    def check_required_configs
      while BaiduNetDisk.app_key.nil? || BaiduNetDisk.app_key.strip.empty?
        $stdout.print "Please enter your App Key:\n"
        BaiduNetDisk.app_key = $stdin.gets.chomp
      end

      while BaiduNetDisk.app_id.nil? || BaiduNetDisk.app_id.strip.empty?
        $stdout.print "Please enter your App ID:\n"
        BaiduNetDisk.app_id = $stdin.gets.chomp
      end

      while BaiduNetDisk.secret_key.nil? || BaiduNetDisk.secret_key.strip.empty?
        $stdout.print "Please enter your Secret Key:\n"
        BaiduNetDisk.secret_key = $stdin.gets.chomp
      end
    end
  end
end
