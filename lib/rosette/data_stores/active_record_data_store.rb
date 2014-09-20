# encoding: UTF-8

require 'active_record'
require 'rosette/core'
require 'rosette/data_stores'
require 'rosette/data_stores/active_record/models'

module Rosette
  module DataStores

    class ActiveRecordDataStore
      CHUNK_SIZE = 20

      def initialize(connection_options = {})
        ActiveRecord::Base.establish_connection(
          connection_options
        )
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
            yield(
              phrase_model.where(repo_name: repo_name).where(
                phrases_by_commit_arr(commit_id_map)
              )
            )
          else
            each_phrase_condition_slice(commit_id_map).flat_map do |conditions|
              yield phrase_model.where(repo_name: repo_name).where(conditions)
            end
          end
        else
          to_enum(__method__, repo_name, commit_id_map)
        end
      end

      def translations_by_commits(repo_name, commit_id_map)
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
              .order(:updated_at)
              .reverse_order
              .group(:locale)

            yield trans
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

      def add_translation(repo_name, params = {})
        phrase = lookup_phrase(
          repo_name, params[:key], params[:meta_key], params[:commit_id]
        )

        if phrase
          find_params = trans_model
            .extract_params_from(params)
            .merge(phrase_id: phrase.id)

          trans = trans_model.new(find_params)

          unless trans.save
            raise AddTranslationError, trans.errors.full_messages.first
          end
        else
          raise(
            PhraseNotFoundError,
            "couldn't find phrase identified by key '#{params[:key]}' and meta key '#{params[:meta_key]}'"
          )
        end
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
    end

  end
end
