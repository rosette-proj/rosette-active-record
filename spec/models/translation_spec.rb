# encoding: UTF-8

require 'spec_helper'

include Rosette::DataStores

describe ActiveRecordDataStore::Translation do
  describe 'validations' do
    [:translation, :phrase_id, :locale].each do |required_field|
      context "without a #{required_field}" do
        let(:translation) { build(:translation, required_field => nil) }

        it 'fails validation' do
          expect(translation.save).to eq(false)
          has_blank = translation.errors[required_field].include?("can't be blank")
          has_nil = translation.errors[required_field].include?("can't be nil")
          expect(has_blank || has_nil).to be_truthy
        end
      end
    end
  end
end
