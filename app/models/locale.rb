class Locale < ActiveRecord::Base
  belongs_to :competition
  validates :competition, presence: true

  validates :handle, presence: true
  validates :handle, uniqueness: { scope: :competition }, allow_nil: true, allow_blank: true

  validates :name, presence: true
  validates :name, uniqueness: { scope: :competition }, allow_nil: true, allow_blank: true
end