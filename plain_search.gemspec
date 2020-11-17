$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "plain_search/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "plain_search"
  s.version     = PlainSearch::VERSION
  s.authors     = ["Andreas Baumgart"]
  s.email       = ["andreas@baumgart.software"]
  s.homepage    = "https://github.com/polycaster/plain_search"
  s.summary     = "A simple scored search plugin for ActiveRecord models. Suited for small projects with little needs for scalability and a reserved attitude towards technical debt."
  s.description = "A simple scored search plugin for ActiveRecord models. Suited for small projects with little needs for scalability and a reserved attitude towards technical debt."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "sqlite3"
end
