class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :scenario, type: String
  field :mode, type: String
  field :initial, type: String # Essentially, this is the .sgl file.
  field :turn, type: Integer, default: 0
  field :complete, type: Boolean, default: false
  has_and_belongs_to_many :players # Well, 2 :)
  embeds_many :actions
  
  validates_presence_of :scenario
  validates_presence_of :mode
  validates_presence_of :initial
  
  def current_player
    players[turn % players.size]
  end
end