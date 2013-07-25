# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|

  # Description Meta...
  s.name        = 'geocoder-griddable'
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael"]
  s.email       = ['mmaccoffe@gmail.com']
  s.homepage    = 'http://github.com/mediaslave24/geocoder-griddable'
  s.summary     = %q{A gem allowing to slice country to grid.}


  # Load Paths...
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']


  # Dependencies (installed via 'bundle install')...
  s.add_dependency("geocoder")
end
