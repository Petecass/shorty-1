# frozen_string_literal: true
require 'sinatra'
require 'redis'
require 'json'
require './url'

before do
  content_type 'application/json'
end

def respond_with(code, body)
  status code
  body.to_json
end

redis = Redis.new

post '/shorten' do
  required_params_present = params && params[:url] && !params[:url].empty?
  return respond_with(400, error: 'no url present') unless required_params_present

  if redis.exists params[:shortcode]
    respond_with(409, error: 'The desired shortcode is already in use')

  elsif params[:shortcode] =~ /^[0-9a-zA-Z_]{6}$/
    Url.create(params)
    respond_with(201, shortcode: params[:shortcode])

  else
    respond_with(422, error: 'Shortcode not valid')
  end
end

get '/:shortcode' do
  if redis.exists params[:shortcode]
    redirect redis.get params[:shortcode]
  else
    respond_with(404, error: 'Shortcode not found')
  end
end

get '/:shortcode/stats' do
  if redis.exists params[:shortcode]

  else
    respond_with(404, error: 'Shortcode not found')
  end
end
