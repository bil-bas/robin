class Action
  include Mongoid::Document
  include Mongoid::Timestamps

  field :data, type: String
  embedded_in :game
  
  validates_presence_of :data
end