$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'amp4e_ldap_tool'

def get_output
  begin
    output = StringIO.new
    $stdout = output
    yield
  ensure
    $stdout = STDOUT
  end
  output.string
end
