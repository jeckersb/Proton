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

module Qpid::Proton::Reactor

  # @private
  class InternalTransactionHandler < Qpid::Proton::Handler::OutgoingMessageHandler

    def initialize
      super
    end

    def on_settled(event)
      if event.delivery.respond_to? :transaction
        event.transaction = event.delivery.transaction
        event.delivery.transaction.handle_outcome(event)
      end
    end

  end


  # A representation of the AMQP concept of a container which, loosely
  # speaking, is something that establishes links to or from another
  # container on which messages are transferred.
  #
  # This is an extension to the Reactor classthat adds convenience methods
  # for creating instances of Qpid::Proton::Connection, Qpid::Proton::Sender
  # and Qpid::Proton::Receiver.
  #
  # @example
  #
  class Container < Reactor

    include Qpid::Proton::Util::Reactor

    include Qpid::Proton::Util::UUID

    proton_attr :ssl, :default => proc {SSLConfig.new}

    proton_attr :trigger

    proton_attr :container_id, :default => proc {|obj| obj.generate_uuid}

    proton_attr :container, :default => proc {|obj| obj.container = obj}

    proton_attr :subclass, :default => self

    def initialize(handlers, options = {})
      super(handlers, options)
      unless options.has_key?(:impl)
        self.ssl = SSLConfig.new
        if options[:global_handler]
          self.global_handler = GlobalOverrides.new(options[:global_handler])
        else
          self.global_handler = GlobalOverrides.new(self.global_handler)
        end
        self.container_id = generate_uuid
        self.subclass = self.class
      end
    end

    # Initiates the establishment of an AMQP connection.
    #
    # @param options [Hash] A hash of named arguments.
    #
    def connect(options = {})
      conn = self.connection(options[:handler])
      conn.container = self.container_id || generate_uuid
      connector = Connector.new(conn)
      conn.overrides = connector
      if options[:url]
        connector.address = URLs.new([options[:url]])
      elsif options[:urls]
        connector.address = URLs.new(options[:urls])
      elsif options[:address]
        connector.address = options[:address]
      else
        raise ArgumentError.new("either :url or :urls or :address required")
      end

      connector.heartbeat = options[:heartbeat] if options[:heartbeat]
      if options[:reconnect]
        connector.reconnect = options[:reconnect]
      else
        connector.reconnect = Backoff.new()
      end

      connector.ssl_domain = SessionPerConnection.new # TODO seems this should be configurable

      conn.open

      return conn
    end

    def session(context)
      if context.is_a? Qpid::Proton::URL
        return self.session(self.connect(:url => context))
      elsif context.is_a? Qpid::Proton::Session
        return context
      elsif context.is_a? Qpid::Proton::Connection
        if context.respond_to? :session_policy
          return context.send(:session_policy).session(context)
        else
          return self.create_session(context)
        end
      else
        return context.session
      end
    end

    # Initiates the establishment of a link over which messages can be sent.
    #
    # @param context [String, URL] The context.
    # @param source
    # @param target
    # @param dynamice
    # @param handler
    # @param options
    #
    def create_sender(context, target = nil, source = nil, name = nil, dynamic = false, handler = nil, tags = nil, options = nil)
      if context.is_a? ::String
        context = Qpid::Proton::URL.new(context)
      elsif context.is_a?(Qpid::Proton::URL) && target.nil?
        target = context.path
      end
      session = self.session(context)

      sender = session.sender(name ||
                              id(session.connection.container,
                                target, source))
        sender.source.address = source if source
        sender.target.address = target if target
        sender.handler = handler if handler
        sender.tag_generator = tags if tags
        apply_link_options(options, sender)
        sender.open
        return sender
    end

    # Initiates the establishment of a link over which messages can be received.
    #
    # @param source
    # @param target
    # @param dynamice
    # @param handler
    # @param options
    #
    def create_receiver(context, source = nil, target = nil, name = nil, dynamic = false, handler = nil, options = nil)
      if context.is_a? ::String
      elsif context.is_a?(Qpid::Proton::URL) && source.nil?
        source = context.path
      end
      session = self.session(context)

      receiver = session.receiver(name ||
                                  id(session.connection.container,
                                      source, target))
      receiver.source.address = source if source
      receiver.target.address = target if target
      receiver.hanlder = handler if handler
      apply_link_options(options, receiver)
      receiver.open
      return receiver
    end

    def declare_transaction(context, handler = nil, settle_before_discharge = false)
      if context.respond_to? :txn_ctl && !context.send(:txn_ctl).nil?
        class << context
          attr_accessor :txn_ctl
        end
        context.txn_ctl = self.create_sender(context, nil, "txn-ctl",
        InternalTransactionHandler.new())
      end
      return Transaction.new(context.txn_ctl, handler, settle_before_discharge)
    end

    # Initiates a server socket, accepting incoming AMQP connections on the
    # interface and port specified.
    #
    # @param url []
    # @param ssl_domain []
    #
    def listen(url, ssl_domain = nil)
      url = Url.new(url)
      ssl_config = ssl_domain
      if ssl_config.nil? && url.schem = "amqps"
        ssl_config = self.ssl_domain
      end
      return self.acceptor(url.host, url.port)
    end

    def do_work(timeout = nil)
      self.timeout = timeout unless timeout.nil?
      self.process
    end

    private

    def id(container, remote, local)
      if !local.nil? && !remote.nil?
        "#{container}-#{remote}-#{local}"
      elsif !local.nil?
        "#{container}-#{local}"
      elsif !remote.nil?
        "#{container}-#{remote}"
      else
        "#{container}-#{generate_uuid}"
      end
    end

    def apply_link_options(options, link)
      unless options.nil? || options.empty?
        options = [options].flatten
        options.each do |option|
          option.apply(link) if option.test(link)
        end
      end
    end

  end

end
