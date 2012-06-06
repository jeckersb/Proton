#ifndef _PROTON_ENGINE_H
#define _PROTON_ENGINE_H 1

/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

#include <stdbool.h>
#include <stddef.h>
#include <sys/types.h>
#include <proton/errors.h>

/** @file
 * API for the proton Engine.
 *
 * @todo
 */

typedef struct pn_error_t pn_error_t;
typedef struct pn_transport_t pn_transport_t;
typedef struct pn_connection_t pn_connection_t; /**< Connection */
typedef struct pn_session_t pn_session_t;       /**< Session */
typedef struct pn_link_t pn_link_t;             /**< Link */
typedef struct pn_delivery_t pn_delivery_t;

typedef struct pn_delivery_tag_t {
  size_t size;
  const char *bytes;
} pn_delivery_tag_t;

#define pn_dtag(BYTES, SIZE) ((pn_delivery_tag_t) {(SIZE), (BYTES)})

typedef int pn_state_t;     /**< encodes the state of an endpoint */

#define PN_LOCAL_UNINIT (1)    /**< local endpoint requires initialization */
#define PN_LOCAL_ACTIVE (2)    /**< local endpoint is active */
#define PN_LOCAL_CLOSED (4)    /**< local endpoint is closed */
#define PN_REMOTE_UNINIT (8)   /**< remote endpoint pending initialization by peer */
#define PN_REMOTE_ACTIVE (16)  /**< remote endpoint is active */
#define PN_REMOTE_CLOSED (32)  /**< remote endpoint has closed */

#define PN_LOCAL_MASK (PN_LOCAL_UNINIT | PN_LOCAL_ACTIVE | PN_LOCAL_CLOSED)
#define PN_REMOTE_MASK (PN_REMOTE_UNINIT | PN_REMOTE_ACTIVE | PN_REMOTE_CLOSED)

/** @enum pn_disposition_t
 * The state/outcome of a message transfer.
 *
 * @todo document each value
 */
typedef enum pn_disposition_t {
  PN_RECEIVED=1,
  PN_ACCEPTED=2,
  PN_REJECTED=3,
  PN_RELEASED=4,
  PN_MODIFIED=5
} pn_disposition_t;

typedef int pn_trace_t;

#define PN_TRACE_OFF (0)
#define PN_TRACE_RAW (1)
#define PN_TRACE_FRM (2)

#define PN_SESSION_WINDOW (1024)

// connection

/** Factory to construct a new Connection.
 *
 * @return pointer to a new connection object.
 */
pn_connection_t *pn_connection();

/** Retrieve the state of the connection.
 *
 * @param[in] connection the connection
 * @return the connection's state flags
 */
pn_state_t pn_connection_state(pn_connection_t *connection);
/** @todo: needs documentation */
pn_error_t *pn_connection_error(pn_connection_t *connection);
/** @todo: needs documentation */
char *pn_connection_container(pn_connection_t *connection);
/** @todo: needs documentation */
void pn_connection_set_container(pn_connection_t *connection, const char *container);
/** @todo: needs documentation */
char *pn_connection_hostname(pn_connection_t *connection);
/** @todo: needs documentation */
void pn_connection_set_hostname(pn_connection_t *connection, const char *hostname);

/** Extracts the first delivery on the connection that has pending
 *  operations.
 *
 * Retrieves the first delivery on the Connection that has pending
 * operations. A readable delivery indicates message data is waiting
 * to be read. A writable delivery indicates that message data may be
 * sent. An updated delivery indicates that the delivery's disposition
 * has changed. A delivery will never be both readable and writible,
 * but it may be both readable and updated or both writiable and
 * updated.
 *
 * @param[in] connection the connection
 * @return the first delivery object that needs to be serviced, else
 * NULL if none
 */
pn_delivery_t *pn_work_head(pn_connection_t *connection);

/** Get the next delivery on the connection that needs has pending
 *  operations.
 *
 * @param[in] delivery the previous delivery retrieved from
 *                     either pn_work_head() or pn_work_next()
 * @return the next delivery that has pending operations, else
 * NULL if none
 */
pn_delivery_t *pn_work_next(pn_delivery_t *delivery);

/** Factory for creating a new session on the connection.
 *
 * A new session is created for the connection, and is added to the
 * set of sessions maintained by the connection.
 *
 * @param[in] connection the session will exist over this connection
 * @return pointer to new session
 */
pn_session_t *pn_session(pn_connection_t *connection);

/** Factory for creating the connection's transport.
 *
 * The transport used by the connection to interface with the network.
 * There can only be one transport associated with a connection.
 *
 * @param[in] connection connection that will use the transport
 * @return pointer to new session
 */
pn_transport_t *pn_transport(pn_connection_t *connection);

/** Retrieve the first Session that matches the given state mask.
 *
 * Examines the state of each session owned by the connection, and
 * returns the first Session that matches the given state mask. If
 * state contains both local and remote flags, then an exact match
 * against those flags is performed. If state contains only local or
 * only remote flags, then a match occurs if any of the local or
 * remote flags are set respectively.
 *
 * @param[in] connection to be searched for matching sessions
 * @param[in] state mask to match
 * @return the first session owned by the connection that matches the
 * mask, else NULL if no sessions match
 */
pn_session_t *pn_session_head(pn_connection_t *connection, pn_state_t state);

