# Copyright (C) 2009-2014 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo
  module View

    # Has behaviour for the collection view that triggers server messages.
    #
    # @since 2.0.0
    module Executable

      # Get a count of matching documents in the collection.
      #
      # @example Get the number of documents in the collection.
      #   collection_view.count
      #
      # @return [ Integer ] The document count.
      #
      # @since 2.0.0
      def count
        cmd = { :count => collection.name, :query => selector }
        cmd[:skip] = options[:skip] if options[:skip]
        cmd[:hint] = options[:hint] if options[:hint]
        cmd[:limit] = options[:limit] if options[:limit]
        database.command(cmd).n
      end

      # Get a list of distinct values for a specific field.
      #
      # @example Get the distinct values.
      #   collection_view.distinct('name')
      #
      # @param [ String, Symbol ] field The name of the field.
      #
      # @return [ Array<Object> ] The list of distinct values.
      #
      # @since 2.0.0
      def distinct(field)
        database.command(
          :distinct => collection.name,
          :key => field.to_s,
          :query => selector
        ).documents.first['values']
      end

      # Get the explain plan for the query.
      #
      # @example Get the explain plan for the query.
      #   view.explain
      #
      # @return [ Hash ] A single document with the explain plan.
      #
      # @since 2.0.0
      def explain
        explain_limit = limit || 0
        opts = options.merge(:limit => -explain_limit.abs, :explain => true)
        Collection.new(collection, selector, opts).first
      end

      # Remove documents from the collection.
      #
      # @example Remove multiple documents from the collection.
      #   collection_view.remove
      #
      # @example Remove a single document from the collection.
      #   collection_view.limit(1).remove
      #
      # @return [ Response ] The response from the database.
      #
      # @since 2.0.0
      def remove
        server = read.select_servers(cluster.servers).first
        Operation::Write::Delete.new(
          :deletes => [{ q: selector, limit: options[:limit] || 0 }],
          :db_name => collection.database.name,
          :coll_name => collection.name,
          :write_concern => collection.write_concern
        ).execute(server.context)
      end

      # Update documents in the collection.
      #
      # @example Update multiple documents in the collection.
      #   collection_view.update('$set' => { name: 'test' })
      #
      # @example Update a single document in the collection.
      #   collection_view.limit(1).update('$set' => { name: 'test' })
      #
      # @return [ Response ] The response from the database.
      #
      # @since 2.0.0
      def update(spec)
        server = read.select_servers(cluster.servers).first
        Operation::Write::Update.new(
          :updates => [{
            q: selector,
            u: spec,
            multi: (options[:limit] || 0) == 1 ? false : true,
            upsert: false
          }],
          :db_name => collection.database.name,
          :coll_name => collection.name,
          :write_concern => collection.write_concern
        ).execute(server.context)
      end
    end
  end
end
