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

  # The SASL layer is responsible for establishing an authenticated and/or
  # encrypted tunnel over which AMQP frames are passed between peers.
  #
  # The peer acting as the SASL client must provide authentication
  # credentials.
  #
  # The peer acting as the SASL server must provide authentication against the
  # received credentials.
  #
  # @example
  #   # SCENARIO: the remote endpoint has not initialized their connection
  #   #           then the local endpoint, acting as a SASL server, decides
  #   #           to allow an anonymous connection.
  #   #
  #   #           The SASL layer locally assumes the role of server and then
  #   #           enables anonymous authentication for the remote endpoint.
  #   #
  #   sasl = @transport.sasl
  #   sasl.server
  #   sasl.mechanisms("ANONYMOUS")
  #   sasl.done(Qpid::Proton::SASL::OK)
  #
  class SASL

    include Util::Wrapper

    # Negotation has not completed.
    NONE = Cproton::PN_SASL_NONE
    # Authentication succeeded.
    OK = Cproton::PN_SASL_OK
    # Authentication failed due to bad credentials.
    AUTH = Cproton::PN_SASL_AUTH
    # Failed due to a system error.
    SYS = Cproton::PN_SASL_SYS
    # Failed due to an unrecoverable error.
    PERM = Cproton::PN_SASL_PERM
    # Failed due to a transient error.
    TEMP = Cproton::PN_SASL_TEMP
    # The peer did not perform the SASL exchange.
    SKIPPED = Cproton::PN_SASL_SKIPPED

    # Pending SASL initialization.
    STATE_IDLE = Cproton::PN_SASL_IDLE
    # Negotiation in progress.
    STATE_STEP = Cproton::PN_SASL_STEP
    # Negotiation completed successfully.
    STATE_PASS = Cproton::PN_SASL_PASS
    # Negotation failed.
    STATE_FAIL = Cproton::PN_SASL_FAIL

    # @private
    include Util::SwigHelper

    # @private
    PROTON_METHOD_PREFIX = "pn_sasl"

    # @!attribute [r] state
    #
    # @return [Fixnum] The current state of the SASL negotiation.
    #
    proton_caller :state

    # @!attribute [r] pending
    #
    # @return [Fixnum] The size of the bytes available to be received.
    #
    proton_caller :pending

    # @private
    include Util::ErrorHandler

    can_raise_error :send, :error_class => SASLError

    # Constructs a new instance for the given transport.
    #
    # @param transport [Transport] The transport.
    #
    # @private A SASL should be fetched only from its Transport
    #
    def initialize(transport)
      @impl = transport.impl # just to get the context in the next call
      get_context(:pn_transport_attachments)
      @impl = Cproton.pn_sasl(transport.impl)
    end

    # Configure the SASL layer to act as a client.
    #
    # @deprecated This relationship is now determined by the Transport.
    #
    def client
      Cproton.pn_sasl_client(@impl)
    end

    # Configure the SASL layer to act as a server.
    #
    # @deprecated This relationship is now determined by the Transport.
    #
    def server
      Cproton.pn_sasl_server(@impl)
    end

    # Sets the acceptable SASL mechanisms.
    #
    # @param mechanisms [String] The space-delimited set of mechanisms.
    #
    # @example Use anonymous SASL authentication.
    #  @sasl.mechanisms("GSSAPI CRAM-MD5 PLAIN")
    #
    def mechanisms(mechanisms)
      Cproton.pn_sasl_mechanisms(@impl, mechanisms)
    end

    # Determines whether to allow skipping the SASL exchange.
    #
    # If the peer client skips the SASL exchange (i.e. goes right to the AMQP
    # header) this server layer will succeed and result in the outcome of
    # #SASL_SKIPPED.
    #
    # The default behavior is to fail and close the connection if the client
    # skips SASL.
    #
    # @param allow [Boolean] True is skipping SASL is allowed.
    #
    def allow_skip=(allow)
      Cproton.pn_sasl_allow_skip(@impl, allow)
    end

    # Configure the SASL layer to use the "PLAIN" mechanism.
    #
    # A utility function to configure a simple client SASL using the PLAIN
    # authentication.
    #
    # @param username [String] The username credential.
    # @param password [String] The password credential.
    #
    # @see mechanisms
    #
    def plain(username, password)
      Cproton.pn_sasl_plain(@impl, username, password)
    end

    # Sends the challenge or response data to the peer.
    #
    # @param data [String] The challenge/response data.
    #
    def send(data)
      Cproton.pn_sasl_send(@impl, data, data.length)
    end

    # Read the challenge/response data sent from the peer.
    #
    # @return [String] the challenge/response data.
    #
    # @see #pending
    #
    def receive
      size = 16
      loop do
        n, data = Cproton.pn_sasl_recv(@impl, size)
        if n == Qpid::Proton::Error::OVERFLOW
          size = size * 2
        elsif n == Qpid::Proton::Error::EOS
          return nil
        else
          check(n)
          return data
        end
      end
    end

    # Returns the outcome of the SASL negotiation.
    #
    # @return [Fixnum] The outcome.
    #
    def outcome
      outcome = Cprotn.pn_sasl_outcome(@impl)
      return nil if outcome == SASL_NONE
      outcome
    end

    # Set the condition of the SASL negotiation.
    #
    # @param outcome [Fixnum] The outcome.
    #
    def done(outcome)
      Cproton.pn_sasl_done(@impl, outcome)
    end

    private

    def check(rc)
      if rc < 0
        raise SASLException.new("[#{rc}]")
      end
      rc
    end

  end

end
