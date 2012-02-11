class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword
  
  #SEED_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + [".", "/"]
  
  field :username, type: String # Should be an index. 
  field :password_digest, type: String
  field :email, type: String
  has_and_belongs_to_many :games
  
  key :username  
  validates_presence_of :username
  validates_length_of :username, minimum: 3, maximum: 16
  validates_uniqueness_of :username,  message: "Player already exists with this username."
    
  has_secure_password
  validates_presence_of :password, on: :create 
  
  validates_presence_of :email
  validates_uniqueness_of :email, message: "Player already exists with this email."
  #validates_format_of :email, with: /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
end