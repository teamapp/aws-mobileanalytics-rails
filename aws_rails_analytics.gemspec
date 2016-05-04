$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aws_rails_analytics/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aws_rails_analytics"
  s.version     = AwsRailsAnalytics::VERSION
  s.authors     = ["Nir Kain"]
  s.email       = ["nir@thumzap.com"]
  s.homepage    = "TODO"
  s.summary     = "Send mobile analytics custom events from your rails server."
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.4"

  s.add_development_dependency "sqlite3"
end
