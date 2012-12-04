#!/usr/bin/env perl -w
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

use Test::More qw( no_plan );
use Test::Exception;

BEGIN { use_ok( 'qpid_proton' ); }
require_ok( 'qpid_proton' );

# Create a new message.
my $message = qpid::proton::Message->new();
isa_ok( $message, 'qpid::proton::Message' );

# Verify the message mutators.

# durable
$message->set_durable(1);
ok($message->get_durable(), "Durable can be enabled.");
$message->set_durable(0);
ok(!$message->get_durable(), "Durable can be disabled.");

# priority
my $priority = int(rand(256) + 1);

dies_ok( sub { $message->set_priority("abc") },
         'Message cannot have a non-numeric priority');
dies_ok( sub { $message->set_priority(0 - $priority) },
         'Message cannot have a negative priority');

$message->set_priority(0);
ok($message->get_priority() == 0, 'Message can have a zero priority.');
$message->set_priority($priority);
ok($message->get_priority() == $priority, 'Message can have a priority.');

# Time to live
my $ttl = int(rand(65535) + 1);

dies_ok( sub { $message->set_ttl("def") },
         'Message cannot have a non-numeric ttl.');
dies_ok( sub { $message->set_ttl(0 - $ttl) },
         'Message cannot have a negative ttl.' );

$message->set_ttl(0);
ok( $message->get_ttl() == 0, 'Message can have a zero ttl.' );
$message->set_ttl($ttl);
ok( $message->get_ttl() == $ttl, 'Message can have a positive ttl.' );
