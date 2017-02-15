require 'spec_helper'
require 'amp4e_ldap_tool/cli'

describe Amp4eLdapTool::CLI do
  let(:subject) { Amp4eLdapTool::CLI.new }
  let(:amp)     { double("CiscoAMP") }

  before(:each) do
    allow(Amp4eLdapTool::CiscoAMP).to receive(:new).and_return(amp)
  end

  context '#fetch' do
    context 'amp' do
      it 'gets a list of computers with -c' do
        allow(amp).to receive(:get).with("computers").and_return("my_computer")
        subject.options = {computers: true}
        expect(subject.fetch("amp")).to eq("my_computer")
      end

      it 'gets a list of groups with -g' do

      end

      xit 'gets a list of policies with -p' do

      end
    end

    context 'ldap' do
      xit 'gets a list of computer names with -c' do

      end

      it 'gets a list of distinguished names with -d' do

      end

      xit 'gets a list of group names with -g' do

      end
    end
  end

  context '#move' do

  end

  context '#create' do

  end
end
