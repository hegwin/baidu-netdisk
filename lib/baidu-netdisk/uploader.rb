class BaiduNetDisk::Uploader
  SLICE_SIZE = 4 * 1024 * 1024

  class PermissionDenied < StandardError; end
  class SliceMissing < StandardError; end
  class FileExisted < StandardError; end
  class SpaceNotEnough < StandardError; end

  def initialize(source_path, target_path, options = {})
    @source_path = source_path
    @target_path = target_path
    @rtype = options[:overwrite] ? 3 : 1
    @file_size = 0
    @file_md5  = ''
    @upload_id = nil
    @block_list_md5 = []
    @is_dir = false
  end

  def execute
    pre_upload
    upload_by_slices
    create_file
  rescue PermissionDenied
    puts 'You are not authorised to upload files to your target path.'
    return false
  end

  private

  def pre_upload

  end

  def upload_by_slices

  end

  def create_file

  end
end
