require 'rest-client'
require 'json'

class BaiduNetDisk::Uploader
  SLICE_SIZE = 4 * 1024 * 1024

  class PermissionDenied < StandardError; end
  class SliceMissing < StandardError; end
  class FileExisted < StandardError; end
  class SpaceNotEnough < StandardError; end

  def initialize(source_path, target_path, options = {})
    @source_path = source_path
    @target_path = target_path
    @verbose = options[:verbose]
    @rtype = options[:overwrite] ? 3 : 1
    @file_size = File.size source_path
    @content_md5  = Digest::MD5.hexdigest(File.read(source_path))
    @upload_id = nil
    @block_list_md5 = [@content_md5]
    @is_dir = false
    @access_token = options[:access_token] || BaiduNetDisk.access_token
    @refresh_token = options[:refresh_token] || BaiduNetDisk.refresh_token
  end

  def execute
    pre_upload
    upload_by_slices
    create_file
  rescue PermissionDenied
    $stderr.print 'You are not authorised to upload files to your target path.'
    return false
  end

  private

  def pre_upload
    response = RestClient.post "https://pan.baidu.com/rest/2.0/xpan/file?method=precreate&access_token=#{@access_token}", {
      path: @target_path,
      size: @file_size,
      isdir: @is_dir,
      autoinit: 1,
      rtype: @rtype,
      block_list: @block_list_md5.to_json,
      :'content-md5' => @content_md5
    }, { 'User-Agent' => 'pan.baidu.com' }

    response_body = JSON.parse response.body

    $stdout.print response_body if @verbose

    if response_body['errno'].zero?
      @upload_id = response_body['uploadid']
    elsif response_body['errno'] == 3
      raise PermissionDenied
    else
      raise
    end
  end

  def upload_by_slices
    response = RestClient.post "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2?access_token=#{@access_token}&method=upload&type=tmpfile&path=#{@target_path}&uploadid=#{@upload_id}&partseq=0", { file: File.new(@source_path, 'rb') }

    $stdout.print response.body, "\n" if @verbose

    if response.code == 200
      $stdout.print 'slice uploaded' if @verbose
    else
      raise
    end
  end

  def create_file
    response = RestClient.post "https://pan.baidu.com/rest/2.0/xpan/file?method=create&access_token=#{@access_token}", {
      path: @target_path,
      size: @file_size,
      isdir: @is_dir,
      rtype: @rtype,
      uploadid: @upload_id,
      block_list: @block_list_md5.to_json
    }, { 'User-Agent' => 'pan.baidu.com' }
    response_body = JSON.parse response.body

    $stdout.print response_body, "\n" if @verbose

    if response_body['errno'].zero?
      $stdout.print 'File was successfully uploaded'
    else
      raise
    end
  end
end
