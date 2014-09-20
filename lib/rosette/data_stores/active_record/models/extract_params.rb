# encoding: UTF-8

module Rosette
  module DataStores
    class ActiveRecordDataStore

      module ExtractParams
        def extract_params_from(params = {})
          columns.each_with_object({}) do |column, ret|
            column_sym = column.name.to_sym

            if params.include?(column_sym)
              ret[column_sym] = params[column_sym]
            end
          end
        end
      end

    end
  end
end
