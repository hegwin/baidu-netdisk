describe BaiduNetDisk::Auth do
  describe '.refresh_access_token' do
    let(:user) { OpenStruct.new access_token: 'expired_token', refresh_token: ENV['REFRESH_TOKEN'] }
    let(:hook) do
      -> (access_token, refresh_token) {
        user.access_token = access_token
        user.refresh_token = refresh_token
      }
    end

    before { BaiduNetDisk.after_token_refreshed = hook }
    after  { BaiduNetDisk.after_token_refreshed = nil }

    it 'calls after_token_refreshed hook' do
      VCR.use_cassette('refresh_token_success') do
        BaiduNetDisk::Auth.refresh_access_token(user.refresh_token)
      end

      expect(user.access_token).to eq 'new_access_token'
      expect(user.refresh_token).to eq 'new_refresh_token'
    end

    it 'raises RefreshTokenFailed when token used' do
      VCR.use_cassette('refresh_token_failed') do
        expect { BaiduNetDisk::Auth.refresh_access_token(user.refresh_access_token) }.to raise_error BaiduNetDisk::Exception::RefreshTokenFailed
      end
    end
  end
end
