module BaiduNetDisk
  class << self
    attr_accessor :app_id, :app_key, :secret_key, :access_token, :refresh_token, :after_token_refreshed

    attr_writer :max_uploading_threads

    def config
      yield self
    end

    def max_uploading_threads
      @max_uploading_threads || 1
    end
  end

end

require 'baidu-netdisk/exception'
require 'baidu-netdisk/auth'
require 'baidu-netdisk/uploader'
