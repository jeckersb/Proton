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

  class PartDescriptor

    def initialize(part)
      @getter = "pn_url_get_#{part}"
      @setter = "pn_url_set_#{part}"
    end

    def get(object)
      object.url.send(@getter)
    end

    def set(object, value)
      object.url.send(@setter, value)
    end

  end

  class URL

    scheme = PartDescriptor.new("scheme")
    username = PartDescriptor.new("username")
    password = PartDescriptor.new("password")
    host = PartDescriptor.new("host")
    path = PartDescriptor.new("path")

    def initialize(options = {})
      options[:defaults] = true

      if options[:url]
        @url = Cproton.pn_url_parse(options[:url])
        if @url.nil?
          raise ArgumentError.new("invalid url: #{options[:url]}")
        end
      else
        @url = Cproton.pn_url
      end
      self.defaults if options[:defaults]
    end

    def port=(port)
      if port.nil?
        Cproton.pn_url_set_port(@url, nil)
      else
        Cproton.pn_url_set_port(@url, port)
      end
    end

    def port
      Cproton.pn_url_get_port(@url)
    end

    def to_s
      "#{Url(Cproton.pn_url_str(@url))}"
    end

    private

    def defaults
      @scheme = @scheme || AMQP
      @host = @host || "0.0.0.0"
      @port = @port || scheme
    end

  end

end
