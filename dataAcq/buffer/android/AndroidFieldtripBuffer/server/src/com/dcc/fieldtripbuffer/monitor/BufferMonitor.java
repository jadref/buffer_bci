package com.dcc.fieldtripbuffer.monitor;

import java.util.ArrayList;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.util.SparseArray;
import nl.fcdonders.fieldtrip.bufferserver.FieldtripBufferMonitor;

import com.dcc.fieldtripbuffer.C;

public class BufferMonitor extends Thread implements FieldtripBufferMonitor {

	private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(final Context context, final Intent intent) {
			if (intent.getIntExtra(C.MESSAGE_TYPE, -1) == C.UPDATE_REQUEST) {
				Log.i(C.TAG, "Received update request.");
				sendAllInfo();
			}
		}
	};

	private boolean run = true;
	private final Context context;
	private final SparseArray<ClientInfo> clients = new SparseArray<ClientInfo>();
	private final BufferInfo info;
	private boolean change = false;

	public BufferMonitor(final Context context, final String adress,
			final long startTime) {
		this.context = context;
		LocalBroadcastManager.getInstance(context).registerReceiver(
				mMessageReceiver, new IntentFilter(C.FILTER));
		setName("Fieldtrip Buffer Monitor");
		info = new BufferInfo(adress, startTime);
		Log.i(C.TAG, "Created Monitor.");
	}

	@Override
	public void clientClosedConnection(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.connected = false;
			client.timeLastActivity = time;
			client.lastActivity = C.DISCONNECTED;
			client.changed = true;
			client.time = time;
			change = true;
		}
	}

	@Override
	public void clientContinues(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.STOPWAITING;
			client.waitEvents = -1;
			client.waitSamples = -1;
			client.waitTimeout = -1;
			client.changed = true;
			change = true;
		}
	}

	@Override
	public void clientError(final int clientID, final int errorType,
			final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.error = errorType;
			client.connected = false;
			client.changed = true;
			client.time = time;
			change = true;
		}
	}

	@Override
	public void clientFlushedData(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.FLUSHSAMPLES;
			client.changed = true;
		}
		info.nSamples = 0;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientFlushedEvents(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.FLUSHEVENTS;
			client.changed = true;
		}
		info.nEvents = 0;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientFlushedHeader(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.FLUSHHEADER;
			client.changed = true;
		}
		info.fSample = -1;
		info.nChannels = -1;
		info.dataType = -1;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientGetEvents(final int count, final int clientID,
			final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.GOTEVENTS;
			client.eventsGotten += count;
			client.changed = true;
			client.diff = count;
			change = true;
		}
	}

	@Override
	public void clientGetHeader(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.GOTHEADER;
			client.changed = true;
			change = true;
		}
	}

	@Override
	public void clientGetSamples(final int count, final int clientID,
			final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.samplesGotten += count;
			client.lastActivity = C.GOTSAMPLES;
			client.changed = true;
			client.diff = count;
			change = true;
		}
	}

	@Override
	public void clientOpenedConnection(final int clientID, final String adress,
			final long time) {
		if (clientID != -1) {
			final ClientInfo client = new ClientInfo(adress, clientID, time);
			clients.put(clientID, client);
			change = true;
		}
	}

	@Override
	public void clientPolls(final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.POLL;
			client.changed = true;
			change = true;
		}
	}

	@Override
	public void clientPutEvents(final int count, final int clientID,
			final int diff, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.PUTEVENTS;
			client.eventsPut += diff;
			client.changed = true;
			client.diff = diff;
		}
		info.nEvents = count;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientPutHeader(final int dataType, final float fSample,
			final int nChannels, final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.PUTHEADER;
			client.changed = true;
		}
		info.dataType = dataType;
		info.fSample = fSample;
		info.nChannels = nChannels;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientPutSamples(final int count, final int clientID,
			final int diff, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.PUTSAMPLES;
			client.samplesPut += diff;
			client.diff = diff;
			client.changed = true;
		}
		info.nSamples = count;
		info.changed = true;
		change = true;
	}

	@Override
	public void clientWaits(final int nSamples, final int nEvents,
			final int timeout, final int clientID, final long time) {
		if (clientID != -1) {
			final ClientInfo client = clients.get(clientID);
			client.timeLastActivity = time;
			client.lastActivity = C.WAIT;
			client.waitSamples = nSamples;
			client.waitEvents = nEvents;
			client.waitTimeout = timeout;
			client.changed = true;
			change = true;
		}
	}

	@Override
	public void run() {
		while (run) {
			try {

				Thread.sleep(500);

			} catch (final InterruptedException e) {

			}
			if (change) {
				sendUpdate();
				Log.i(C.TAG, "SENDING UPDATE.");
				change = false;
			}
		}
	}

	private void sendAllInfo() {
		final Intent intent = new Intent(C.FILTER);
		intent.putExtra(C.MESSAGE_TYPE, C.UPDATE);
		intent.putExtra(C.BUFFER_INFO, info);

		if (clients.size() > 0) {
			final ClientInfo[] clientInfo = new ClientInfo[clients.size()];

			for (int i = 0; i < clients.size(); i++) {
				if (clients.valueAt(i).changed) {
					clientInfo[i] = clients.valueAt(i);
				}
			}
			intent.putExtra(C.CLIENT_INFO, clientInfo);
		}

		LocalBroadcastManager.getInstance(context).sendBroadcast(intent);
	}

	private void sendUpdate() {
		final Intent intent = new Intent(C.FILTER);
		intent.putExtra(C.MESSAGE_TYPE, C.UPDATE);

		if (info.changed) {
			intent.putExtra(C.BUFFER_INFO, info);
		}

		final ArrayList<ClientInfo> clientInfo = new ArrayList<ClientInfo>();

		for (int i = 0; i < clients.size(); i++) {
			if (clients.valueAt(i).changed) {
				clientInfo.add(clients.valueAt(i));
			}
		}

		if (clientInfo.size() > 0) {
			intent.putExtra(C.CLIENT_INFO,
					clientInfo.toArray(new ClientInfo[clientInfo.size()]));
			Log.i(C.TAG, "Including Client Info in update.");
		}

		LocalBroadcastManager.getInstance(context).sendBroadcast(intent);
	}

	public void stopMonitoring() {
		run = false;
		LocalBroadcastManager.getInstance(context).unregisterReceiver(
				mMessageReceiver);
		Log.i(C.TAG, "BufferMonitor stopped");
	}

}