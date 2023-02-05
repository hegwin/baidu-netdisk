module BaiduNetDisk
  module Exception
    class PermissionDenied < StandardError; end
    class SliceMissing < StandardError; end
    class FileExisted < StandardError; end
    class SpaceNotEnough < StandardError; end
  end
end
