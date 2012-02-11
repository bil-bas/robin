require 'digest/md5'
require 'zlib'

# A map contains the data for an uploaded map, which can be used to create games.
class Map
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :data_compressed, type: BSON::Binary
  field :data_digest, type: String
  has_many :games
  belongs_to :uploader, class_name: "Player", inverse_of: :uploaded_maps
   
  validates_presence_of :name
  
  validates_presence_of :data
  
  index :data_digest, unique: true
  validates_presence_of :data_digest
  validates_uniqueness_of :data_digest
  
  def data=(data)
    # Get the hash of the uncompressed data so we never have multiple
    # copies of the same map uploaded..
    self.data_digest = Digest::MD5.hexdigest data
    # Compress the data.
    compressed = Zlib::Deflate.deflate data, 9
    self.data_compressed = BSON::Binary.new compressed
  end
  
  def data
    Zlib::Inflate.inflate data_compressed.to_s
  end
end