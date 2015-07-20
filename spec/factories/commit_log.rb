# encoding: UTF-8

FactoryGirl.define do
  factory :commit_log, class: Rosette::DataStores::ActiveRecordDataStore::CommitLog do
    repo_name 'foobar_repo'
    sequence :commit_id, 'aaaa'
    status 'NOT_SEEN'
  end
end
