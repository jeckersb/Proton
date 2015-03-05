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

require 'qpid_proton'
require 'yaml'

def how_many_transports?(which = nil)
  GC.start if !which.nil? && (which % 5).zero?
  print "[#{which}] " if !which.nil?
  puts "instances: count=#{ObjectSpace.each_object(Qpid::Proton::Transport).count}"
  ObjectSpace.each_object(Qpid::Proton::Transport) do |instance|
    puts "     -> #{instance}"
  end
end

transport = Qpid::Proton::Transport.new
timpl = transport.impl
Cproton.pn_transport_set_mine(timpl)
transport.first_name = "Darryl"
transport.last_name = "Pierce"
transport = nil

how_many_transports?

max = 1000
puts "Creating #{max} instances of Transport"
(0...max).each do |which|
  t = Qpid::Proton::Transport.new
  t.instance_id = which
  how_many_transports?(which)
  t = nil
end

puts "===================================="
puts "= Retrieving my original transport ="
puts "===================================="
how_many_transports?
puts "===================================="
timpl = Cproton.pn_transport_get_mine
transport = Qpid::Proton::Transport.wrap(timpl)
puts transport
how_many_transports?
puts "===================================="
puts "My transport attributes:"
puts transport.to_yaml
