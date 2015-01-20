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

module Qpid::Proton

  # The sending endpoint.
  #
  # @see Receiver
  #
  class Sender < Link

    # @private
    include Util::ErrorHandler

    # @private
    can_raise_error :send, :error_class => Qpid::Proton::LinkError

    # Signals the availability of deliveries.
    #
    # @param n [Fixnum] The number of deliveries potentially available.
    #
    def offered(n)
      Cproton.pn_link_offered(@impl, n)
    end

    # Sends the specified data to the remote endpoint.
    #
    # @param bytes [String] The data to send.
    #
    # @return [Fixnum] The number of bytes sent.
    #
    def send(bytes)
      Cproton.pn_link_send(@impl, bytes)
    end

    def delivery_tag
      # if we haven't already defined a tag generator then do so now
      if !self.respond_to?(:tag_generator)
        self.tag_count = 0
        define_method(:tag_generator) do
          self.tag_count = @tag_count + 1
          self.tag_count
        end
      end
      self.next(self.tag_generator)
    end

  end

end
