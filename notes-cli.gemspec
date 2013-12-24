require File.expand_path('../lib/notes-cli/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'notes-cli'
  s.date        = '2013-01-13'
  s.summary     = "A tool for managing source code annotations"
  s.description = %q{
    notes-cli lets you manage source code annotations such as
    todo or fixme comments, providing a command-line interface as well as a web
    dashboard.
  }.strip.gsub(/\s+/, ' ')
  s.authors     = ["Andrew Berls"]
  s.email       = 'andrew.berls@gmail.com'
  s.homepage    = 'https://github.com/andrewberls/notes-cli'
  s.license     = 'MIT'

  s.executables << 'notes'
  s.files       = `git ls-files`.split($/)
  s.version     = Notes::VERSION

  s.add_runtime_dependency 'sinatra'
  s.add_development_dependency 'rspec', '~> 2.14.1'
end
