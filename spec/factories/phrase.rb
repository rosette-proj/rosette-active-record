# encoding: UTF-8

FactoryGirl.define do
  factory :phrase, class: Rosette::DataStores::ActiveRecordDataStore::Phrase do
    sequence :key, 'aaaa'
    repo_name 'foobar_repo'
    sequence :commit_id, 'aaaa'
    sequence :file do |n|
      "file#{n}.#{%w(yml rb txt).sample}"
    end

    trait :with_meta_key do
      sequence :meta_key, 'aaaa'
    end
  end
end
