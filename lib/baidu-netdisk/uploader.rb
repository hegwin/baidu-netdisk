require 'rest-client'
require 'json'

class BaiduNetDisk::Uploader
  SLICE_SIZE = 4 * 1024 * 1024

  def initialize(source_path, target_path, options = {})
    @is_dir = File.directory?(source_path) ? true : false
    raise BaiduNetDisk::Exception::UploadDirectoryNotSupported, 'Uploading directory is not supported at present.' if @is_dir

    @source_path = source_path
    @target_path = target_path

    @verbose = options[:verbose]
    @slice_prefix = ".tmp_#{Random.hex(6)}_"

    @rtype = options[:overwrite] ? 3 : 1
    @file_size = File.size @source_path
    @content_md5  = Digest::MD5.hexdigest(File.read @source_path)
    @upload_id = nil
    @slices = []
    @refresh_token = options[:refresh_token] || BaiduNetDisk.refresh_token
    @access_token = options[:access_token] || BaiduNetDisk.access_token
  end

  def execute
    prepare
    pre_upload
    upload_by_slices
    create_file
  rescue BaiduNetDisk::Exception::PermissionDenied
    $stderr.puts 'You are not authorised to upload files to your target path.'
    return false
  rescue BaiduNetDisk::Exception::AuthenticationFailed, BaiduNetDisk::Exception::AccessTokenExpired => e
    raise e if @tried_refresh_token
    retry if refresh_token!
  ensure
    clear_up
  end

  private

  def prepare
    return if @slices.any?

    if @file_size > SLICE_SIZE
      $stdout.puts 'Splitting file into slices...' if @verbose

      `split -b #{SLICE_SIZE} "#{@source_path}" #{@slice_prefix}`

      Dir["#{Dir.getwd}/#{@slice_prefix}*"].sort.each do |slice_file_path|
        @slices << {
          md5: Digest::MD5.hexdigest(File.read slice_file_path),
          slice_file_path: slice_file_path,
          block_id: nil
        }
      end

      $stdout.puts "Split file into #{@slices.size} slices. Done." if @verbose
    else
      $stdout.puts 'File size is smaller than 4MB, no split.' if @verbose

      @slices << { md5: @content_md5, slice_file_path: @source_path, block_id: 0}
    end
  end

  # API doc in Baidu:
  # https://pan.baidu.com/union/doc/3ksg0s9r7
  def pre_upload
    response = RestClient.post "https://pan.baidu.com/rest/2.0/xpan/file?method=precreate&access_token=#{@access_token}", {
      path: @target_path,
        size: @file_size,
        isdir: @is_dir,
        autoinit: 1,
        rtype: @rtype,
        block_list: @slices.map { |slice| slice[:md5] }.to_json,
        :'content-md5' => @content_md5
    }, { 'User-Agent' => 'pan.baidu.com' }

    response_body = JSON.parse response.body

    if response_body['errno'].zero?
      @upload_id = response_body['uploadid']
      $stdout.print "Got upload ID #{@upload_id}\n" if @verbose

      response_body['block_list'].each.with_index do |block_id, index|
        @slices[index][:block_id] = block_id
      end
    else
      raise BaiduNetDisk::Exception::MAPPING[response_body['errno']] || StandardError
    end
  end

  # API doc in Baidu:
  # https://pan.baidu.com/union/doc/nksg0s9vi
  def upload_by_slices
    queue = @slices.dup

    # TODO Consider `typhoeus` rather than invoking multiple threads manually
    BaiduNetDisk.max_uploading_threads.times.map do
      Thread.new do
        while queue.length > 0
          slice = queue.pop
          if slice
            upload_slice_file(slice[:slice_file_path], slice[:block_id])
          end
        end
      end
    end.each(&:join)

    $stdout.puts 'Slices upload complete.' if @verbose
  end

  def upload_slice_file(slice_file_path, block_id = 0)
    response = RestClient.post "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2?access_token=#{@access_token}&method=upload&type=tmpfile&path=#{@target_path}&uploadid=#{@upload_id}&partseq=#{block_id}", { file: File.new(slice_file_path, 'rb') }

    $stdout.puts "Slice ##{block_id} uploaded!" if @verbose

    response
  end

  # API doc in Baidu:
  # https://pan.baidu.com/union/doc/rksg0sa17
  def create_file
    response = RestClient.post "https://pan.baidu.com/rest/2.0/xpan/file?method=create&access_token=#{@access_token}", {
      path: @target_path,
        size: @file_size,
        isdir: @is_dir,
        rtype: @rtype,
        uploadid: @upload_id,
        block_list: @slices.map { |slice| slice[:md5] }.to_json
    }, { 'User-Agent' => 'pan.baidu.com' }

    response_body = JSON.parse response.body

    if response_body['errno'].zero?
      $stdout.puts "File was successfully created at #{Time.at(response_body['ctime'])}!"
      response_body
    else
      raise BaiduNetDisk::Exception::MAPPING[response_body['errno']] || StandardError, response.body
    end
  end

  def clear_up
    return if @slices.length < 2

    $stdout.puts 'Cleaning tmp slice files...' if @verbose
    @slices.each do |slice|
      File.delete(slice[:slice_file_path]) if File.exist?(slice[:slice_file_path])
    end
    $stdout.puts 'Cleaning tmp slice files. Done.' if @verbose
  end

  def refresh_token!
    @tried_refresh_token = true

    if @refresh_token
      $stdout.puts 'Access token expired. Trying to refresh...' if @verbose
      @access_token, @refresh_token = BaiduNetDisk::Auth.refresh_access_token(@refresh_token)
      $stdout.puts 'Access token refreshed!' if @verbose

      true
    else
      raise BaiduNetDisk::Exception::RefreshTokenNotProvided, 'Access token expired. Please provide a refresh token.'
    end
  end
end
