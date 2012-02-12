require 'pony'

Pony.options = {
    via: :smtp,
    via_options: {
        address: 'smtp.gmail.com',
        port: '587',
        domain: ENV['GMAIL_SMTP_USER'],
        user_name: ENV['GMAIL_SMTP_USER'],
        password: ENV['GMAIL_SMTP_PASSWORD'],
        authentication: :plain,
        enable_starttls_auto: true,

    },
    from: "Smash and Grab",
}

class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword
  
  #SEED_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + [".", "/"]
  
  field :username, type: String # Should be an index. 
  field :password_digest, type: String
  field :email, type: String
  has_and_belongs_to_many :games
  has_many :uploaded_maps, class_name: "Map", inverse_of: :uploader
  
  index :username, :unique  
  validates_presence_of :username
  validates_length_of :username, minimum: 3, maximum: 16
  validates_uniqueness_of :username,  message: "Player already exists with this username."
    
  has_secure_password
  validates_presence_of :password, on: :create 
  
  validates_presence_of :email
  validates_uniqueness_of :email, message: "Player already exists with this email."
  #validates_format_of :email, with: /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
  
  class << self 
    # Returns the requested Player object if the password checks out.
    def authenticate(username, password)
      player = where(username: username).first
      player and player.try(:authenticate, password)
    end
  end
  
  def send_mail(subject, message)
    Pony.mail to: email, subject: subject,
              body: <<END
Hi #{username},

#{message}

--- The Smash and Grab server

----------------------------

This is an automated message; please do not reply!
END
  end
end