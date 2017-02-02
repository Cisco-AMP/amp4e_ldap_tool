require 'spec_helper'
require 'amp4e_ldap_tool/cisco_amp'
require 'amp4e_ldap_tool/errors'
require 'yaml'
require 'json'

describe Amp4eLdapTool::CiscoAMP do
  before(:each) do
    @config = {amp: { host: "https://localhost:3000",
                      email: "test@email.com",
                      api: { third_party: "123456789",
                             key: "some-weird-key",
                             version: "v1" }}}
    allow(YAML).to receive(:load_file).and_return(@config)
    @amp = Amp4eLdapTool::CiscoAMP.new
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
    
    it 'throws an error with a bad  URI' do
      @config[:amp][:host] = "A_bad_hostname!"
      expect{Amp4eLdapTool::CiscoAMP.new}
        .to raise_error(Amp4eLdapTool::AMPBadURIError)
    end
  end

	context '#move_computer' do
		context 'with a valid request' do
			before(:each) do
        @body = {data: { hostname: "test_pc"}}.to_json
        @response = double("response", 
                            body: @body, 
                            message: "Accepted", 
                            code: "202", 
                            status: "202 Accepted")
        allow(Net::HTTP).to receive(:start).and_return(@response)
      end

      it 'moves a pc from one group to another' do
        ancestry = {parent: "parent_guid", child: "child_guid"}
        expect(@amp.move_computer("test_pc", "new_guid")).to eq("Accepted")
      end
		end

    context 'with bad inputs' do
      before(:each) do
        @body = { errors: "error!" }.to_json
        @bad_response = double("bad_response",
                               body: @body,
                               message: "Bad Request",
                               code: "400")
        allow(Net::HTTP).to receive(:start).and_return(@bad_response)
      end

      it 'raises a Bad Request error' do
        expect{@amp.move_computer("pc_guid", "bad_group_guid")}
          .to raise_error(Amp4eLdapTool::AMPBadRequestError)
      end
    end
	end

  context '#get' do
    context 'with good creds and valid request' do
    
      it 'sends an api request for a list of computers' do
        @body = {metadata: {links: {self: "computers"}},
                 data: [ { hostname: "computer1"},
                         { hostname: "computer2"}]}.to_json
        @response = double("response", body: @body, message: "OK", code: "200")
        allow(Net::HTTP).to receive(:start).and_return(@response)
        expect(@amp.get("computers")).to match_array(["computer1", "computer2"])
      end

      it 'sends an api request for a list of groups' do
        @body = {metadata: {links: {self: "groups"}},
                 data: [ { name: "a_name"},
                         { name: "b_name"}]}.to_json
        @response = double("response", body: @body, message: "OK", code: "200")
        allow(Net::HTTP).to receive(:start).and_return(@response)
        expect(@amp.get("groups")).to match_array(["a_name", "b_name"])
      end
    end

    context 'with bad creds' do
      before(:each) do
        @response_body = {errors: [{ error_code: 401,
                          description: "Unauthorized",
                          details: ["Unknown API key or Client ID"]}]}.to_json
        @response = double("response", body: @response_body, 
                            message: "Unauthorized", code: "401")
        allow(Net::HTTP).to receive(:start).and_return(@response)
      end

      it 'should return invalid creds response' do
        expect{@amp.get("computers")}
          .to raise_error(Amp4eLdapTool::AMPUnauthorizedError)
      end
    end

    context 'with a refused connection' do
      before(:each) do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)       
      end

      it 'should throw a connection refused error' do
        expect{@amp.get("computers")}
          .to raise_error(Errno::ECONNREFUSED)
      end
    end
  end
end
