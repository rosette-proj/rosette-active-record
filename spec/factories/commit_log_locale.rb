# encoding: UTF-8

FactoryGirl.define do
  factory :commit_log_locale, class: Rosette::DataStores::ActiveRecordDataStore::CommitLogLocale do
    sequence :commit_id, 'aaaa'
    sequence :locale, 'aa-AA'
  end
end
