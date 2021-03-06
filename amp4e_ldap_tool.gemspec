# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amp4e_ldap_tool/version'

Gem::Specification.new do |spec|
  spec.name          = "amp4e_ldap_tool"
  spec.version       = Amp4eLdapTool::VERSION
  spec.authors       = ["vbakala"]
  spec.email         = ["vbakala@cisco.com"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "thor", "~> 0.19.4"
  spec.add_dependency "net-ldap", "~> 0.15.0" 
  spec.add_dependency "terminal-table", "~> 1.7", ">= 1.7.3"
  spec.homepage = "https://github.com/Cisco-AMP/amp4e_ldap_tool"
end
