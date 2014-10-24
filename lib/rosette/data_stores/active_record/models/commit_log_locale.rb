# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore
      class CommitLogLocale < ActiveRecord::Base

        belongs_to :commit_log, foreign_key: :commit_id, primary_key: :commit_id

        validates :commit_id, presence: true
        validates :locale, presence: true

      end
    end
  end
end
