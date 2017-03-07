require 'amp4e_ldap_tool'

describe Amp4eLdapTool do

  let(:dry_string)  { "CREATE GROUP: host\nCREATE GROUP: Computers.host\n" + 
                      "UPDATE GROUP: Computers.host, PARENT: host\n" +
                      "MOVE PC: computer1.host, GROUP: Computers.host\n" +
                      "MOVE PC: computer2.host, GROUP: Computers.host\n" }
  let(:name)        { ["computer1.host",
                       "computer2.host"] }
  let(:pc)          { [double("AMP::Computer", name: name[0], group_guid: "1234"), 
                       double("AMP::Computer", name: name[1], group_guid: "4321")] }
  let(:groups)      { [double("AMP::Group", name: "group_1", guid: "1234"), 
                       double("AMP::Group", name: "group_2", guid: "4321")] }
  let(:dn)          { ["CN=computer1,CN=Computers,DC=host", 
                       "CN=computer2,CN=Computers,DC=host"] }
  let(:entries)     { [Net::LDAP::Entry.new(dn[0]),
                       Net::LDAP::Entry.new(dn[1])]}
  let(:ldap_groups) { ["host", "Computers.host"] }
  let(:ldap)        { double("LdapScrape", entries: entries, groups: ldap_groups) }
  let(:amp)         { double("CiscoAMP") }
  
  it 'has a version number' do
    expect(Amp4eLdapTool::VERSION).not_to be nil
  end

  context '#dry_run' do
    let(:output) { get_output {Amp4eLdapTool.dry_run(amp, ldap)} }
    
    before(:each) do
      entries[0]["dnshostname"] = name[0]
      entries[1]["dnshostname"] = name[1]
    end

    it 'generates a list of changes' do
      expect(amp).to receive(:get).with(:groups).and_return(groups)
      expect(amp).to receive(:get).with(:computers).and_return(pc)
      expect(ldap).to receive(:parent).with(ldap_groups[0]).and_return(nil)
      expect(ldap).to receive(:parent).with(ldap_groups[1]).and_return(ldap_groups[0])
      expect(ldap).to receive(:parent).with(dn[0]).and_return(ldap_groups[1])
      expect(ldap).to receive(:parent).with(dn[1]).and_return(ldap_groups[1])
      expect(output).to eq(dry_string)
    end
  end

  context '#push_changes' do
    let(:output) { get_output {Amp4eLdapTool.push_changes(amp, ldap)} }

    before(:each) do
      entries[0]["dnshostname"] = name[0]
      entries[1]["dnshostname"] = name[1]
    end

    xit 'pushes the listed changes' do
      
    end
  end
end
