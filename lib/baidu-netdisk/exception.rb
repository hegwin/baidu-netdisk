module BaiduNetDisk
  module Exception
    # Exceptions following Baidu error codes
    # https://openauth.baidu.com/doc/appendix.html#_4-openapi%E9%94%99%E8%AF%AF%E7%A0%81%E5%88%97%E8%A1%A8
    class PermissionDenied < StandardError; end
    class SliceMissing < StandardError; end
    class FileExisted < StandardError; end
    class SpaceNotEnough < StandardError; end
    class AuthenticationFailed < StandardError; end
    class TooManyRequests < StandardError; end
    class AccessTokenExpired < StandardError; end
    class UnknownError < StandardError; end
    class ArgumentError < StandardError; end
    class UserAuthorizationRequired < StandardError; end

    # Custom exception
    class UploadDirectoryNotSupported < StandardError; end
    class RefreshTokenNotProvided < StandardError; end
    class RefreshTokenFailed < StandardError; end

    MAPPING = {
      -10 => SpaceNotEnough,
      -8  => FileExisted,
      -7  => PermissionDenied,
      -6  => AuthenticationFailed,
      1   => UnknownError,
      2   => ArgumentError,
      3   => PermissionDenied,
      6   => UserAuthorizationRequired,
      111 => AccessTokenExpired,
      31034 => TooManyRequests,
      31363 => SliceMissing
    }
  end
end
