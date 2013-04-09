Gem::Specification.new do |s|
  s.name        = 'notes-cli'
  s.version     = '1.1.0'
  s.executables << 'notes'
  s.date        = '2013-01-13'
  s.summary     = "A tool for managing source code annotations"
  s.authors     = ["Andrew Berls"]
  s.email       = 'andrew.berls@gmail.com'
  s.files       = Dir['lib/**/*']
  s.add_development_dependency "rspec-core"
  s.homepage    =
    'https://github.com/andrewberls/notes-cli'
end
