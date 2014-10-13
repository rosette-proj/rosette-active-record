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
      CHUNK_SIZE = 20

      def initialize(connection_options = {})
        if connection_options
          ActiveRecord::Base.establish_connection(
            connection_options
          )
        end

        @@mutex = Mutex.new
      end

      def store_phrase(repo_name, phrase)
        phrase = phrase_model.where(
          repo_name: repo_name,
          key: phrase.key,
          meta_key: phrase.meta_key,
          file: phrase.file,
          commit_id: phrase.commit_id
        ).first_or_initialize
        phrase.save
      end

      def phrases_by_commit(repo_name, commit_id, file = nil)
        # Rather than create a bunch of Rosette::Core::Phrases, just return
        # the ActiveRecord objects, which respond to the same methods.
        params = { repo_name: repo_name, commit_id: commit_id }
        params[:file] = file if file
        phrase_model.where(params)
      end

      # commit_id_map is a hash of commit_ids to file paths
      def phrases_by_commits(repo_name, commit_id_map)
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

      def translations_by_commits(repo_name, locale, commit_id_map)
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
          to_enum(__method__, repo_name, commit_id_map)
        end
      end

      def lookup_phrase(repo_name, key, meta_key, commit_id)
        phrase_model.lookup(key, meta_key)
          .where(commit_id: commit_id)
          .where(repo_name: repo_name)
          .first
      end

      # params must include key or meta_key, commit_id, translation, and locale
      def add_or_update_translation(repo_name, params = {})
        required_params = [
          phrase_model.index_key(params[:key], params[:meta_key]),
          :commit_id, :translation, :locale
        ]

        missing_params = required_params - params.keys

        if missing_params.size > 0
          raise Rosette::DataStores::Errors::MissingParamError,
            "missing params: #{missing_params.join(', ')}"
        end

        phrase = lookup_phrase(
          repo_name, params[:key], params[:meta_key], params[:commit_id]
        )

        if phrase
          params = trans_model
            .extract_params_from(params)
            .merge(phrase_id: phrase.id)

          find_params = params.dup
          find_params.delete(:translation)  # may have changed

          trans = trans_model.where(find_params)
          trans << trans_model.new if trans.size == 0

          trans.each do |t|
            t.assign_attributes(params)

            unless t.save
              raise(
                Rosette::DataStores::Errors::AddTranslationError,
                t.errors.full_messages.join(', ')
              )
            end
          end
        else
          raise(
            Rosette::DataStores::Errors::PhraseNotFoundError,
            "couldn't find phrase identified by key '#{params[:key]}' and meta key '#{params[:meta_key]}'"
          )
        end
      end

      def each_unique_commit(repo_name)
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

      def unique_commit_count(repo_name)
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

      def add_or_update_commit_log(repo_name, commit_id, status = Rosette::DataStores::PhraseStatus::UNTRANSLATED)
        log_entry = commit_log
          .where(repo_name: repo_name, commit_id: commit_id)
          .first_or_initialize

        log_entry.assign_attributes(status: status)

        unless log_entry.save
          raise Rosette::DataStores::Errors::CommitLogUpdateError,
            "Unable to update commit #{commit_id}: #{log_entry.errors.full_messages.first}"
        end
      end

      def seen_commits_in(repo_name, commit_id_list)
        commit_log
          .where(repo_name: repo_name)
          .where(commit_id: commit_id_list)
          .pluck(:commit_id)
      end

      private

      def phrases_by_commit_arr(arr)
        phrase_model[:commit_id].in(commit_id_map.keys)
      end

      # slices up the commit map into manageable chunks and constructs
      # arel queries for each chunk
      def each_phrase_condition_slice(commit_id_map)
        if block_given?
          each_phrase_slice(commit_id_map, CHUNK_SIZE) do |slice|
            conditions = slice.inject(nil) do |rel, (file, commit_id)|
              pair = phrase_model[:file].eq(file).and(phrase_model[:commit_id].eq(commit_id))
              rel ? rel.or(pair) : pair
            end

            yield conditions
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

      def commit_log
        self.class::CommitLog
      end
    end

  end
end
