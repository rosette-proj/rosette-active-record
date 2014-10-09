# encoding: UTF-8

FactoryGirl.define do
  factory :repo_last_commit, class: Rosette::DataStores::ActiveRecordDataStore::RepoLastCommit do
    repo_name 'foobar_repo'
    sequence :last_commit_id, 'aaaa'
  end
end
