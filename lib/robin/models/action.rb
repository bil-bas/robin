module Robin::Models
class Action < Base
  include Mongoid::Timestamps

  field :data, type: String
  embedded_in :game, class_name: "Robin::Models::Game"
  
  validates_presence_of :data
end
end