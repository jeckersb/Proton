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

  # A Delivery maintains detail on the delivery of data to an endpoint.
  #
  # A Delivery has a single parent Qpid::Proton::Link
  #
  # @example
  #
  #   # SCENARIO: An event comes in notifying that data has been delivered to
  #   #           the local endpoint. A Delivery object can be used to check
  #   #           the details of the delivery.
  #
  #   delivery = @event.delivery
  #   if delivery.readable? && !delivery.partial?
  #     # decode the incoming message
  #     msg = Qpid::Proton::Message.new
  #     msg.decode(link.receive(delivery.pending))
  #   end
  #
  class Delivery

    # @private
    include Util::Wrapper

    proton_attr :local, :default => proc {|obj| Disposition.new(Cproton.pn_delivery_local(obj.impl), true)}
    proton_attr :remote, :default => proc {|obj| Disposition.new(Cproton.pn_delivery_remote(obj.impl), false)}

    # @private
    def self.wrap(impl) # :nodoc:
      return nil if impl.nil?
      Delivery.new(impl)
    end

    # @private
    def initialize(impl) # :nodoc:
      @impl = impl
      get_context(:pn_delivery_attachments)
    end

    # @private
    include Util::SwigHelper

    # @private
    PROTON_METHOD_PREFIX = "pn_delivery"

    # @!attribute [r] tag
    #
    # @return [String] The tag for the delivery.
    #
    proton_caller :tag

    # @!attribute [r] writable?
    #
    # A delivery is considered writable if it is the current delivery on an
    # outgoing link, and the link has positive credit.
    #
    # @return [Boolean] Returns if a delivery is writable.
    #
    proton_caller :writable?

    # @!attribute [r] readable?
    #
    # A delivery is considered readable if it is the current delivery on an
    # incoming link.
    #
    # @return [Boolean] Returns if a delivery is readable.
    #
    proton_caller :readable?
    # @!attribute [r] updated?
    #
    # A delivery is considered updated whenever the peer communicates a new
    # disposition for the dlievery. Once a delivery becomes updated, it will
    # remain so until cleared.
    #
    # @return [Boolean] Returns if a delivery is updated.
    #
    # @see #clear
    #
    proton_caller :updated?

    # @!method update
    #
    # Update the disposition of a delivery.
    #
    # When update is invoked, the updated disposition of the delivery will be
    # communited to the peer.
    #
    proton_caller :update

    # @!method clear
    #
    # Clear the updated flag for a delivery.
    #
    proton_caller :clear

    # @!attribute [r] pending
    #
    # @return [Fixnum] Return the amount of pending message data for the
    # delivery.
    #
    proton_caller :pending

    # @!attribute [r] partial?
    #
    # @return [Boolean] Returns if the delivery has only partial message data.
    #
    proton_caller :partial?

    # @!attribute [r] settled?
    #
    # @return [Boolean] Returns if the delivery is remotely settled.
    #
    proton_caller :settled?


    # @!method settle
    #
    # Settles a delivery.
    #
    #  A settled delivery can never be used again.
    #
    proton_caller :settle

    # @!method dump
    #
    #  Utility function for printing details of a delivery.
    #
    proton_caller :dump

    # @!attribute [r] buffered?
    #
    # A delivery that is buffered has not yet been written to the wire.
    #
    # Note that returning false does not imply that a delivery was definitely
    # written to the wire. If false is returned, it is not known whether the
    # delivery was actually written to the wire or not.
    #
    # @return [Boolean] Returns if the delivery is buffered.
    #
    proton_caller :buffered?

    include Util::Engine

    def update(state)
      impl = @local.impl
      object_to_data(self.local.data, Cproton.pn_disposition_data(impl))
      object_to_data(self.local.annotations, Cproton.pn_disposition_annotations(impl))
      object_to_data(self.local.condition, Cproton.pn_disposition_condition(impl))
      Cproton.pn_delivery_update(@impl, state)
    end

    # Returns the local disposition state for the delivery.
    #
    # @return [Disposition] The local disposition state.
    #
    def local_state
      Disposition.by_value(Cproton.pn_delivery_local_state(@impl))
    end

    # Returns the remote disposition state for the delivery.
    #
    # @return [Disposition] The remote disposition state.
    #
    def remote_state
      Disposition.by_value(Cproton.pn_delivery_remote_state(@impl))
    end

    # Returns the next delivery on the connection that has pending operations.
    #
    # @return [Delivery, nil] The next delivery, or nil if there are none.
    #
    # @see Connection#work_head
    #
    def work_next
      Delivery.wrap(Cproton.pn_work_next(@impl))
    end

    # Returns the parent link.
    #
    # @return [Link] The parent link.
    #
    def link
      Link.wrap(Cproton.pn_delivery_link(@impl))
    end

    # Returns the parent session.
    #
    # @return [Session] The session.
    #
    def session
      self.link.session
    end

    # Returns the parent connection.
    #
    # @return [Connection] The connection.
    #
    def connection
      self.session.connection
    end

    # Returns the parent transport.
    #
    # @return [Transport] The transport.
    #
    def transport
      self.conneciton.transport
    end

    # @private
    def received?(delivery)
      delivery.state == Disposition::RECEIVED
    end

    # @private
    def accepted?(delivery)
      delivery.state == Disposition::ACCEPTED
    end

    # @private
    def rejected?(delivery)
      delivery.state == Disposition::REJECTED
    end

    # @private
    def released?(delivery)
      delivery.state == Disposition::RELEASED
    end

    # @private
    def modified?(delivery)
      delivery.state == Disposition::MODIFIED
    end

  end

end
