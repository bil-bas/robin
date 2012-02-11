class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :scenario, type: String
  field :mode, type: String
  field :initial, type: String # Essentially, this is the .sgl file.
  has_and_belongs_to_many :players # Well, 2 :)
  embeds_many :turns
  
  validates_presence_of :scenario
  validates_presence_of :mode
  validates_presence_of :initial
  
  def create_turn?(number) 
    turns.count == number - 1
  end  
end