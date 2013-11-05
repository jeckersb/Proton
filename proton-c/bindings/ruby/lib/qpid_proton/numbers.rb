#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

module Qpid

  module Proton

    class ProtonNumeric # :nodoc:

      attr_reader :amqp_type

      def initialize(value, amqp_type)
        @value = value
        @amqp_type = amqp_type
      end

      def self.use_binary_operator(operator)
        eval "def #{operator}(other); @value #{operator} other; end"
      end

      def self.use_unary_operator(operator)
        eval "def #{operator}; @value.#{operator}; end"
      end

      def self.use_method(name, opts = {})
        definition = "def #{name.to_s}"
        args = ""
        if(opts[:args] && opts[:args] > 0)
          args = "("
          (1..opts[:args]).each do |which|
            defval = ""
            defval = "=nil" if opts[:required].nil? || which > opts[:required]
            args = "#{args}#{which > 1 ? ',' : ''}arg#{which}#{defval}"
          end
          args = "#{args})"
        end
        definition = "#{definition}#{args}; @value.#{name.to_s}#{args}; end"
        eval definition
      end

    end

    class ProtonFixnum < ProtonNumeric # :nodoc:

      use_unary_operator "~"
      use_unary_operator "-@"

      use_binary_operator "%"
      use_binary_operator "&"
      use_binary_operator "*"
      use_binary_operator "**"
      use_binary_operator "+"
      use_binary_operator "-"
      use_binary_operator "/"
      use_binary_operator "<"
      use_binary_operator "<<"
      use_binary_operator "<="
      use_binary_operator "<=>"
      use_binary_operator "=="
      use_binary_operator ">"
      use_binary_operator "|"

      use_method :abs
      use_method :div, :args => 1
      use_method :divmod, :args => 1
      use_method :even?
      use_method :fdiv, :args => 1
      use_method :magnitude
      use_method :modulo, :args => 1
      use_method :odd?
      use_method :size
      use_method :succ
      use_method :to_f
      use_method :zero?

      def coerce(other)
        case other
          when Integer
          begin
            return other, Integer(@value)
          rescue
            return Float(other), Float(@value)
          end

          when Float
          return other, Float(@value)

        else super
        end
      end

      def eql?(other)
        @value.eql? other
      end

      def to_s
        @value.to_s
      end

    end

    class ProtonFloat < ProtonNumeric # :nodoc:

      use_unary_operator "-@"

      use_binary_operator "%"
      use_binary_operator "*"
      use_binary_operator "**"
      use_binary_operator "+"
      use_binary_operator "-"
      use_binary_operator "/"
      use_binary_operator "<"
      use_binary_operator "<="
      use_binary_operator "<=>"
      use_binary_operator "=="
      use_binary_operator ">"
      use_binary_operator ">="

      use_method :abs
      use_method :ceil
      use_method :divmod, :args => 1
      use_method :fdiv, :args => 1
      use_method :finite?
      use_method :floor
      use_method :hash
      use_method :infinite?
      use_method :magnitude
      use_method :modulo, :args => 1
      use_method :nan?
      use_method :quo, :args => 1
      use_method :round, :args => 1, :required => 0
      use_method :to_f
      use_method :to_i
      use_method :to_int
      use_method :truncate
      use_method :zero?
    end

    def coerce(other)
        case other
          when Integer
          begin
            return Float(other), @value
          rescue
            return Float(other), Float(@value)
          end

          when Float
          return other, @value
        else super
        end
    end

      def eql?(other)
        @value.eql? other
      end

    def to_s
      @value.to_s
    end

  end

end
