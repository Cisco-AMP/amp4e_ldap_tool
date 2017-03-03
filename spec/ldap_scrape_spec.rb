require 'amp4e_ldap_tool/ldap_scrape'
require 'yaml'
require 'net/ldap'

describe Amp4eLdapTool::LDAPScrape do
  let(:ldap)        { Amp4eLdapTool::LDAPScrape.new }
  let(:domain)      { "host.com" }
  let(:host)        { 'http://localhost:3000' }
  let(:un)          { 'testuser' }
  let(:pw)          { 'testpassword' }
  let(:pc1)         { "computer1" }
  let(:pc2)         { "computer2" }
  let(:pc3)         { "computer3" }
  let(:config)      { {ldap: { host: host, domain: domain, 
                               credentials: { un: un, pw: pw },
                               schema: { filter: filter }}} }
  let(:entries)     { [Net::LDAP::Entry.new("CN=#{pc1},DC=host,DC=com"),
                       Net::LDAP::Entry.new("CN=#{pc2},DC=host,DC=com"),
                       Net::LDAP::Entry.new("CN=#{pc3},DC=host,DC=com")] }
  let(:attributes)  { ["cn", "dnshostname"] }
  let(:filter)      { Net::LDAP::Filter.eq('objectclass', "computer") }
  let(:base)        { "dc=host,dc=com" }
  let(:params)      { {base: base, filter: filter, attributes: attributes} }
  let(:server)      { double("LDAP::Server", search: entries) }

  before(:each) do
    allow(YAML).to receive(:load_file).and_return(config)
    allow(Net::LDAP).to receive(:new).and_return(server)
  end

  context '#initialize' do
    it 'creates a valid Net::LDAP object' do
      expect(ldap.entries).to eq(entries)
    end
  end

  context 'with a valid instance' do
    context '#groups' do
      let(:root)      { 'com' }
      let(:subgroup)  { 'host.com' }

      it 'returns unique parsed dn names' do
        expect(ldap.groups).to eq([root, subgroup])
      end
    end

    context '#get_parent' do
      it 'should return a valid parent dn' do
        expect(ldap.parent(entries[0].dn)).to eq(domain)
      end
    end
  end
end
