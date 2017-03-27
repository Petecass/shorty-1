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

post '/shorten' do
  required_params_present = params && params[:url] && !params[:url].empty?
  return respond_with(400, error: 'no url present') unless required_params_present

  if Url.find params[:shortcode]
    respond_with(409, error: 'The desired shortcode is already in use')

  elsif (url = Url.create(params))
    respond_with(201, shortcode: url.shortcode)

  else
    respond_with(422, error: 'Shortcode not valid')
  end
end

get '/:shortcode' do
  if (url = Url.find(params[:shortcode]))
    touch_record(url)

    location = url.url
    redirect location

  else
    respond_with(404, error: 'Shortcode not found')
  end
end

get '/:shortcode/stats' do
  if (url = Url.find(params[:shortcode]))
    body = {
      startDate: url.start_date,
      redirectCount: url.redirect_count,
      lastSeenDate: (url.last_seen_date if url.redirect_count.positive?)
    }.reject { |_k, v| v.nil? }

    respond_with(200, body)
  else
    respond_with(404, error: 'Shortcode not found')
  end
end

def touch_record(url)
  increment_redirect_count(url)
  update_date(url)
end

def increment_redirect_count(url)
  current_count = url.redirect_count
  current_count += 1
  url.update(redirect_count: current_count)
end

def update_date(url)
  url.update(last_seen_date: Time.now.iso8601)
end
