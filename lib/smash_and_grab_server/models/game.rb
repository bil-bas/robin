class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :mode, type: String
  field :turn, type: Integer, default: 0
  field :complete, type: Boolean, default: false
  has_and_belongs_to_many :players # Well, 2 :)
  embeds_many :actions
  belongs_to :map
  
  validates_presence_of :players
  validates_presence_of :map
  validates_presence_of :mode
  
  def current_player
    players[turn % players.size]
  end
  
  def summary
    {
        game_id: id,
        map_id: map.id,
        mode: mode,
        turn: turn,
        complete: complete?,
    }
  end
end