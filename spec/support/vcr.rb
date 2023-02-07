require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = File.join(__dir__, '..', 'fixtures', 'vcr_cassettes')
  config.hook_into :webmock
  config.filter_sensitive_data('<APP_ID>') { ENV.fetch('APP_ID') }
  config.filter_sensitive_data('<APP_KEY>') { ENV.fetch('APP_KEY') }
  config.filter_sensitive_data('<SECRET_KEY>') { ENV.fetch('SECRET_KEY') }
  config.filter_sensitive_data('<ACCESS_TOKEN>') { ENV.fetch('ACCESS_TOKEN') }
  config.filter_sensitive_data('<REFRESH_TOKEN>') { ENV.fetch('REFRESH_TOKEN') }
end
