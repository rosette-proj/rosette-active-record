# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      class RepoLastCommit < ActiveRecord::Base
        extend ExtractParams

        validates :repo_name, presence: true
        validates :last_commit_id, presence: true

      end
    end
  end
end
