# frozen_string_literal: true
require 'rack/test'
require 'rspec'
require 'pry'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.before(:each) { redis.flushdb }
  c.after(:each) { redis.quit }
end
