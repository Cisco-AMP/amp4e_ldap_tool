require 'amp4e_ldap_tool/ldap_scrape'
require 'yaml'
require 'json'
require 'net/ldap'

describe Amp4eLdapTool::LDAPScrape do
  let(:ldap)        { Amp4eLdapTool::LDAPScrape.new }
  let(:email)       { 'test@email.com' }
  let(:host)        { 'http://localhost:3000' }
  let(:un)          { 'testuser' }
  let(:pw)          { 'testpassword' }
  let(:filter)      { 'computer' }
  let(:attributes)  { 'cn' }
  let(:domain)      { 'computers.host' }
  let(:config)      { {ldap: { host: host, email: email, domain: domain, 
                               credentials: { un: un, pw: pw },
                               schema: { filter: filter, attributes: attributes }}}}

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

  context 'with a valid instance' do
    let(:server)        { double('ldapserver') }
    let(:distinguished) { 'cn=computer1,dc=computers,dc=host' }
    
    before(:each) do
      allow(Net::LDAP).to receive(:new).and_return(server)
    end
    
    context '#scrape_ldap_entries' do
      let(:entry)   { Net::LDAP::Entry.new('dc=com') }
      let(:entry2)  { Net::LDAP::Entry.new('dc=com2') }
      let(:entry3)  { Net::LDAP::Entry.new('dc=com3') }
    
      it 'returns an array of entries' do
        allow(server).to receive(:search).and_yield(entry).and_yield(entry2).and_yield(entry3)
        expected_array = [ entry, entry2, entry3 ]
        expect(ldap.scrape_ldap_entries).to match_array(expected_array)
      end
    end
    
    context '#get_groups' do
      let(:root)    { 'host' }
      let(:sub_dn)  { 'computers.host' }

      it 'returns parsed dn names' do
        expect(ldap.get_groups(distinguished)).to eq([root, sub_dn])
      end
      
      context 'multiple same named groups' do
        it 'should not return a new group to add' do
          expect(ldap.get_groups(distinguished)).to eq([root, sub_dn]) 
          expect(ldap.get_groups(distinguished)).to eq([])
        end
      end
    end

    context '#get_computer' do
      let(:computer)  { 'computer1.computers.host' }
      
      it 'returns a computer name' do
        expect(ldap.get_computer(distinguished)).to eq(computer)
      end
    end

    context '#make_distinguished' do
      let(:distinguished_domain) { 'dc=computers,dc=host' }
      
      it 'returns a distinguished name' do
        expect(ldap.make_distinguished(domain)).to eq(distinguished_domain)
      end
    end

    context '#get_parent' do
      let(:has_two_parents) { 'test.server.local' }
      let(:has_parent)      { 'server.local' }
      let(:orphan)          { 'local' }

      it 'should return a valid parent class' do
        expect(ldap.get_parent(has_two_parents)).to eq(has_parent)
      end

      it 'should return nil for a group with no parent class' do
        expect(ldap.get_parent(orphan)).to eq(nil)
      end
    end
  end
end
