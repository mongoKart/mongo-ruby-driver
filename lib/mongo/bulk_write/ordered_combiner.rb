# Copyright (C) 2015 MongoDB, Inc.
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
  class BulkWrite

    # Combines groups of bulk write operations in order.
    #
    # @api private
    #
    # @since 2.1.0
    class OrderedCombiner

      # @return [ Array<Hash, BSON::Document> ] requests The provided requests.
      attr_reader :requests

      # Create the ordered combiner.
      #
      # @api private
      #
      # @example Create the ordered combiner.
      #   OrderedCombiner.new([{ insert_one: { _id: 0 }}])
      #
      # @param [ Array<Hash, BSON::Document> ] requests The bulk requests.
      #
      # @since 2.1.0
      def initialize(requests)
        @requests = requests
      end

      # Combine the requests in order.
      #
      # @api private
      #
      # @example Combine the requests.
      #   combiner.combine
      #
      # @return [ Array<Hash> ] The combined requests.
      #
      # @since 2.1.0
      def combine
        requests.reduce([]) do |operations, request|
          add(operations, convert(request.keys.first), request.values.first)
        end
      end

      private

      def add(operations, name, document)
        operations.push({ name => []}) if next_group?(name, operations)
        operations[-1][name].concat(process(name, document))
        operations
      end

      def convert(name)
        name == BulkWrite::INSERT_ONE ? BulkWrite::INSERT_MANY : name
      end

      def next_group?(name, operations)
        !operations[-1] || !operations[-1].key?(name)
      end

      def process(name, document)
        document.respond_to?(:to_ary) ? document.to_ary : [ validate(name, document) ]
      end

      def validate(name, document)
        if document.respond_to?(:keys)
          document
        else
          raise Error::InvalidBulkOperation.new(name, document)
        end
      end
    end
  end
end
