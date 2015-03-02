# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore
      class CommitLog < ActiveRecord::Base

        include Rosette::Core::CommitLogStatus

        validates :commit_id, presence: true
        validates :status, inclusion: {
          in: Rosette::DataStores::PhraseStatus.all
        }

        has_many :commit_log_locales, {
          foreign_key: :commit_id, primary_key: :commit_id
        }

      end
    end
  end
end
