# Baidu Netdisk

[![CI](https://github.com/hegwin/baidu-netdisk/actions/workflows/test.yml/badge.svg)](https://github.com/hegwin/baidu-netdisk/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/hegwin/baidu-netdisk/branch/main/graph/badge.svg?token=HCUJ4QDMH6)](https://codecov.io/gh/hegwin/baidu-netdisk)
[![Maintainability](https://api.codeclimate.com/v1/badges/75bf545e0efd8f0b24e1/maintainability)](https://codeclimate.com/github/hegwin/baidu-netdisk/maintainability)

A Ruby client to upload files to Baidu NetDisk (PCS). It'll auto-split big files and upload slices parallelly.


## Installation

Install with bundler:

```
bundle add baidu-netdisk
```

Or install with ruby gem

```
gem install baidu-netdisk
```

## Configuration

```ruby
BaiduNetDisk.config do |c|
  # Required configs
  c.app_id     = 'your_app_id'
  c.app_key    = 'your_app_key'
  c.secret_key = 'your_secret_key'

  # Max threads for uploading file slices, default to 1
  c.max_uploading_threads = 4

  # The following two are optional;
  # Fill them in if you want to explicitly indicate uploading to someone else's storage space
  c.access_token  = 'your_access_token'
  c.refresh_token = 'your_refresh_token'
end
```

## Usage

This client is designed for the two following scenarios.

### Scenario 1: Using Baidu NetDisk as a backup file storage

You always save files to your net disk storage. You don't need a callback to receive auth codes or tokens from Baidu; Instead, you can just get them from your Ruby console.

```ruby
require 'baidu-netdisk'

# It opens a browser to ask for access to Baidu OAuth;
# you will get your auth code after you log in to your Baidu NetDisk
BaiduNetDisk::Auth.get_auth_code

# Pass the code as the argument your received from the previous step
BaiduNetDisk::Auth.get_token(auth_code)

uploader = BaiduNetDisk::Uploader.new(source_path, target_path)
uploader.execute

#  => {"category"=>6, "ctime"=>1676019860, "from_type"=>1, "fs_id"=>121127634951625, "isdir"=>0, "md5"=>"79835de6btc0b3482f51b49088c8ccfb", "mtime"=>1676019860, "path"=>"<target_path>", "server_filename"=>"<file_name>", "size"=>76267, "errno"=>0, "name"=>"<target_path>"} 
```

### Scenario 2: Upload files to your clients' Baidu NetDisk 

You should have a web server and need to implement your webhook to receive a callback from Baidu NetDisk after auth.

Say your callback URL is `https://www.example.com/webhook`, you should have the:

```ruby
BaiduNetDisk::Auth.get_auth_code('https://www.example.com/webhook')


# Auth code is fetched in your callbacks
BaiduNetDisk::Auth.get_token(auth_code, 'https://www.example.com/webhook')

uploader = BaiduNetDisk::Uploader.new(source_path, target_path,
  { access_token: 'client.access_token', refresh_token: 'client.refresh_token' })

uploader.execute
```

It provides a hook after token refreshed so you can save tokens after refreshing.

```ruby
BaiduNetDisk.config do |c|
  c.after_token_refreshed = -> (access_token, refresh_token) {
    user.update access_token: access_token, refresh_token: refresh_token
  }
end
```

## Development

### Copy the env file

It reads ENV from .env for testing.

```
cp .env.example .env
```

### Run tests

```
bundle install
bundle exec rake
```

### Todo

1. Improve MAINTAINABILITY

2. To use other HTTP clients instead of RestClient:

  1. RestClient can't catch response body when response is `400 BadRequest`.

  2. Currently, we implemented multi-threaded uploading by hands. Consider to use typhoeus with its native hydra to run HTTP requests in parallel.
