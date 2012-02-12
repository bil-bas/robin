source 'http://rubygems.org'

gem 'sinatra', '~> 1.3.2'
gem 'mongoid', '~> 2.4.3'
gem 'bson_ext', '~> 1.5.2'
gem 'bcrypt-ruby', '~> 3.0.1'
gem 'pony', '~> 1.4'

group :production do
  # Not needed for testing and EventMachine doesn't work on Windows anyway.
  gem 'thin', '~> 1.3.1'
end

group :development do
  gem 'foreman', '~> 0.39.0'
end

group :test do
  gem 'bacon', '~> 1.1.0'
  gem 'bacon-rr', '~> 0.1.0'
  gem 'rack-test', '~> 0.6.1'
end
  
