# encoding: UTF-8

require 'spec_helper'

include Rosette::DataStores

describe ActiveRecordDataStore do
  let(:datastore) { ActiveRecordDataStore.new(nil) }
  let(:repo_name) { 'foobar_repo' }

  def build_commit_id_map_from(phrase_arr)
    phrase_arr.each_with_object({}) do |phrase, ret|
      ret[phrase.file] = phrase.commit_id
    end
  end

  describe '#store_phrase' do
    it 'creates a phrase in the database' do
      phrase = build(:phrase)
      expect(Phrase.count).to eq(0)
      datastore.store_phrase(repo_name, phrase)
      expect(Phrase.count).to eq(1)

      Phrase.first.tap do |found_phrase|
        expect(found_phrase.id).to_not be_nil
        expect(found_phrase.key).to eq(phrase.key)
        expect(found_phrase.commit_id).to eq(phrase.commit_id)
        expect(found_phrase.file).to eq(phrase.file)
        expect(found_phrase.repo_name).to eq(phrase.repo_name)
      end
    end
  end

  describe '#phrases_by_commit' do
    it 'returns an array of phrases for the given commit' do
      phrases = create_list(:phrase, 5, commit_id: 'abc123')

      datastore.phrases_by_commit(repo_name, 'abc123').tap do |found_phrases|
        phrases.each do |phrase|
          found_phrase = found_phrases.find do |found_phrase|
            found_phrase.id == phrase.id
          end

          expect(found_phrase.key).to eq(phrase.key)
          expect(found_phrase.file).to eq(phrase.file)
          expect(found_phrase.commit_id).to eq('abc123')
        end
      end
    end

    it 'returns an array of phrases that also match the given file' do
      phrases_with_right_file = create_list(:phrase, 2, {
        commit_id: 'abc123', file: 'right_file.txt'
      })

      phrases_with_wrong_file = create_list(:phrase, 3, {
        commit_id: 'abc123', file: 'wrong_file.txt'
      })

      datastore.phrases_by_commit(repo_name, 'abc123', 'right_file.txt').tap do |found_phrases|
        expect(found_phrases.map(&:id)).to(
          eq(phrases_with_right_file.map(&:id))
        )
      end
    end
  end

  describe '#phrases_by_commits' do
    it 'returns an array of phrases that match the file and commit_id pairs in the map' do
      phrases = create_list(:phrase, 5, commit_id: 'abc123')
      commit_id_map = build_commit_id_map_from(phrases)

      datastore.phrases_by_commits(repo_name, commit_id_map) do |found_phrase|
        phrase = phrases.find { |p| p.id == found_phrase.id }
        expect(phrase).to_not be_nil
        expect(phrase.file).to eq(found_phrase.file)
        expect(phrase.commit_id).to eq(found_phrase.commit_id)
        phrases.delete(phrase)
      end

      expect(phrases.size).to eq(0)
    end
  end

  describe '#translations_by_commits' do
    it 'returns an array of translations whose phrases match the file and commit_id pairs in the map' do
      translations = create_list(:translation, 5, locale: 'es')
      commit_id_map = build_commit_id_map_from(translations.map(&:phrase))

      datastore.translations_by_commits(repo_name, 'es', commit_id_map) do |found_trans|
        trans = translations.find { |t| t.id == found_trans.id }
        expect(trans).to_not be_nil
        expect(trans.phrase_id).to eq(found_trans.phrase_id)
        expect(trans.translation).to eq(found_trans.translation)
        expect(trans.locale).to eq('es')
        translations.delete(trans)
      end

      expect(translations.size).to eq(0)
    end
  end

  describe '#lookup_phrase' do
    it 'finds the phrase by key' do
      phrase_by_key = create(:phrase, key: 'foobar')
      found_phrase = datastore.lookup_phrase(
        repo_name, 'foobar', nil, phrase_by_key.commit_id
      )

      expect(found_phrase.id).to eq(phrase_by_key.id)
      expect(found_phrase.key).to eq(phrase_by_key.key)
      expect(found_phrase.meta_key).to be_nil
    end

    it 'finds the phrase by meta_key' do
      phrase_by_meta_key = create(:phrase, key: 'foo', meta_key: 'bar')
      found_phrase = datastore.lookup_phrase(
        repo_name, nil, 'bar', phrase_by_meta_key.commit_id
      )

      expect(found_phrase.id).to eq(phrase_by_meta_key.id)
      expect(found_phrase.key).to eq('foo')
      expect(found_phrase.meta_key).to eq('bar')
    end

    it "returns nil if the phrase can't be found" do
      found_phrase = datastore.lookup_phrase(repo_name, 'foo', 'bar', 'abc123')
      expect(found_phrase).to be_nil
    end
  end

  describe '#add_or_update_translation' do
    it 'raises an error if params are missing' do
      phrase = create(:phrase)
      all_params = {
        key: phrase.key,
        commit_id: phrase.commit_id,
        translation: 'new trans text',
        locale: 'es'
      }

      [:key, :commit_id, :translation, :locale].each do |missing_param|
        params = all_params.dup.tap { |p| p.delete(missing_param) }
        expect(
          lambda do
            datastore.add_or_update_translation(params)
          end
        ).to raise_error(Rosette::DataStores::Errors::MissingParamError)
      end
    end

    it "raises an error if the phrase can't be found" do
      expect(
        lambda do
          datastore.add_or_update_translation(
            repo_name, key: 'foo', locale: 'foo',
            commit_id: 'fake', translation: 'faketrans'
          )
        end
      ).to raise_error(Rosette::DataStores::Errors::PhraseNotFoundError)
    end

    it "raises an error if the model can't be saved" do
      phrase = create(:phrase)

      expect(
        lambda do
          # should fail validations
          datastore.add_or_update_translation(
            repo_name, key: phrase.key,
            commit_id: phrase.commit_id, locale: 'es',
            translation: nil
          )
        end
      ).to raise_error(Rosette::DataStores::Errors::AddTranslationError)
    end

    it 'replaces any existing translation text when phrase params match' do
      new_translation_text = 'other translation text'
      translation = create(:translation)

      params = {
        key: translation.phrase.key,
        commit_id: translation.phrase.commit_id,
        translation: new_translation_text,
        locale: translation.locale
      }

      datastore.add_or_update_translation(repo_name, params).tap do |translation_statuses|
        expect(translation_statuses.size).to eq(1)
        translation_statuses.first.tap do |translation_status|
          expect(translation_status[:status]).to eq(:changed)
          expect(translation_status[:translation].id).to eq(translation.id)
        end
      end

      expect(translation.reload.translation).to eq(new_translation_text)
    end

    it 'updates multiple translations if more than one translation is found' do
      new_translation_text = 'other translation text'
      translation = create(:translation)
      other_translation = create(:translation, {
        phrase_id: translation.phrase_id,
        locale: translation.locale
      })

      params = {
        key: translation.phrase.key,
        commit_id: translation.phrase.commit_id,
        translation: new_translation_text,
        locale: translation.locale
      }

      datastore.add_or_update_translation(repo_name, params).tap do |translation_statuses|
        expect(translation_statuses.size).to eq(2)

        translation_statuses.first.tap do |translation_status|
          expect(translation_status[:status]).to eq(:changed)
          expect(translation_status[:translation].id).to eq(translation.id)
        end

        translation_statuses.last.tap do |translation_status|
          expect(translation_status[:status]).to eq(:changed)
          expect(translation_status[:translation].id).to eq(other_translation.id)
        end
      end

      expect(translation.reload.translation).to eq(new_translation_text)
      expect(other_translation.reload.translation).to eq(new_translation_text)
    end

    it 'creates a new translation' do
      new_translation_text = "I'm a little teapot"
      phrase = create(:phrase)

      params = {
        key: phrase.key,
        commit_id: phrase.commit_id,
        translation: new_translation_text,
        locale: 'es'
      }

      translation_statuses = nil

      expect do
        translation_statuses = datastore.add_or_update_translation(
          repo_name, params
        )
      end.to change { Translation.count }.by(1)

      first_trans = Translation.first
      expect(translation_statuses.size).to eq(1)
      expect(translation_statuses.first[:status]).to eq(:created)
      expect(translation_statuses.first[:translation].id).to eq(first_trans.id)

      expect(first_trans.phrase_id).to eq(phrase.id)
      expect(first_trans.translation).to eq(new_translation_text)
      expect(first_trans.locale).to eq('es')
    end

    it "doesn't update any translations" do
      translation = create(:translation)
      phrase = translation.phrase

      params = {
        key: phrase.key,
        commit_id: phrase.commit_id,
        translation: translation.translation,
        locale: translation.locale
      }

      datastore.add_or_update_translation(repo_name, params).tap do |translation_statuses|
        expect(translation_statuses.size).to eq(1)
        translation_statuses.first.tap do |translation_status|
          expect(translation_status[:status]).to eq(:unchanged)
          expect(translation_status[:translation].id).to eq(translation.id)
        end
      end
    end
  end

  describe '#each_unique_commit' do
    it 'yields once for each unique commit in the database' do
      commit_ids = create_list(:phrase, 3).map(&:commit_id)
      create(:phrase, commit_id: commit_ids.last)  # duplicate

      datastore.each_unique_commit(repo_name) do |commit_id|
        expect(commit_ids).to include(commit_id)
        commit_ids.delete(commit_id)
      end

      expect(commit_ids.size).to eq(0)
    end
  end

  describe '#unique_commit_count' do
    it 'returns the number of unique commits in the database' do
      commit_ids = create_list(:phrase, 3).map(&:commit_id)
      create(:phrase, commit_id: commit_ids.last)  # duplicate

      expect(Phrase.count).to eq(4)
      expect(datastore.unique_commit_count(repo_name)).to eq(3)
    end
  end

  describe '#add_or_update_commit_log' do
    let(:commit_id) { '4321' }

    context 'the commit has not been logged yet' do
      it 'creates a new commit log entry' do
        expect(CommitLog.count).to eq(0)
        datastore.add_or_update_commit_log(repo_name, commit_id)

        expect(CommitLog.count).to eq(1)
        CommitLog.first.tap do |log_entry|
          expect(log_entry.repo_name).to eq(repo_name)
          expect(log_entry.commit_id).to eq (commit_id)
          expect(log_entry.status).to eq(PhraseStatus::UNTRANSLATED)
        end
      end
    end

    context 'the commit has already been logged' do
      it 'updates the commit status' do
        create(:commit_log, commit_id: commit_id)

        expect do
          datastore.add_or_update_commit_log(repo_name, commit_id, nil, PhraseStatus::PENDING)
        end.to_not change { CommitLog.count }

        CommitLog.first.tap do |log_entry|
          expect(log_entry.repo_name).to eq(repo_name)
          expect(log_entry.commit_id).to eq(commit_id)
          expect(log_entry.status).to eq(PhraseStatus::PENDING)
        end
      end
    end
  end

  describe '#each_pending_commit_log' do
    it 'yields all pending commit logs' do
      create(:commit_log, status: PhraseStatus::UNTRANSLATED)
      pending_commit_log = create(:commit_log, status: PhraseStatus::PENDING)

      commit_logs = datastore.each_pending_commit_log(repo_name).to_a

      expect(commit_logs.size).to eq(1)
      expect(commit_logs.first.commit_id).to eq(pending_commit_log.commit_id)
    end
  end

  describe '#pending_commit_log_count' do
    it 'returns the count of pending commit logs' do
      create(:commit_log, status: PhraseStatus::UNTRANSLATED)
      create(:commit_log, status: PhraseStatus::PENDING)

      expect(datastore.pending_commit_log_count).to eq(1)
    end
  end

  describe '#commit_log_exists?' do
    it "returns false if the commit log doesn't exist" do
      expect(datastore.commit_log_exists?(repo_name, 'abc123')).to be(false)
    end

    it 'returns true if the commit log exists' do
      log_entry = create(:commit_log)
      expect(datastore.commit_log_exists?(repo_name, log_entry.commit_id)).to be(true)
    end
  end

  describe '#seen_commits_in' do
    it 'returns the commits in the list that are also in the commit log' do
      commits = create_list(:commit_log, 2)
      seen_commits = datastore.seen_commits_in(
        repo_name, [commits.first.commit_id, 'foobar']
      )

      expect(seen_commits.size).to eq(1)
      expect(seen_commits.first).to eq(commits.first.commit_id)
    end
  end

  describe '#add_or_update_commit_log_locale' do
    let(:commit_id) { 'beef123' }
    let(:locale) { 'es' }
    let(:translated_count) { 1000 }

    context 'the locale for the commit has not been logged yet' do
      it 'creates a commit log locale entry' do
        expect do
          datastore.add_or_update_commit_log_locale(commit_id, locale, translated_count)
        end.to change { CommitLogLocale.count }.by(1)

        CommitLogLocale.first.tap do |log_locale_entry|
          expect(log_locale_entry.commit_id).to eq(commit_id)
          expect(log_locale_entry.locale).to eq(locale)
          expect(log_locale_entry.translated_count).to eq(translated_count)
        end
      end
    end

    context 'the locale for the commit has already been logged' do
      it 'updates the commit log locale' do
        create(:commit_log_locale, locale: locale, translated_count: translated_count, commit_id: commit_id)

        expect do
          datastore.add_or_update_commit_log_locale(commit_id, locale, translated_count)
        end.to_not change { CommitLogLocale.count }

        CommitLogLocale.first.tap do |log_locale_entry|
          expect(log_locale_entry.commit_id).to eq(commit_id)
          expect(log_locale_entry.locale).to eq(locale)
          expect(log_locale_entry.translated_count).to eq(translated_count)
        end
      end
    end
  end

  describe '#commit_log_status' do
    let(:commit_id) { '43210' }
    let(:phrase_count) { 999 }
    let(:translated_count) { 333 }

    it 'returns the status of a commit from a repo' do
      commit_log = create(:commit_log, repo_name: repo_name, commit_id: commit_id, phrase_count: phrase_count)
      commit_log_locales = create_list(:commit_log_locale, 5, commit_log: commit_log, translated_count: translated_count)

      locales = commit_log_locales.map(&:locale)

      datastore.commit_log_status(repo_name, commit_id).tap do |status|
        expect(status[:commit_id]).to eq(commit_id)
        expect(status[:status]).to eq(PhraseStatus::UNTRANSLATED)
        expect(status[:phrase_count]).to eq(phrase_count)
        locales_hash = locales.map do |locale|
          {}.tap do |h|
            h[:locale] = locale
            h[:percent_translated] = (translated_count.to_f / phrase_count).round(2)
            h[:translated_count] = translated_count
          end
        end
        expect(sort_by_locale(status[:locales])).to eq(sort_by_locale(locales_hash))
      end

    end
  end

  describe '#file_list_for_repo' do
    let(:first_file_name) { 'cool_file.txt' }
    let(:second_file_name) { 'a_cooler_file.txt' }

    it 'returns the list of files for a repo' do
      create_list(:phrase, 5, repo_name: repo_name, file: first_file_name)
      create_list(:phrase, 5, repo_name: repo_name, file: second_file_name)

      expect(datastore.file_list_for_repo(repo_name).sort).to eq([first_file_name, second_file_name].sort)
    end
  end

  def sort_by_locale(locales_hash)
    locales_hash.sort { |a,b| a[:locale] <=> b[:locale] }
  end

end
