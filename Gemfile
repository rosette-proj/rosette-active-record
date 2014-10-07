source "https://rubygems.org"

gemspec

ruby '2.0.0', engine: 'jruby', engine_version: '1.7.15'

gem 'rosette-core', '~> 1.0.0', path: '~/workspace/rosette-core'

group :development, :test do
  gem 'pry', '~> 0.9.0'
  gem 'pry-nav'
  gem 'rake'
end

group :test do
  gem 'activerecord-jdbcmysql-adapter', '~> 1.3.0'
  gem 'factory_girl', '~> 4.4.0'
  gem 'rspec'
  gem 'rr'
end
