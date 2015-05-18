class Wca::RanksSingle < ActiveRecord::Base
  establish_connection :wca
  self.table_name = "RanksSingle"

  def self.for_event(wca_ids, wca_event_handle)
    where(personId: wca_ids, eventId: wca_event_handle).group_by(&:personId)
  end
end