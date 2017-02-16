require 'amp4e_ldap_tool/cli'
require 'amp4e_ldap_tool/endpoints'
require 'json'

describe Amp4eLdapTool::CLI do
  let(:subject)   { Amp4eLdapTool::CLI.new }

  context '#fetch' do
    context 'amp' do
      let(:amp)       { double("CiscoAMP") }
      let(:output)    { get_output {subject.fetch 'amp'} }
      let(:computer1) { {hostname: "computer_1", links: {}, policy: {}}.to_json }
      let(:computer2) { {hostname: "computer_2", links: {}, policy: {}}.to_json }
      let(:computers) { [Amp4eLdapTool::AMP::Computer.new(computer1),
                         Amp4eLdapTool::AMP::Computer.new(computer2)] }

      let(:group1)    { {name: "group_1", links: {}, policy: {}}.to_json }
      let(:group2)    { {name: "group_2", links: {}, policy: {}}.to_json }
      let(:groups)    { [Amp4eLdapTool::AMP::Group.new(group1),
                         Amp4eLdapTool::AMP::Group.new(group2)] }

      let(:policy1)   { {name: "policy_1", links: {}}.to_json }
      let(:policy2)   { {name: "policy_2", links: {}}.to_json }
      let(:policies)  { [Amp4eLdapTool::AMP::Policy.new(policy1), 
                         Amp4eLdapTool::AMP::Policy.new(policy2)] }

      before(:each) do
        allow(Amp4eLdapTool::CiscoAMP).to receive(:new).and_return(amp)
      end
      
      it 'gets a list of computers with -c' do
        allow(amp).to receive(:get).with(:computers).and_return(computers)
        subject.options = {computers: true}
        expect(output).to eq("#{computers[0].name}\n#{computers[1].name}\n")
      end

      it 'gets a list of groups with -g' do
        allow(amp).to receive(:get).with(:groups).and_return(groups)
        subject.options = {groups: true}
        expect(output).to eq("#{groups[0].name}\n#{groups[1].name}\n")
      end

      it 'gets a list of policies with -p' do
        allow(amp).to receive(:get).with(:policies).and_return(policies) 
        subject.options = {policies: true}
        expect(output).to eq("#{policies[0].name}\n#{policies[1].name}\n")
      end
    end

    context 'ldap' do
      let(:ldap)      { double("LdapScrape") }
      let(:output)    { get_output {subject.fetch 'ldap'} }
      let(:computers) { [Net::LDAP::Entry.new("computer")] }

      before(:each) do
        allow(Amp4eLdapTool::LDAPScrape).to receive(:new).and_return(ldap)
      end

      it 'gets a list of computer names with -c' do
        allow(ldap).to receive(:scrape_ldap_entries).and_return(computers)
        subject.options = {distinguished: true}
        expect(output).to eq("#{computers.first.dn}\n")
      end

      xit 'gets a list of distinguished names with -d' do

      end

      xit 'gets a list of group names with -g' do

      end
    end
  end
end
