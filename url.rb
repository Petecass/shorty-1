require 'redis'
require 'json'

class Url
  DB = Redis.new
  attr_accessor :shortcode, :url, :start_date, :redirect_count, :last_seen_date

  def initialize(params)
    @shortcode = self.class.generate_shortcode(params)
    @url = self.class.generate_url(params)
    @start_date = params['startDate'] || params[:startDate] || Time.now.iso8601
    @last_seen_date = params['lastSeenDate'] || params[:lastSeenDate] || Time.now.iso8601
    @redirect_count = self.class.generate_redirect_count(params)
  end

  def update(params)
    params.each do |key, value|
      send("#{key}=", value)
    end

    hash = to_hash
    DB.set(hash['shortcode'], hash.to_json)
    self
  end

  def self.create(params)
    return false unless params && params[:url] && !params[:url].empty?

    url = Url.new(params)
    return false unless url.shortcode =~ /^[0-9a-zA-Z_]{6}$/
    if DB.set(url.shortcode, url.to_hash.to_json)
      url
    else
      false
    end
  end

  def self.find(shortcode)
    record = DB.get(shortcode)
    return nil if record.nil?
    Url.new(JSON.parse(record))
  end

  def self.generate_shortcode(params)
    shortcode = params['shortcode'] || params[:shortcode]
    return shortcode unless shortcode.nil? || shortcode.empty?
    SecureRandom.hex(3)
  end

  def self.generate_url(params)
    params['url'] || params[:url]
  end

  def self.generate_redirect_count(params)
    params['redirectCount'] || params[:redirectCount] || params['redirect_count'] || 0
  end

  def to_hash
    hash = {}
    instance_variables.each { |var| hash[var.to_s.delete('@')] = instance_variable_get(var) }
    hash
  end
end
