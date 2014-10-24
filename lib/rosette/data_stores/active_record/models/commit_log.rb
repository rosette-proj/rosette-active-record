# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore
      class CommitLog < ActiveRecord::Base

        STATUSES = Rosette::DataStores::PhraseStatus.constants.map(&:to_s)

        validates :commit_id, presence: true
        validates :status, inclusion: { in: STATUSES }

        has_many :commit_log_locales, foreign_key: :commit_id, primary_key: :commit_id

      end
    end
  end
end
