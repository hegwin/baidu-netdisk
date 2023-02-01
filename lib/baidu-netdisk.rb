module BaiduNetDisk
  class << self
    attr_accessor :app_id, :app_key, :secret_key, :access_token, :refresh_token

    def config
      yield self
    end
  end

end

require 'baidu-netdisk/uploader'
