require 'amp4e_ldap_tool/cli'

describe Amp4eLdapTool::CLI do
  let(:subject)   { Amp4eLdapTool::CLI.new }

  context '#fetch' do
    context 'amp' do
      let(:amp)       { double("CiscoAMP") }
      let(:output)    { get_output {subject.fetch 'amp'} }
      let(:computers) { [double("AMP::Computer", name: "computer_1"), 
                         double("AMP::Computer", name: "computer_2")] }
      let(:groups)    { [double("AMP::Group", name: "group_1"), 
                         double("AMP::Group", name: "group_2")] }
      let(:policies)  { [double("AMP::Policy", name: "policy_1"), 
                         double("AMP::Policy", name: "policy_2")] }

      before(:each) do
        allow(Amp4eLdapTool::CiscoAMP).to receive(:new).and_return(amp)
      end
      
      it 'gets a list of computers with -c' do
        allow(amp).to receive(:get).with(:computers).and_return(computers)
        subject.options = {computers: true}
        expect(output).to eq("computers:\n#{computers[0].name}\n#{computers[1].name}\n")
      end

      it 'gets a list of groups with -g' do
        allow(amp).to receive(:get).with(:groups).and_return(groups)
        subject.options = {groups: true}
        expect(output).to eq("groups:\n#{groups[0].name}\n#{groups[1].name}\n")
      end

      it 'gets a list of policies with -p' do
        allow(amp).to receive(:get).with(:policies).and_return(policies) 
        subject.options = {policies: true}
        expect(output).to eq("policies:\n#{policies[0].name}\n#{policies[1].name}\n")
      end

      it 'gets a list of computers and groups with -cg' do
        allow(amp).to receive(:get).with(:groups).and_return(groups)
        allow(amp).to receive(:get).with(:computers).and_return(computers)
        subject.options = {groups: true, computers: true}
        results = "groups:\n#{groups[0].name}\n#{groups[1].name}\n"
        results << "computers:\n#{computers[0].name}\n#{computers[1].name}\n"
        expect(output).to eq(results)
      end
    end

    context 'ldap' do
      let(:ldap)      { double("LdapScrape") }
      let(:output)    { get_output {subject.fetch 'ldap'} }
      let(:computers) { [Net::LDAP::Entry.new("computer")] }

      before(:each) do
        allow(Amp4eLdapTool::LDAPScrape).to receive(:new).and_return(ldap)
      end

      it 'gets a list of distinguished names with -d' do
        allow(ldap).to receive(:scrape_ldap_entries).and_return(computers)
        subject.options = {distinguished: true}
        expect(output).to eq("#{computers.first.dn}\n")
      end
    end
  end
end
