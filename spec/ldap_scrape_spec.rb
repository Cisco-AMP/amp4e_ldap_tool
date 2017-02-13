require 'spec_helper'
require 'amp4e_ldap_tool/ldap_scrape'
require 'yaml'
require 'json'
require 'net/ldap'

describe Amp4eLdapTool::LDAPScrape do
  let(:ldap) { Amp4eLdapTool::LDAPScrape.new }
  let(:email) { 'test.email.com' }
  let(:host) { 'http://localhost:3000' }
  let(:un) { 'testuser' }
  let(:pw) { 'testpassword' }
  let(:filter) { 'computer' }
  let(:attributes) { 'cn' }
  let(:config) { {ldap: { host: host, email: email, 
          credentials: { un: un, pw: pw },
               schema: { filter: filter, attributes: attributes }}}}
  let(:entry) { Net::LDAP::Entry.new('dc=com') }
  let(:entry2) { Net::LDAP::Entry.new('dc=com2') }
  let(:entry3) { Net::LDAP::Entry.new('dc=com3') }
  let(:d_name) { 'cn=pc,dc=server,dc=host' }
  let(:server) { double('ldapserver') }
  
  before(:each) do
    allow(YAML).to receive(:load_file).and_return(config)
  end

  context '#initialize' do
    it 'creates a valid object for ldap' do
      ldap = Amp4eLdapTool::LDAPScrape.new
      expect(ldap.domain).to eq(config[:ldap][:host])
      expect(ldap.filter).to be_a(Net::LDAP::Filter)
      expect(ldap.attributes).to eq(config[:ldap][:schema][:attributes])
    end
  end

  context '#scrape_ldap_entries' do
    it 'returns an array of entries' do
      allow(Net::LDAP).to receive(:new).and_return(server)
      allow(server).to receive(:search).and_yield(entry).and_yield(entry2).and_yield(entry3)
      expected_array = [ entry, entry2, entry3 ]
     expect(ldap.scrape_ldap_entries).to match_array(expected_array)
    end
  end
  
  context '#parse_dn' do
    it 'returns parsed dn names' do
      allow(Net::LDAP).to receive(:new).and_return(server)
      expect(ldap.parse_dn(d_name)).to eq(['host', 'server.host', 'pc.server.host'])
    end
  end
end
