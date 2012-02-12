module Robin::Models
class Game < Base
  include Mongoid::Timestamps
  
  field :mode, type: String, default: config[:game, :default_mode]
  field :turn, type: Integer, default: 0 # Number of player turns completed (not rounds).
  field :complete, type: Boolean, default: false
  has_and_belongs_to_many :players, class_name: "Robin::Models::Player"
  embeds_many :actions, class_name: "Robin::Models::Action"
  belongs_to :map, class_name: "Robin::Models::Map"
  
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
end