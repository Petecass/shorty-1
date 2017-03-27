require 'sinatra'
require 'redis'

redis = Redis.new

get '/' do
  'Hello World'
end
