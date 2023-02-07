# Baidu Netdisk

[![codecov](https://codecov.io/gh/hegwin/baidu-netdisk/branch/main/graph/badge.svg?token=HCUJ4QDMH6)](https://codecov.io/gh/hegwin/baidu-netdisk)

## Configuration

```ruby
BaiduNetDisk.config do |c|
  c.app_id     = 'your_app_id'
  c.app_key    = 'your_app_key'
  c.secret_key = 'your_secret_key'

  # Max threads for uploading file slices, default to 1
  c.max_threads = 4

  # The following two are optional;
  # Fill them in if you want to explicitly indicate uploading to someone else's storage space
  c.access_token  = 'your_access_token'
  c.refresh_token = 'your_refresh_token'
end
```

## Todo

1. File uploader
2. Unit Tests
3. Documentations
