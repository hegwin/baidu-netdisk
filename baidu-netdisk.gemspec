# frozen_string_literal: true

require_relative 'lib/baidu-netdisk/version'

Gem::Specification.new do |s|
  s.name        = 'baidu-netdisk'
  s.version     = BaiduNetDisk::VERSION
  s.homepage    = 'https://github/hegwin/baidu-netdisk'
  s.summary     = 'A client to upload files to Baidu NetDisk'
  s.description = 'Ruby 版百度网盘文件上传客户端'
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
  s.required_ruby_version = '>= 2.5.0'
  s.require_paths = ['lib']

  s.add_dependency 'rest-client'

  s.add_development_dependency 'codecov'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'vcr'
end
