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
package org.apache.qpid.proton.engine.impl;

import java.util.Iterator;
import org.apache.qpid.proton.amqp.UnsignedInteger;
import org.apache.qpid.proton.engine.Delivery;
import org.apache.qpid.proton.engine.Receiver;

public class ReceiverImpl extends LinkImpl implements Receiver
{

    @Override
    public boolean advance()
    {
        DeliveryImpl current = current();
        if(current != null)
        {
            current.setDone();
        }
        final boolean advance = super.advance();
        if(advance)
        {
            decrementQueued();
            decrementCredit();
            getSession().incrementIncomingBytes(-current.pending());
            getSession().incrementIncomingDeliveries(-1);
            if (getSession().getTransportSession().getIncomingWindowSize().equals(UnsignedInteger.ZERO)) {
                modified();
            }
        }
        return advance;
    }

    private TransportReceiver _transportReceiver;
    private int _unsentCredits;


    ReceiverImpl(SessionImpl session, String name)
    {
        super(session, name);
    }

    public void flow(final int credits)
    {
        modified();
        addCredit(credits);
        setDrain(false);
        _unsentCredits += credits;
    }

    int clearUnsentCredits()
    {
        int credits = _unsentCredits;
        _unsentCredits = 0;
        return credits;
    }


    public int recv(final byte[] bytes, int offset, int size)
    {
        if (_current == null) {
            throw new IllegalStateException("no current delivery");
        }

        int consumed = _current.recv(bytes, offset, size);
        if (consumed > 0) {
            getSession().incrementIncomingBytes(-consumed);
            if (getSession().getTransportSession().getIncomingWindowSize().equals(UnsignedInteger.ZERO)) {
                modified();
            }
        }
        return consumed;
    }

    public Iterator<Delivery> unsettled()
    {
        return null;  //TODO.
    }

    public void free()
    {
        getSession().freeReceiver(this);

        super.free();
        //TODO.
    }

    boolean hasIncoming()
    {
        return false;  //TODO - Implement
    }

    void setTransportLink(TransportReceiver transportReceiver)
    {
        _transportReceiver = transportReceiver;
    }

    @Override
    TransportReceiver getTransportLink()
    {
        return _transportReceiver;
    }

    public void drain(int credit)
    {
        flow(credit);
        setDrain(true);
    }

    public boolean draining()
    {
        return getDrain() && (getCredit() > getQueued());
    }

}
