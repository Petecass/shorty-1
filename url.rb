require 'redis'
require 'json'

class Url
  DB = Redis.new
  attr_accessor :shortcode, :url, :start_date, :redirect_count

  def initialize(params)
    @shortcode = params['shortcode'] || params[:shortcode]
    @url = params['url'] || params[:url]
    @start_date = params['startDate'] || params[:startDate]
    @last_seen_date = params['last_seen_date'] || params[:lastSeenDate]
    @redirect_count = params['resetCount'] || params[:resetCount] || 0
  end

  def update(params)
    params.each do |key, value|
      send("#{key}=", value)
    end

    hash = to_hash
    DB.set(hash['shortcode'], hash.to_json)
    self
  end

  def to_hash
    hash = {}
    instance_variables.each { |var| hash[var.to_s.delete('@')] = instance_variable_get(var) }
    hash
  end

  def self.create(params)
    return false unless params && params[:url] && !params[:url].empty?

    data = { shortcode: params[:shortcode],
             url: params[:url],
             startDate: Time.now.iso8601,
             lastSeenDate: Time.now.iso8601,
             redirectCount: 0 }

    if DB.set(params[:shortcode], data.to_json)
      Url.new(data)
    else
      false
    end
  end

  def self.find(shortcode)
    record = DB.get(shortcode)
    return nil if record.nil?

    Url.new(JSON.parse(record))
  end

  def self.generate_shortcode
    SecureRandom.base64(3)
  end
end
