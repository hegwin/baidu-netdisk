describe BaiduNetDisk::Uploader do
  subject { described_class.new(source_path, target_path) }

  let(:small_fixture_file_name) { 'test.csv' }
  let(:small_fixture_file_size) { 54 }
  let(:small_fixture_file_md5)  { 'adb786a1c7688ee00e916f35c7c7a096' }

  let(:big_fixture_file_name) { 'big.txt' }
  let(:big_fixture_file_size) { 10 * 1024 * 1024 }

  let(:source_path) { File.join(File.dirname(__FILE__), '..', 'fixtures', small_fixture_file_name) }
  let(:target_path) { '/apps/rspec/test.csv' }

  def create_big_file(path)
    File.open(path, 'w') do |f|
      f.write '1' * big_fixture_file_size
    end
  end

  def remove_big_file(path)
    File.delete path
  end

  describe '.new' do
    it 'initiates instance variables' do
      expect(subject.instance_variable_get :@source_path).to eq source_path
      expect(subject.instance_variable_get :@target_path).to eq target_path
      expect(subject.instance_variable_get :@slices).to eq []
      expect(subject.instance_variable_get :@is_dir).to be_falsey
      expect(subject.instance_variable_get :@refresh_token).to eq BaiduNetDisk.refresh_token
      expect(subject.instance_variable_get :@access_token).to eq BaiduNetDisk.access_token
    end

    it 'calculates file MD5 and size' do
      expect(subject.instance_variable_get :@file_size).to eq small_fixture_file_size
      expect(subject.instance_variable_get :@content_md5).to eq small_fixture_file_md5
    end

    it 'raises error when source_path is a directory' do
      expect { described_class.new(File.join(__dir__, '../fixtures'), target_path) }.to \
        raise_error BaiduNetDisk::Exception::UploadDirectoryNotSupported
    end
  end

  describe '#execute' do
    it 'uploads a small file to net disk' do
      VCR.use_cassette('full_upload_success') do
        result = subject.execute
        expect(result['errno']).to be_zero
        expect(result['size']).to eq small_fixture_file_size
      end
    end

    context 'access token expired while refresh token works' do
      let(:expired_token) { 'expired' }
      subject { described_class.new(source_path, target_path, access_token: expired_token) }
      before do
        allow(subject).to receive(:upload_by_slices)
        allow(subject).to receive(:create_file)
      end

      it 'tries to refresh token' do
        VCR.use_cassette('pre_upload_token_expired_and_refresh') do
          expect(subject).to receive(:refresh_token!).and_call_original
          subject.execute
          expect(subject.instance_variable_get :@access_token).not_to eq expired_token
        end
      end

      context 'refresh_token not provided' do
        it 'does not try to refresh' do
          subject.instance_variable_set :@refresh_token, nil
          allow(subject).to receive(:pre_upload).and_raise BaiduNetDisk::Exception::AccessTokenExpired
          expect(BaiduNetDisk::Auth).not_to receive(:refresh_access_token)

          expect { subject.execute }.to raise_error BaiduNetDisk::Exception::RefreshTokenNotProvided
        end
      end
    end

    context 'uploading permission denied' do
      it 'returns false and does clear up' do
        allow(subject).to receive(:pre_upload).and_raise BaiduNetDisk::Exception::PermissionDenied

        expect(subject).to receive(:clear_up)
        expect(subject.execute).to be_falsey
      end
    end
  end

  describe '#prepare' do
    context 'small file' do
      it 'assigns file slices' do
        subject.send :prepare

        slices = subject.instance_variable_get :@slices

        expect(slices).to eq [
          { md5: small_fixture_file_md5, slice_file_path: source_path, block_id: 0 }
        ]
      end

    end

    context 'file with size greater than 4 MB' do
      let(:source_path) { File.join(__dir__, '..', 'fixtures', big_fixture_file_name) }
      before { create_big_file(source_path) }
      after do
        remove_big_file(source_path)
        subject.send :clear_up
      end

      it 'split origin file into 4MB slices' do
        subject.send :prepare

        slices = subject.instance_variable_get :@slices
        slice_prefix = subject.instance_variable_get :@slice_prefix

        expect(slices.size).to eq(3)
        expect(slices[0][:md5]).to eq slices[1][:md5]
        expect(slices[0][:md5]).not_to eq slices[2][:md5]

        slices.each do |slice|
          expect(slice[:slice_file_path]).to include slice_prefix
          expect(slice[:block_id]).to be_nil
        end
      end

      it 'does not create more files when retries' do
        subject.send :prepare

        expect { subject.send :prepare }.not_to change { subject.instance_variable_get(:@slices).size }
      end
    end
  end

  describe '#clear_up' do
    context 'small file' do
      it 'keeps original file' do
        subject.send :prepare
        subject.send :clear_up

        expect(File.exist?(source_path)).to be_truthy
      end
    end

    context 'file with size greater than 4 MB' do
      let(:source_path) { File.join(__dir__, '..', 'fixtures', big_fixture_file_name) }
      before { create_big_file(source_path) }
      after do
        remove_big_file(source_path)
      end

      it 'removes slice files' do
        subject.send :prepare
        slices = subject.instance_variable_get :@slices

        slices.each do |slice|
          expect(File.exist?(slice[:slice_file_path])).to be_truthy
        end

        subject.send :clear_up

        expect(File.exist?(source_path)).to be_truthy
        slices.each do |slice|
          expect(File.exist?(slice[:slice_file_path])).to be_falsey
        end
      end
    end
  end

  describe '#pre_upload' do
    context 'files with size greater than 4 MB' do
      let(:source_path) { File.join(__dir__, '..', 'fixtures', big_fixture_file_name) }
      before { create_big_file(source_path) }
      after do
        subject.send :clear_up
        remove_big_file(source_path)
      end

      it 'assigns block id for each slices' do
        subject.send :prepare
        slices = subject.instance_variable_get :@slices

        slices.each {|slice| expect(slice[:block_id]).to be_nil }

        VCR.use_cassette('pre_upload_success') do
          subject.send :pre_upload
        end

        slices.each {|slice| expect(slice[:block_id]).to be_kind_of Integer }
      end
    end
  end
end
