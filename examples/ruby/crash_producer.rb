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

require "qpid_proton"
require "socket"
require "selectable"

Thread.abort_on_exception = true

server = TCPServer.new(8888)
$selectables = []
$selectable_by_fileno = {}
read, write = IO.pipe

Thread.new(read) do |read|
  loop do
    reading = [read]
    writing = []

    $selectables.each do |sel|
      reading << IO.new(sel.fileno) if sel.reading?
      writing << IO.new(sel.fileno) if sel.writing?
      if sel.closed?
        $selectables.remove(sel)
        $selectable_by_fileno.delete(sel.fileno)
      end
    end

    deadline = 0
    readable, writable = IO.select(reading, writing, [], 1)

    reading.each do |socket|
      sel = $selectable_by_fileno[socket.fileno]
      sel.readable unless sel.nil?
    end

    writing.each do |socket|
      sel = $selectable_by_fileno[socket.fileno]
      sel.writable unless sel.nil?
    end
  end
end

loop do
  socket = server.accept

  conn = Qpid::Proton::Connection.new
  puts "Connection from #{socket.peeraddr(true)[3]}"

  transport = Qpid::Proton::Transport.new
  transport.trace(Qpid::Proton::Transport::TRACE_FRM)
  transport.idle_timeout = 300
  sasl = transport.sasl
  sasl.mechanisms("ANONYMOUS")
  sasl.server
  sasl.done(Qpid::Proton::SASL::OK)
  transport.bind(conn)
  selectable = Selectable.new(transport, socket)
  $selectables << selectable
  $selectable_by_fileno[socket.fileno] = selectable

  session = conn.session
  receiver = session.receiver("test")
  delivery = receiver.delivery("test")
  link = delivery.link
  msg = Qpid::Proton::Message.new
  puts "delivery.pending?=#{delivery.pending?}"
  msg.decode(link.receive(delivery.pending?))
  link.advance
  puts "Received: #{msg.body}"
end
