# encoding: UTF-8

FactoryGirl.define do
  factory :translation, class: Rosette::DataStores::ActiveRecordDataStore::Translation do
    phrase
    sequence :translation, 'aaaa'
    locale { %w(es it pt ko ja).sample }
  end
end
