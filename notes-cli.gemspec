require File.expand_path('../lib/notes-cli/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'notes-cli'
  s.date        = '2013-01-13'
  s.summary     = "A tool for managing source code annotations"
  #s.description = %q{}
  s.authors     = ["Andrew Berls"]
  s.email       = 'andrew.berls@gmail.com'
  s.homepage    = 'https://github.com/andrewberls/notes-cli'
  s.license     = 'MIT'

  s.executables << 'notes'
  s.files       = `git ls-files`.split($/)
  s.version     = Notes::VERSION

  s.add_development_dependency "rspec-core"
end
