require 'amp4e_ldap_tool'

describe Amp4eLdapTool do
  it 'has a version number' do
    expect(Amp4eLdapTool::VERSION).not_to be nil
  end

  context '#compare' do
    let(:output)      { get_output {Amp4eLdapTool.compare(amp, ldap, true)} }
    let(:dry_string)  { "CREATE GROUP: host\nCREATE GROUP: Computers.host\n" + 
                        "UPDATE GROUP: host\tParent: nil\nUPDATE GROUP: " + 
                        "Computers.host\tParent: host\n" }
    let(:name)        { ["computer1.Computers.Host",
                         "computer2.Computers.Host"] }
    let(:pc)          { [double("AMP::Computer", name: name[0], group_guid: "1234"), 
                         double("AMP::Computer", name: name[1], group_guid: "4321")] }
    let(:groups)      { [double("AMP::Group", name: "group_1", guid: "1234"), 
                         double("AMP::Group", name: "group_2", guid: "4321")] }
    let(:new_groups)  { groups << double("AMP::Group", name: "group_3") }
    let(:dn)          { ["CN=computer1,CN=Computers,DC=Host", 
                         "CN=computer2,CN=Computers,DC=Host"] }
    let(:entries)     { [Net::LDAP::Entry.new(dn[0]),
                         Net::LDAP::Entry.new(dn[1])]}
    let(:ldap_groups) { ["host", "Computers.host"] }
    let(:ldap)        { double("LdapScrape", entries: entries, groups: ldap_groups) }
    let(:amp)         { double("CiscoAMP") }

    before(:each) do
      entries[0]["dnshostname"] = name[0]
      entries[1]["dnshostname"] = name[1]
    end

    xit 'generates a list of changes' do
      expect(ldap).to receive(:parent).with("host").and_return(nil)
      expect(ldap).to receive(:parent).with("Computers.host").and_return("host")
      expect(ldap).to receive(:parent).with(name[0].downcase).and_return("computers.host")
      expect(amp).to receive(:get).with(:groups).and_return(groups, new_groups)
      expect(amp).to receive(:get).with(:computers).and_return(pc)
      expect(output).to eq(dry_string)
    end
  end
end
