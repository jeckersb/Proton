#--
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
#++

module Qpid::Proton::Util

  # @private
  module Wrapper

    EMPTY_ATTRS = Hash.new

    attr_reader :dict
    attr_reader :impl

    class << EMPTY_ATTRS
      def []=(key, value)
        raise TypeError.new("does not support item assignment");
      end

      def [](key)
        raise KeyError.new(key)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def proton_attributes
        @proton_attributes ||= {}
        @proton_attributes
      end

      def proton_attr(name, options = {})
        setter = "#{name}="
        getter = "#{name}"

        define_method setter do |value|
          self.instance_variable_set("@#{name}", value)
          proton_save_state
        end

        define_method getter do
          self.instance_variable_get("@#{name}")
        end

        proton_attributes["--proton_defaults"] ||= {}
        proton_attributes["--proton_defaults"][name] = options[:default]
      end

    end

    def proton_load_state
      state = @dict[:attrs]
      # if we have no state for this instance then load state from
      # the class and its parents
      if state.nil? || state.empty?
        state = {}
        done = false
        clazz = self.class
        while clazz.respond_to? :proton_attributes
          attrs = clazz.proton_attributes["--proton_defaults"]
          state.merge!(attrs) unless attrs.nil?
          clazz = clazz.superclass
        end
        @dict[:attrs] = state
      end
      if !state.nil?
        state.each_pair do |varname, varvalue|
          if varvalue.is_a? Proc
            value = varvalue.call(self)
            instance_variable_set("@#{varname}", value)
          else
            instance_variable_set("@#{varname}", varvalue)
          end
        end
      end
    end

    def proton_save_state
      state = {}
      instance_variables.each do |varname|
        state[varname] = instance_variable_get(varname)
      end
      dict[:attrs] = state
    end

    def get_context(context_method = nil)
      if context_method.nil?
        attrs = EMPTY_ATTRS
      else
        record = Cproton.send(context_method, @impl)
        attrs = Cproton.pn_void2rb(Cproton.pn_record_get(record, RBCTX))
        if attrs.nil?
          attrs = {}
          Cproton.pn_record_def(record, RBCTX, Cproton.PN_RBREF)
          Cproton.pn_record_set(record, RBCTX, Cproton.pn_rb2void(attrs))
        end
      end
      @dict = {}
      @dict[:impl] = @impl
      @dict[:attrs] = attrs
      proton_load_state
    end

  end

  # @private
  RBCTX = 39212544 # Wrapper.hash.to_i

end