/** Retrieve the next Session that matches the given state mask.
 *
 * When used with pn_session_head(), application can access all
 * Sessions on the connection that match the given state. See
 * pn_session_head() for description of match behavior.
 *
 * @param[in] session the previous session obtained from
 *                    pn_session_head() or pn_session_next()
 * @param[in] state mask to match.
 * @return the next session owned by the connection that matches the
 * mask, else NULL if no sessions match
 */
pn_session_t *pn_session_next(pn_session_t *session, pn_state_t state);

/** Retrieve the first Link that matches the given state mask.
 *
 * Examines the state of each Link owned by the connection and returns
 * the first Link that matches the given state mask. If state contains
 * both local and remote flags, then an exact match against those
 * flags is performed. If state contains only local or only remote
 * flags, then a match occurs if any of the local or remote flags are
 * set respectively.
 *
 * @param[in] connection to be searched for matching Links
 * @param[in] state mask to match
 * @return the first Link owned by the connection that matches the
 * mask, else NULL if no Links match
 */
pn_link_t *pn_link_head(pn_connection_t *connection, pn_state_t state);

/** Retrieve the next Link that matches the given state mask.
 *
 * When used with pn_link_head(), the application can access all Links
 * on the connection that match the given state. See pn_link_head()
 * for description of match behavior.
 *
 * @param[in] link the previous Link obtained from pn_link_head() or
 *                 pn_link_next()
 * @param[in] state mask to match
 * @return the next session owned by the connection that matches the
 * mask, else NULL if no sessions match
 */
pn_link_t *pn_link_next(pn_link_t *link, pn_state_t state);

void pn_connection_open(pn_connection_t *connection);
void pn_connection_close(pn_connection_t *connection);
void pn_connection_destroy(pn_connection_t *connection);

// transport
pn_error_t *pn_transport_error(pn_transport_t *transport);
ssize_t pn_input(pn_transport_t *transport, char *bytes, size_t available);
ssize_t pn_output(pn_transport_t *transport, char *bytes, size_t size);
time_t pn_tick(pn_transport_t *transport, time_t now);
void pn_trace(pn_transport_t *transport, pn_trace_t trace);
void pn_transport_destroy(pn_transport_t *transport);

// session
pn_state_t pn_session_state(pn_session_t *session);
pn_error_t *pn_session_error(pn_session_t *session);
pn_link_t *pn_sender(pn_session_t *session, const char *name);
pn_link_t *pn_receiver(pn_session_t *session, const char *name);
pn_connection_t *pn_get_connection(pn_session_t *session);
void pn_session_open(pn_session_t *session);
void pn_session_close(pn_session_t *session);
void pn_session_destroy(pn_session_t *session);

// link
const char *pn_link_name(pn_link_t *link);
bool pn_is_sender(pn_link_t *link);
bool pn_is_receiver(pn_link_t *link);
pn_state_t pn_link_state(pn_link_t *link);
pn_error_t *pn_link_error(pn_link_t *link);
pn_session_t *pn_get_session(pn_link_t *link);
const char *pn_target(pn_link_t *link);
const char *pn_source(pn_link_t *link);
void pn_set_source(pn_link_t *link, const char *source);
void pn_set_target(pn_link_t *link, const char *target);
char *pn_remote_source(pn_link_t *link);
char *pn_remote_target(pn_link_t *link);
pn_delivery_t *pn_delivery(pn_link_t *link, pn_delivery_tag_t tag);
pn_delivery_t *pn_current(pn_link_t *link);
bool pn_advance(pn_link_t *link);
int pn_credit(pn_link_t *link);
int pn_queued(pn_link_t *link);

int pn_unsettled(pn_link_t *link);
pn_delivery_t *pn_unsettled_head(pn_link_t *link);
pn_delivery_t *pn_unsettled_next(pn_delivery_t *delivery);

void pn_link_open(pn_link_t *sender);
void pn_link_close(pn_link_t *sender);
void pn_link_destroy(pn_link_t *sender);

// sender
//void pn_offer(pn_sender_t *sender, int credits);
ssize_t pn_send(pn_link_t *sender, const char *bytes, size_t n);
void pn_drained(pn_link_t *sender);
//void pn_abort(pn_sender_t *sender);

// receiver
void pn_flow(pn_link_t *receiver, int credit);
void pn_drain(pn_link_t *receiver, int credit);
ssize_t pn_recv(pn_link_t *receiver, char *bytes, size_t n);

// delivery
pn_delivery_tag_t pn_delivery_tag(pn_delivery_t *delivery);
pn_link_t *pn_link(pn_delivery_t *delivery);
// how do we do delivery state?
int pn_local_disp(pn_delivery_t *delivery);
int pn_remote_disp(pn_delivery_t *delivery);
bool pn_remote_settled(pn_delivery_t *delivery);
size_t pn_pending(pn_delivery_t *delivery);
bool pn_writable(pn_delivery_t *delivery);
bool pn_readable(pn_delivery_t *delivery);
bool pn_updated(pn_delivery_t *delivery);
void pn_clear(pn_delivery_t *delivery);
void pn_disposition(pn_delivery_t *delivery, pn_disposition_t disposition);
//int pn_format(pn_delivery_t *delivery);
void pn_settle(pn_delivery_t *delivery);
void pn_delivery_dump(pn_delivery_t *delivery);

#endif /* engine.h */
