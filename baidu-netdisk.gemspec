Gem::Specification.new do |s|
  s.name        = 'baidu-netdisk'
  s.version     = BaiduNetDisk::VERSION
  s.summary     = 'A client to upload files to Baidu NetDisk'
  s.description = 'Ruby 版百度网盘文件上传客户端'
  s.authors     = ['Hegwin Wang']
  s.email       = 'hegwin@hegwin.me'
  s.files       = [
    'lib/baidu-netdisk.rb',
    'lib/baidu-netdisk/auth.rb',
    'lib/baidu-netdisk/exception.rb',
    'lib/baidu-netdisk/uploader.rb',
    'lib/baidu-netdisk/version.rb',
  ]
  s.homepage    = 'https://github/hegwin/baidu-netdisk'
  s.license     = 'MIT'
end
