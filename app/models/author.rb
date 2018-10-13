class Author < ActiveRecord::Base
  has_many :posts, :dependent => :destroy

  validates_presence_of :name, :email

  def to_s
    name
  end
end
