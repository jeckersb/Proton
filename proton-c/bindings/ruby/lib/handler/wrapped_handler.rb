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

module Qpid::Proton::Handler

  class WrappedHandler

    # @private
    include Qpid::Proton::Util::Wrapper

    def self.wrap(impl, on_error = nil)
      return nil if impl.nil?

      handler = WrappedHandler.new(impl)
      handler.instance_eval { @dict['on_error'] = on_error }
      return handler
    end

    include Qpid::Proton::Util::Handler

    def initialize(impl)
      @impl = impl
      get_context
      # We need to associate the lifespan of this handler with
      # the underlying C handler. In this way the Ruby-space
      # object should live for as long as the Swig wrapper,
      # which is as long as the underlying C struct, hopefully.
      @impl.instance_exec(self) do |parent|
        @wrapped_handler = parent
      end
    end

    def add(handler)
      return if handler.nil?

      impl = chandler(handler, self.method(:_on_error))
      Cproton.pn_handler_add(@impl, impl)
    end

    def clear
      Cproton.pn_handler_clear(@impl)
    end

    private

    def _on_error(info)
      if self.has?['on_error']
        self['on_error'].call(info)
      else
        raise info
      end
    end

  end

end
