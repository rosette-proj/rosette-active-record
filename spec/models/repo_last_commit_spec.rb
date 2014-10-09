# encoding: UTF-8

require 'spec_helper'

include Rosette::DataStores

describe ActiveRecordDataStore::RepoLastCommit do
  describe 'validations' do
    [:repo_name, :last_commit_id].each do |required_field|
      context "without a #{required_field}" do
        let(:repo_last_commit) { build(:repo_last_commit, required_field => nil) }

        it 'fails validation' do
          expect(repo_last_commit.save).to eq(false)
          expect(repo_last_commit.errors[required_field]).to include("can't be blank")
        end
      end
    end
  end
end
