module BaiduNetDisk
  module Exception
    class PermissionDenied < StandardError; end
    class SliceMissing < StandardError; end
    class FileExisted < StandardError; end
    class SpaceNotEnough < StandardError; end
    class AuthenticationFailed < StandardError; end
    class AccessTokenExpired < StandardError; end
    class UnknownError < StandardError; end
    class UploadDirectoryNotSupported < StandardError; end

    MAPPING = {
      -10 => ::BaiduNetDisk::Exception::SpaceNotEnough,
      -7  => ::BaiduNetDisk::Exception::PermissionDenied,
      -6  => ::BaiduNetDisk::Exception::AuthenticationFailed,
      1   => ::BaiduNetDisk::Exception::UnknownError,
      3   => ::BaiduNetDisk::Exception::PermissionDenied,
      111 => ::BaiduNetDisk::Exception::AccessTokenExpired,
      31363 => ::BaiduNetDisk::Exception::SliceMissing
    }
  end
end
