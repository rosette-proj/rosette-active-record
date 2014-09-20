source "https://rubygems.org"

gemspec

ruby '1.9.3', engine: 'jruby', engine_version: '1.7.12'

gem 'rosette-core', '~> 1.0.0', path: '~/workspace/rosette-core'

group :development, :test do
  gem 'pry', '~> 0.9.0'
  gem 'pry-nav'
  gem 'rake'
end

group :test do
  gem 'rspec'
  gem 'rr'
end
