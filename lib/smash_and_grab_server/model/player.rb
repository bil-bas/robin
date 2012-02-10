class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String # Should be an index.
  field :password, type: String
  field :email, type: String
  has_and_belongs_to_many :games
  
  validates_uniqueness_of :name,  message: "Player already exists with this name."
  validates_uniqueness_of :email, message: "Player already exists with this email."
end