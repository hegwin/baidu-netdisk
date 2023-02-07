require 'rest-client'
require 'json'

class BaiduNetDisk::Uploader
  SLICE_SIZE = 4 * 1024 * 1024
  DEFAULT_MAX_THREADS = 1

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
    $stderr.print 'You are not authorised to upload files to your target path.'
    return false
  rescue BaiduNetDisk::Exception::AuthenticationFailed, BaiduNetDisk::Exception::AccessTokenExpired => e
    raise e if @tried_refresh_token

    if @refresh_token
      $stdout.print "Access token expired. Trying to refresh...\n"
      @tried_refresh_token = true
      begin
        @access_token = BaiduNetDisk::Auth.refresh_access_token(@refresh_token)['access_token']
        $stdout.puts "Access token refreshed!"
        retry
      rescue => e
        $stderr.print "Failed to refresh access token.\n"
        raise e
      end

    else
      $stderr.print "Token expired. Please provide a refresh token.\n"
      raise e
    end
  ensure
    clear_up
  end

  private

  def prepare
    return if @slices.any?

    if @file_size > SLICE_SIZE
      $stdout.print "Splitting file into slices...\n" if @verbose

      `split -b #{SLICE_SIZE} "#{@source_path}" #{@slice_prefix}`

      Dir["#{Dir.getwd}/#{@slice_prefix}*"].sort.each do |slice_file_path|
        @slices << {
          md5: Digest::MD5.hexdigest(File.read slice_file_path),
          slice_file_path: slice_file_path,
          block_id: nil
        }
      end

      $stdout.print "Split file into #{@slices.size} slices. Done.\n" if @verbose
    else
      $stdout.print "File size is smaller than 4MB, no split.\n" if @verbose

      @slices << { md5: @content_md5, slice_file_path: @source_path, block_id: 0}
    end
  end

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
    elsif BaiduNetDisk::Exception::MAPPING[response_body['errno']]
      raise BaiduNetDisk::Exception::MAPPING[response_body['errno']]
    else
      raise StandardError, response.body
    end
  end

  def upload_by_slices
    queue = @slices.dup

    (BaiduNetDisk.max_threads || DEFAULT_MAX_THREADS).times.map do
      Thread.new do
        while queue.length > 0
          slice = queue.pop
          if slice
            response = RestClient.post "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2?access_token=#{@access_token}&method=upload&type=tmpfile&path=#{@target_path}&uploadid=#{@upload_id}&partseq=#{slice[:block_id]}", { file: File.new(slice[:slice_file_path], 'rb') }

            if response.code == 200
              $stdout.print "Slice ##{slice[:block_id]} uploaded!\n" if @verbose
            else
              raise
            end
          end
        end
      end
    end.each(&:join)

    $stdout.print "Slices upload complete.\n" if @verbose
  end

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
      $stdout.print "File was successfully created at #{Time.at(response_body['ctime'])}!\n"
      response_body
    else
      raise
    end
  end

  def clear_up
    return if @slices.length < 2

    $stdout.print "Cleaning tmp slice files...\n" if @verbose
    @slices.each do |slice|
      File.delete(slice[:slice_file_path]) if File.exist?(slice[:slice_file_path])
    end
    $stdout.print "Cleaning tmp slice files. Done.\n" if @verbose
  end
end
