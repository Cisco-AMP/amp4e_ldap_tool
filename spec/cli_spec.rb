require 'amp4e_ldap_tool/cli'

describe Amp4eLdapTool::CLI do
  let(:subject)   { Amp4eLdapTool::CLI.new }

  context '#fetch' do
    context 'amp' do
      let(:amp)       { double("CiscoAMP") }
      let(:output)    { get_output {subject.fetch 'amp'} }
      let(:computers) { ["computer_name","computer2"] }
      let(:groups)    { ["group_name","group2"]}
      
      before(:each) do
        allow(Amp4eLdapTool::CiscoAMP).to receive(:new).and_return(amp)
      end
      
      it 'gets a list of computers with -c' do
        allow(amp).to receive(:get).with("computers").and_return(computers)
        subject.options = {computers: true}
        expect(output).to eq("#{computers[0]}\n#{computers[1]}\n")
      end

      it 'gets a list of groups with -g' do
        allow(amp).to receive(:get).with("groups").and_return(groups)
        subject.options = {groups: true}
        expect(output).to eq("#{groups[0]}\n#{groups[1]}\n")
      end

      xit 'gets a list of policies with -p' do
        #TODO on waiting PR's
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
