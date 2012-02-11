require 'digest/md5'

# A map contains the data for an uploaded map, which can be used to create games.
class Map
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :data, type: String
  field :data_digest, type: String
  has_many :games
  belongs_to :uploader, class_name: "Player", inverse_of: :uploaded_maps
   
  validates_presence_of :name
  
  validates_presence_of :data
  
  index :data_digest, unique: true
  validates_presence_of :data_digest
  validates_uniqueness_of :data_digest
  
  before_validation :generate_data_digest
  
  protected
  def generate_data_digest
    self.data_digest = Digest::MD5.hexdigest(data)
  end
end