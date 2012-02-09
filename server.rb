puts "Server start"

require 'sinatra'

get '/' do
  "Hello, world"
end

puts "Server end"