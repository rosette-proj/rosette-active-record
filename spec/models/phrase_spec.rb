# encoding: UTF-8

require 'spec_helper'

include Rosette::DataStores

describe ActiveRecordDataStore::Phrase do
  describe 'validations' do
    [:key, :repo_name, :key, :file, :commit_id].each do |required_field|
      context "without a #{required_field}" do
        let(:phrase) { build(:phrase, required_field => nil) }

        it 'fails validation' do
          expect(phrase.save).to eq(false)
          expect(phrase.errors[required_field]).to include("can't be blank")
        end
      end
    end
  end

  describe '#lookup' do
    it 'uses the phrase index policy to find the correct phrase by key' do
      phrase = create(:phrase)
      Phrase.lookup(phrase.key, nil).first.tap do |found_phrase|
        expect(found_phrase.id).to eq(phrase.id)
      end
    end

    it 'uses the phrase index policy to find the correct phrase by meta_key' do
      phrase = create(:phrase, :with_meta_key)
      Phrase.lookup(nil, phrase.meta_key).first.tap do |found_phrase|
        expect(found_phrase.id).to eq(phrase.id)
      end
    end
  end
end
