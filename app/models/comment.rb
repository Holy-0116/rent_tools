class Comment < ApplicationRecord
  belongs_to :item
  belongs_to :borrower, class_name: "User", foreign_key: "borrower_id"

  validates :text, presence: true
  validates :borrower_id, presence: true
  validates :item_id, presence: true
end