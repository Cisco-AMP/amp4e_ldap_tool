require 'amp4e_ldap_tool/endpoints'
require 'json'

describe 'Endpoints' do
  context '.Computer' do
    let(:name)    {"computer_1"}
    let(:guid)    {"88888888-4444-4444-2222-121212121212"}
    let(:os)      {"Windows 10, SP 0.0"}
    let(:group)   {"11111111-2222-3333-4444-121212121212"}
    let(:links)   { {computer: "commputer_endpoint",
                     trajectory: "trajectory_endpoint",
                     group: "group_endpoint"}}
    let(:policy)        { {name: "policy1", 
                           guid: "11111111-2222-3333-4444-121212121212"}}
    let(:api_response)  { {hostname: name, connector_guid: guid, active: true,
                           operating_system: os, group_guid: group, 
                           links: links, policy: policy}.to_json}
    
    it 'returns a valid computer object' do
      computer = Amp4eLdapTool::AMP::Computer.new(JSON.parse(api_response))
      expect(computer.name).to eq(name)
      expect(computer.guid).to eq(guid)
      expect(computer.os).to eq(os)
      expect(computer.group_guid).to eq(group)
      expect(computer.link).to eq(links)
    end
  end

  context '.Group' do
    xit 'returns a group object' do

    end 
  end

  context '.Policy' do
    xit 'returns a policy object' do

    end
  end
end
