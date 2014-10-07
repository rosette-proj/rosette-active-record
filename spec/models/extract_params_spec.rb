# encoding: UTF-8

require 'spec_helper'

include Rosette::DataStores

describe ActiveRecordDataStore::ExtractParams do
  it "filters out parameters that aren't columns on the model" do
    filtered_params = Phrase.extract_params_from(key: 'foobar', bad: 'mwhahahaha')
    expect(filtered_params).to include(:key)
    expect(filtered_params).to_not include(:bad)
    expect(filtered_params[:key]).to eq('foobar')
  end
end
