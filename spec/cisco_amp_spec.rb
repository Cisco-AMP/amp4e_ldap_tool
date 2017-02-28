require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/errors'
require 'amp4e_ldap_tool/endpoints'
require 'yaml'
require 'json'

describe Amp4eLdapTool::CiscoAMP do
  let(:computers)     { "computers" }
  let(:groups)        { "groups" }
  let(:policies)      { "policies" }
  let(:internal_server_error){ "Internal Server Error" }
  let(:too_many_requests)    { "Too Many Requests" }
  let(:ok)            { "OK" }
  let(:accepted)      { "Accepted" }
  let(:created)       { "Created" }
  let(:unauthorized)  { "Unauthorized"}
  let(:bad_request)   { "Bad Request" }
  let(:amp)           { Amp4eLdapTool::CiscoAMP.new}
  let(:email)         { "test@email.com" }
  let(:host)          { "https://localhost:3000" }
  let(:key)           { "akey" }
  let(:version)       { "v1" }
  let(:third)         { "123456789" }
  let(:config)        { {amp: {host: host, email: email,
                         api: {third_party: third, key: key, version: version}}}}
  let(:head)          { double("HTTPOK", to_hash: head_hash) }
  let(:head_hash)     { {Amp4eLdapTool::X_RATELIMIT_REMAINING => 3000,
                         Amp4eLdapTool::X_RATELIMIT_RESET => 15}}

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
      let(:response)    { double("response", header: head, body: body, 
                                             msg: accepted, to_hash: head_hash) }
      
      before(:each) do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(Net::HTTP::Patch).to receive(:new)
          .with(uri).and_return(Net::HTTP::Patch.new(uri))
      end 
      it 'gives a group a parent' do
        expect(amp.update_group(group_guid, parent_guid)).to eq(accepted)
      end
      it 'orphans a group to root' do
        expect(amp.update_group(group_guid, nil)).to eq(accepted)
      end
    end
  end

  context '#create_group' do
    let(:uri)       { URI("#{host}/#{version}/groups/") }
    let(:response)  { double("response", header: head, body: body, 
                                         msg: created, to_hash: head_hash) }
    
    before(:each) do
      expect(Net::HTTP::Post).to receive(:new)
        .with(uri).and_return(Net::HTTP::Post.new(uri))
    end
    context 'with a valid input' do
      let(:group)     { "group_name"}
      let(:body)      { {data: {name: group}}.to_json }
      
      it 'creates a group' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(amp.create_group(group)).to eq(created)
      end
    end
    context 'with a created group' do
      let(:body)      { {}.to_json }
      let(:response)  { double("resp", body: body, msg: internal_server_error)}

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
      let(:response)  { double("response", header: head, body: body, 
                                           msg: accepted, to_hash: head_hash) }

      it 'moves a pc from one group to another' do
        allow(Net::HTTP).to receive(:start).and_return(response)
        expect(amp.update_computer(computer, new_group)).to eq(accepted)
      end
		end
    context 'with valid inputs but bad server response' do
      let(:body) { {errors: "error!"}.to_json }
      let(:invalid_group) { "88888888-4444-4444-2222-121212121212" }
      let(:response) { double("bad_response", header: head, body: body, 
                                              msg: bad_request, to_hash: head_hash) }

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
    let(:group_guid)      { "88888888-4444-4444-2222-121212121212" }
    let(:group_endpoint)  { "api_endpoint_to_group" }
    let(:traj_endpoint)   { "api_endpoint_to_trajectory" }
    let(:policy_name)     { "a_policy" }
    let(:policy_guid)     { "11111111-1111-1111-1111-777777777777" }
    let(:policy_endpoint) { "api_endpoint_to_policy" }

    context 'with good creds and valid request' do
      context 'computers' do
        let(:name)        { "computer_name" }
        let(:guid)        { "11111111-5555-5555-3333-999999999999" }
        let(:active)      { true }
        let(:pc_endpoint) { "api_endpoint_to_computer" }
        let(:os)          { "Windows 10, SP 0.0" }
        let(:body)        { {data: [{hostname: name, connector_guid: guid, 
                                     active: active, group_guid: group_guid, 
                                     operating_system: os,
                                     links: {computer: pc_endpoint,
                                             trajectory: traj_endpoint,
                                             groups: group_endpoint },
                                     policy: {name: policy_name, 
                                              guid: policy_guid}}]}.to_json }
        let(:response)    { double("response", header: head, body: body, 
                                               msg: ok, to_hash: head_hash) }
        
        it 'sends an api request for a list of computers' do
          allow(Net::HTTP).to receive(:start).and_return(response)
          expect(amp.get(computers).first.name).to eq(name)
          expect(amp.get(computers).first.guid).to eq(guid)
          expect(amp.get(computers).first.link[:computer]).to eq(pc_endpoint)
          expect(amp.get(computers).first.active).to eq(active)
          expect(amp.get(computers).first.group_guid).to eq(group_guid)
          expect(amp.get(computers).first.policy[:name]).to eq(policy_name)
          expect(amp.get(computers).first.os).to eq(os)
        end
        context 'with an exceeded ratelimit' do 
          let(:sleep_rate)  { "4" }
          let(:limit)       { "0" }
          let(:head)        { double("HTTPTooManyRequests", to_hash: head_hash)}
          let(:head_hash)   {{Amp4eLdapTool::X_RATELIMIT_REMAINING => sleep_rate,
                              Amp4eLdapTool::X_RATELIMIT_RESET => sleep_rate}}
          let(:response)    {double("response", header: head, body: body,
                                    msg: too_many_requests, to_hash: head_hash)}
          let(:head_ok)     { double("HTTPOK", to_hash: head_hash_ok)}
          let(:head_hash_ok){{Amp4eLdapTool::X_RATELIMIT_REMAINING => limit,
                              Amp4eLdapTool::X_RATELIMIT_RESET => sleep_rate}}
          let(:response_ok) {double("response", header: head, body:body, 
                                                msg: ok, to_hash: head_hash_ok)}

          it 'does not send the request' do
            allow(Net::HTTP).to receive(:start).and_return(response, response_ok)
            expect(amp).to receive(:sleep).with(4)
            expect(amp.get(computers).first.name).to eq(name)
          end
        end
      end
      context 'policies' do
        let(:desc)        { "a mock policy description" }
        let(:product)     { "windows" }
        let(:default)     { false }
        let(:serial_num)  { 1 }
        let(:body)        { { data: [{name: policy_name, description: desc,
                                  guid: policy_guid, product: product,
                                  default: default, serial_number: serial_num,
                                  links: {policy: policy_endpoint}}]}.to_json }
        let(:response)    { double("response", header: head, body: body, 
                                               msg: ok, to_hash: head_hash) }

        it 'sends an api request for a list of policies' do
          allow(Net::HTTP).to receive(:start).and_return(response)
          expect(amp.get(policies).first.name).to eq(policy_name)
          expect(amp.get(policies).first.product).to eq(product)
          expect(amp.get(policies).first.description).to eq(desc)
          expect(amp.get(policies).first.link).to eq(policy_endpoint)
          expect(amp.get(policies).first.guid).to eq(policy_guid)
          expect(amp.get(policies).first.serial_number).to eq(serial_num)
          expect(amp.get(policies).first.default).to eq(default)
        end
      end
      context 'groups' do
        let(:name)    { "group_name" }
        let(:desc)    { "a mock group" }
        let(:body)    { {data: [{name: name, links: {group: group_endpoint}, 
                                 description: desc, group_guid: group_guid}]}.to_json }
        let(:response){ double("response", header: head, body: body, msg: ok,
                                           to_hash: head_hash) }

        it 'sends an api request for a list of groups' do
          allow(Net::HTTP).to receive(:start).and_return(response)
          expect(amp.get(groups).first.name).to eq(name)
          expect(amp.get(groups).first.description).to eq(desc)
          expect(amp.get(groups).first.guid).to eq(group_guid)
          expect(amp.get(groups).first.link).to eq(group_endpoint)
        end
      end
    end
    context 'with bad creds' do
      let(:body)     {{errors: [{ error_code: 401, description: "Unauthorized",
                       details: ["Unknown API key or Client ID"]}]}.to_json}
      let(:response) { double("response", header: head, body: body, 
                                          msg: unauthorized, to_hash: head_hash) }

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
