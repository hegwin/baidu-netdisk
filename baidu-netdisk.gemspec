# frozen_string_literal: true

require_relative 'lib/baidu-netdisk/version'

Gem::Specification.new do |s|
  s.name        = 'baidu-netdisk'
  s.version     = BaiduNetDisk::VERSION
  s.homepage    = 'https://github.com/hegwin/baidu-netdisk'
  s.summary     = 'A client to upload files to Baidu NetDisk'
  s.description = '百度网盘文件上传客户端Ruby版'
  s.authors     = ['Hegwin Wang']
  s.email       = ['zwt315@163.com','hegwin@hegwin.me']

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  s.license     = 'MIT'

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.6.0'
  s.require_paths = ['lib']

  s.add_dependency 'rest-client', '~> 2.1.0'

  s.add_development_dependency 'codecov', '~> 0.6.0'
  s.add_development_dependency 'dotenv', '~> 2.8.1'
  s.add_development_dependency 'pry', '~> 0.14.2'
  s.add_development_dependency 'rake', '~> 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.12.0'
  s.add_development_dependency 'simplecov', '~> 0.21.2'
  s.add_development_dependency 'vcr', '~> 6.1.0'
  s.add_development_dependency 'webmock', '~> 3.18.1'
end
