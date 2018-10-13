class Post < ActiveRecord::Base
  belongs_to :author
  has_many :comments, :dependent => :destroy

  validates_presence_of :body, :author, :title
end
