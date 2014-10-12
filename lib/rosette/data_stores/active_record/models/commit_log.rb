# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore
      class CommitLog < ActiveRecord::Base

        UNTRANSLATED = 'UNTRANSLATED'
        PENDING = 'PENDING'
        TRANSLATED = 'TRANSLATED'

        STATUSES = [UNTRANSLATED, PENDING, TRANSLATED]

        validates :commit_id, presence: true
        validates :status, inclusion: { in: STATUSES }

      end
    end
  end
end
