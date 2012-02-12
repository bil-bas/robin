module Robin::Models
  class Base
    include Mongoid::Document
    include Robin::Configuration
  end
end