# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore
      class CommitLog < ActiveRecord::Base

        STATUSES = Rosette::DataStores::PhraseStatus.constants.map(&:to_s)

        validates :commit_id, presence: true
        validates :status, inclusion: { in: STATUSES }

      end
    end
  end
end
