
class Url


  def self.generate_shortcode
    SecureRandom.base64(3)
  end
end
