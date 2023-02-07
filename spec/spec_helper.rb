require 'dotenv/load'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec/'
  add_filter 'git'
  add_filter do |source_file|
    source_file.lines.count < 5
  end
end

require 'baidu-netdisk'

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

BaiduNetDisk.config do |c|
  c.app_id        = ENV['APP_ID']
  c.app_key       = ENV['APP_KEY']
  c.secret_key    = ENV['SECRET_KEY']
  c.access_token  = ENV['ACCESS_TOKEN']
  c.refresh_token = ENV['REFRESH_TOKEN']
end
