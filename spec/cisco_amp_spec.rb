require 'spec_helper'
require 'amp4e_ldap_tool/cisco_amp'
require 'yaml'

describe Amp4eLdapTool::CiscoAMP do
  before(:each) do
    @config = {
      amp: {
        host: "https://localhost:3000",
        email: "test@email.com",
        api: {
          third_party: "123456789",
          key: "some-weird-key",
          version: "v1" 
        }
      }
    }
    allow(YAML).to receive(:load_file).and_return(@config)
  end

  context '#initialize' do
    it 'creates a valid web object for amp' do
      amp = Amp4eLdapTool::CiscoAMP.new
      expect(amp.base_url).to eq(@config[:amp][:host])
      expect(amp.version).to eq(@config[:amp][:api][:version])
      expect(amp.email).to eq(@config[:amp][:email])
      expect(amp.third_party).to eq(@config[:amp][:api][:third_party])
      expect(amp.api_key).to eq(@config[:amp][:api][:key])
    end

    it 'throws an error with a bad config' do
      @config[:amp][:api][:version] = nil  
      expect{Amp4eLdapTool::CiscoAMP.new}.to raise_error(Amp4eLdapTool::AMPConfigError)
    end
  end

  context '#get' do
    it 'sends an api request for a list of computers' do
      allow(Amp4eLdapTool::CiscoAMP).to receive(:get)
        .with("computers").and_return("blah")
      amp = Amp4eLdapTool::CiscoAMP.new
    end
  end
end
