# encoding: UTF-8

require 'thread'
require 'active_record'
require 'rosette/core'
require 'rosette/data_stores'
require 'rosette/data_stores/phrase_status'
require 'rosette/data_stores/active_record/models'

module Rosette
  module DataStores

    class ActiveRecordDataStore
      CHUNK_SIZE = 100

      def initialize(connection_options = {})
        if connection_options
          ActiveRecord::Base.establish_connection(
            connection_options
          )
        end

        @@mutex = Mutex.new
      end

      def store_phrase(repo_name, phrase)
        with_connection do
          phrase = phrase_model.where(
            repo_name: repo_name,
            key: phrase.key,
            meta_key: phrase.meta_key,
            file: phrase.file,
            commit_id: phrase.commit_id,
            author_name: phrase.author_name,
            author_email: phrase.author_email,
            line_number: phrase.line_number
          ).first_or_initialize
          phrase.save
        end
      end

      def phrases_by_commit(repo_name, commit_id, file = nil)
        # Rather than create a bunch of Rosette::Core::Phrases, just return
        # the ActiveRecord objects, which respond to the same methods.
        with_connection do
          params = { repo_name: repo_name, commit_id: commit_id }
          params[:file] = file if file
          phrase_model.where(params).to_a
        end
      end

      # commit_id_map is a hash of commit_ids to file paths
      def phrases_by_commits(repo_name, commit_id_map)
        with_connection do
          if block_given?
            if commit_id_map.is_a?(Array)
              query = phrase_model.where(repo_name: repo_name).where(
                phrases_by_commit_arr(commit_id_map)
              )

              query.each { |phrase| yield phrase }
            else
              each_phrase_condition_slice(commit_id_map).flat_map do |conditions|
                phrase_model.where(repo_name: repo_name).where(conditions).each do |phrase|
                  yield phrase
                end
              end
            end
          else
            to_enum(__method__, repo_name, commit_id_map)
          end
        end
      end

      def translations_by_commits(repo_name, locale, commit_id_map)
        with_connection do
          if block_given?
            each_phrase_condition_slice(commit_id_map) do |conditions|
              trans = trans_model
                .where(
                  trans_model[:phrase_id].in(
                    phrase_model
                      .select(:id)
                      .where(repo_name: repo_name)
                      .where(conditions)
                      .ast
                  )
                )
                .where(locale: locale)
                # .order(:updated_at)  # why are these here?
                # .reverse_order

              trans.each { |t| yield t }
            end
          else
            to_enum(__method__, repo_name, locale, commit_id_map)
          end
        end
      end

      # NOTE: commit_id can be an array of commit ids
      def lookup_phrase(repo_name, key, meta_key, commit_id)
        with_connection do
          phrase_model.lookup(key, meta_key)
            .where(commit_id: commit_id)
            .where(repo_name: repo_name)
            .first
        end
      end

      # Params must include key or meta_key, commit_id, translation, and locale.
      # NOTE: commit_id can be an array of commit ids.
      def add_or_update_translation(repo_name, params = {})
        with_connection do
          required_params = [
            phrase_model.index_key(params[:key], params[:meta_key]),
            :commit_id, :translation, :locale
          ]

          missing_params = required_params - params.keys

          if missing_params.size > 0
            raise Rosette::DataStores::Errors::MissingParamError,
              "missing params: #{missing_params.join(', ')}"
          end

          phrases = phrase_model.lookup(params[:key], params[:meta_key])
            .where(commit_id: Array(params[:commit_id]))
            .where(repo_name: repo_name)

          phrases.each do |phrase|
            params = trans_model
              .extract_params_from(params)
              .merge(phrase_id: phrase.id)

            find_params = params.dup
            find_params.delete(:translation)  # may have changed

            trans = trans_model.where(find_params)
            trans << trans_model.new if trans.size == 0

            trans.map do |t|
              t.assign_attributes(params)

              unless t.save
                raise(
                  Rosette::DataStores::Errors::AddTranslationError,
                  t.errors.full_messages.join(', ')
                )
              end
            end
          end
        end
      end

      def each_unique_commit(repo_name)
        with_connection do
          if block_given?
            # ActiveRecord's find_in_batches will occasionally yield a commit_id we've
            # already seen because there are numerous entries with the same commit_id.
            # They overlap when queried in batches.
            seen_ids = Set.new
            query = phrase_model.select([:commit_id, :id])
              .where(repo_name: repo_name)
              .group(:commit_id)

            query.find_in_batches(batch_size: CHUNK_SIZE) do |batch|
              batch.each do |entry|
                unless seen_ids.include?(entry.commit_id)
                  yield entry.commit_id
                end

                seen_ids << entry.commit_id
              end
            end
          else
            to_enum(__method__, repo_name)
          end
        end
      end

      def each_unique_meta_key(repo_name)
        with_connection do
          if block_given?
            query = phrase_model
              .select([:id, :meta_key])
              .where(repo_name: repo_name)
              .group(:meta_key)
              .pluck(:meta_key)
              .each { |mk| yield mk }
          else
            to_enum(__method__, repo_name)
          end
        end
      end

      def most_recent_key_for_meta_key(repo_name, meta_key)
        with_connection do
          phrase_model
            .select(phrase_model.arel_table[:key])
            .joins(
              phrase_model.arel_table.join(commit_log_model.arel_table).on(
                phrase_model.arel_table[:commit_id].eq(commit_log_model.arel_table[:commit_id])
              ).join_sources
            )
            .where(repo_name: repo_name, meta_key: meta_key)
            .order(:commit_datetime)
            .reverse_order
            .first
            .key
        end
      end

      def unique_commit_count(repo_name)
        with_connection do
          count = Arel::Nodes::NamedFunction.new(
            'COUNT', [Arel::Nodes::NamedFunction.new(
                'DISTINCT', [phrase_model[:commit_id]]
              )
            ]
          )

          phrase_model
            .select(count.as('commit_count'))
            .where(repo_name: repo_name)
            .first
            .attributes['commit_count']
          end
      end

      def add_or_update_commit_log(repo_name, commit_id, commit_datetime = nil, status = Rosette::DataStores::PhraseStatus::UNTRANSLATED, phrase_count = nil)
        with_connection do
          log_entry = commit_log_model
            .where(repo_name: repo_name, commit_id: commit_id)
            .first_or_initialize

          log_entry.assign_attributes(status: status)
          log_entry.assign_attributes(commit_datetime: commit_datetime) if commit_datetime
          log_entry.assign_attributes(phrase_count: phrase_count) if phrase_count

          unless log_entry.save
            raise Rosette::DataStores::Errors::CommitLogUpdateError,
              "Unable to update commit #{commit_id}: #{log_entry.errors.full_messages.first}"
          end
        end
      end

      # status can be an array of statuses
      def each_commit_log_with_status(repo_name, status, &blk)
        if block_given?
          with_connection do
            commit_log_model.where(status: status, repo_name: repo_name)
              .find_each(batch_size: CHUNK_SIZE, &blk)
          end
        else
          to_enum(__method__, repo_name, status)
        end
      end

      def commit_log_with_status_count(repo_name, status)
        with_connection do
          commit_log_model.where(status: status, repo_name: repo_name).count
        end
      end

      def commit_log_exists?(repo_name, commit_id)
        with_connection do
          commit_log_model.where(repo_name: repo_name, commit_id: commit_id).exists?
        end
      end

      def seen_commits_in(repo_name, commit_id_list)
        with_connection do
          commit_log_model
            .where(repo_name: repo_name)
            .where(commit_id: commit_id_list)
            .pluck(:commit_id)
          end
      end

      def add_or_update_commit_log_locale(commit_id, locale, translated_count)
        with_connection do
          commit_log_locale_entry = commit_log_locale_model
            .where(commit_id: commit_id)
            .where(locale: locale)
            .first_or_initialize

          commit_log_locale_entry.assign_attributes(translated_count: translated_count)

          unless commit_log_locale_entry.save
            raise Rosette::DataStores::Errors::CommitLogLocaleUpdateError,
              "Unable to update commit log locale #{commit_id} #{locale}: #{commit_log_locale_entry.errors.full_messages.first}"
          end
        end
      end

      def commit_log_status(repo_name, commit_id)
        with_connection do
          log_entry = commit_log_model
            .where(repo_name: repo_name, commit_id: commit_id)
            .includes(:commit_log_locales)
            .first

          if log_entry
            phrase_count = log_entry.phrase_count.to_i

            locales = log_entry.commit_log_locales.map do |log_locale|
              translated_count = log_locale[:translated_count].to_i

              {
                locale: log_locale[:locale],
                percent_translated: percentage(translated_count, phrase_count),
                translated_count: translated_count,
              }
            end

            {
              commit_id: commit_id,
              status: log_entry.status,
              phrase_count: phrase_count,
              locales: locales
            }
          end
        end
      end

      def file_list_for_repo(repo_name)
        with_connection do
          Phrase
            .where(repo_name: repo_name)
            .uniq
            .pluck(:file)
        end
      end

      private

      def percentage(dividend, divisor)
        if divisor > 0
          (dividend.to_f / divisor.to_f).round(2)
        else
          0.0
        end
      end

      def with_connection(&block)
        ActiveRecord::Base.connection_pool.with_connection(&block)
      end

      def phrases_by_commit_arr(arr)
        phrase_model[:commit_id].in(commit_id_map.keys)
      end

      # slices up the commit map into manageable chunks and constructs
      # arel queries for each chunk
      def each_phrase_condition_slice(commit_id_map)
        if block_given?
          each_phrase_slice(commit_id_map, CHUNK_SIZE) do |slice|
            conditions = slice.map do |file, commit_id|
              pair = phrase_model[:file].eq(file).and(phrase_model[:commit_id].eq(commit_id))
              "(#{pair.to_sql})"
            end

            yield conditions.join(' OR ')
          end
        else
          to_enum(__method__, commit_id_map)
        end
      end

      # slices and yields chunks of a hash (like Enumerable#each_slice, but maybe more efficient)
      def each_phrase_slice(hash, size)
        if block_given?
          remaining = hash.each_with_index.inject({}) do |ret, ((key, val), idx)|
            if idx > 0 && idx % size == 0
              yield ret
              {}
            else
              ret[key] = val
              ret
            end
          end

          yield remaining if remaining.size > 0
        else
          to_enum(__method__, hash, size)
        end
      end

      def phrase_model
        self.class::Phrase
      end

      def trans_model
        self.class::Translation
      end

      def commit_log_model
        self.class::CommitLog
      end

      def commit_log_locale_model
        self.class::CommitLogLocale
      end
    end

  end
end
