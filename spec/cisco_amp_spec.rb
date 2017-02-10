require 'spec_helper'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/errors'
require 'yaml'
require 'json'

describe Amp4eLdapTool::CiscoAMP do
  let(:amp)     { Amp4eLdapTool::CiscoAMP.new}
  let(:email)   { "test@email.com" }
  let(:host)    { "https://localhost:3000" }
  let(:key)     { "akey" }
  let(:version) { "v1" }
  let(:third)   { "123456789" }
  let(:config)  { {amp: {host: host, email: email,
                   api: {third_party: third, key: key, version: version}}}}
  before(:each) do
    allow(YAML).to receive(:load_file).and_return(config)
  end
  
  context '#initialize' do
    let(:bad_hostname) { "a_bad_hostname" }

    it 'creates a valid web object for amp' do
      expect(amp.base_url).to eq(config[:amp][:host])
      expect(amp.version).to eq(config[:amp][:api][:version])
      expect(amp.email).to eq(config[:amp][:email])
      expect(amp.third_party).to eq(config[:amp][:api][:third_party])
      expect(amp.api_key).to eq(config[:amp][:api][:key])
    end
    it 'throws an error with a bad config' do
      config[:amp][:api][:version] = nil  
      expect{Amp4eLdapTool::CiscoAMP.new}.to raise_error(Amp4eLdapTool::AMPConfigError)
    end
    it 'throws an error with a bad  URI' do
      config[:amp][:host] = bad_hostname
      expect{Amp4eLdapTool::CiscoAMP.new}.to raise_error(Amp4eLdapTool::AMPBadURIError)
    end
  end

  context '#update_group' do
    context 'with valid inputs' do
      let(:body)        { {}.to_json }
      let(:group_guid)  { "88888888-4444-4444-2222-121212121212" }
      let(:parent_guid) { "99999999-3333-2222-1111-121212121212" }
      let(:uri)         { URI("#{host}/#{version}/groups/#{group_guid}/parent") }
      let(:response)    { double("resp", body: body, code: :accepted) }
      
      before(:each) do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(Net::HTTP::Patch).to receive(:new)
          .with(uri).and_return(Net::HTTP::Patch.new(uri))
      end 
      it 'gives a group a parent' do
        expect(amp.update_group(group_guid, parent_guid)).to eq(:accepted)
      end
      it 'orphans a group to root' do
        expect(amp.update_group(group_guid, nil)).to eq(:accepted)
      end
    end
  end

  context '#create_group' do
    let(:uri)       { URI("#{host}/#{version}/groups/") }
    let(:response)  { double("resp", body: body, code: :created) }
    
    before(:each) do
      expect(Net::HTTP::Post).to receive(:new)
        .with(uri).and_return(Net::HTTP::Post.new(uri))
    end
    context 'with a valid input' do
      let(:group)     { "group_name"}
      let(:body)      { {data: {name: group}}.to_json }
      
      it 'creates a group' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(amp.create_group(group)).to eq(:created)
      end
    end
    context 'with a created group' do
      let(:body)      { {}.to_json }
      let(:response)  { double("resp", body: body, code: :internal_server_error)}

      xit 'returns server error until a better response can be built' do
        allow(Net::HTTP).to receive(:start).and_return(response) 
      end
    end
  end

	context '#update_computer' do
    let(:computer)  { "11111111-2222-3333-4444-555555555555"}
		
    context 'with a valid request' do
      let(:new_group) { "88888888-4444-4444-2222-121212121212" }
      let(:body)      { {data: {hostname: computer}}.to_json }
      let(:response)  { double("resp", body: body, code: :accepted) }

      it 'moves a pc from one group to another' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(amp.update_computer(computer, new_group)).to eq(:accepted)
      end
		end
    context 'with valid inputs but bad server response' do
      let(:body) { {errors: "error!"}.to_json }
      let(:invalid_group) { "88888888-4444-4444-2222-121212121212" }
      let(:response) { double("bad_response", body: body, code: :bad_request) }

      it 'raises a Bad Request error' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect{amp.update_computer(computer, invalid_group)}
          .to raise_error(Amp4eLdapTool::AMPBadRequestError)
      end
    end
    context 'with invalid inputs' do
      let(:bad_group_guid) { "some_bad_guid"}
      it 'raises a bad format error' do
        expect{amp.update_computer(computer, bad_group_guid)}
          .to raise_error(Amp4eLdapTool::AMPInvalidFormatError)
      end
    end
	end

  context '#get' do
    let(:computers) { "computers" }
    let(:groups)  { "groups" }
    
    context 'with good creds and valid request' do
      context 'computers' do
        let(:pc1)   { "computer1" }
        let(:pc2)   { "computer2" }
        let(:body)  { {metadata: {links: {self: computers}},
                       data: [{hostname: pc1}, {hostname: pc2}]}.to_json}
        it 'sends an api request for a list of computers' do
          response = double("response", body: body, code: :ok)
          allow(Net::HTTP).to receive(:start).and_return(response)
          expect(amp.get(computers)).to match_array([pc1, pc2])
        end
      end
      context 'groups' do
        let(:group1)  { "group_1" }
        let(:group2)  { "group_2" }
        let(:body){   {metadata: {links: {self: groups}},
                           data: [{name: group1}, {name: group2}]}.to_json}
        it 'sends an api request for a list of groups' do
          response = double("response", body: body, code: :ok)
          allow(Net::HTTP).to receive(:start).and_return(response)
          expect(amp.get(groups)).to match_array([group1, group2])
        end
      end
    end

    context 'with bad creds' do
      let(:body)     {{errors: [{ error_code: 401, description: "Unauthorized",
                       details: ["Unknown API key or Client ID"]}]}.to_json}
      let(:response) { double("response", body: body, code: :unauthorized) }

      it 'should return invalid creds response' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect{amp.get(computers)}
          .to raise_error(Amp4eLdapTool::AMPUnauthorizedError)
      end
    end

    context 'with a refused connection' do
      let(:bad_host) { "http://bad.hostname.com" }
      
      it 'should throw a connection refused error' do
        config[:amp][:host] = bad_host
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)
        expect{amp.get(computers)}
          .to raise_error(Errno::ECONNREFUSED)
      end
    end
  end
end
