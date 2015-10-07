package nl.dcc.fieldtripbuffer.fragments;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.content.LocalBroadcastManager;
import android.text.Html;
import android.util.Log;
import android.util.SparseArray;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.ListView;
import android.widget.TextView;

import nl.dcc.fieldtripbuffer.BufferService;
import nl.dcc.fieldtripbuffer.C;
import nl.dcc.fieldtripbuffer.monitor.ClientInfo;
import nl.fcdonders.fieldtrip.bufferserver.network.NetworkProtocol;

import nl.dcc.fieldtripbuffer.monitor.BufferInfo;

public class RunningBufferFragment extends Fragment {
	private class Timer extends Thread {
		public boolean running = true;

		@Override
		public void run() {
			while (running) {
				getActivity().runOnUiThread(new Runnable() {
					@Override
					public void run() {
						try {
							uptime.setText(minSec.format(new Date(System
									.currentTimeMillis() - buffer.startTime)));
						} catch (final Exception e) {
						}
					}
				});
				try {
					Thread.sleep(1000);
				} catch (final InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}

	private static String dataTypeToString(final int dataType,
			final Resources res) {
		switch (dataType) {
		case NetworkProtocol.CHAR:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.CHAR);
		case NetworkProtocol.UINT8:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.UINT8);
		case NetworkProtocol.INT8:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.INT8);
		case NetworkProtocol.UINT16:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.UINT16);
		case NetworkProtocol.INT16:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.INT16);
		case NetworkProtocol.UINT32:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.UINT32);
		case NetworkProtocol.INT32:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.INT32);
		case NetworkProtocol.FLOAT32:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.FLOAT32);
		case NetworkProtocol.UINT64:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.UINT64);
		case NetworkProtocol.INT64:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.INT64);
		case NetworkProtocol.FLOAT64:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.FLOAT64);
		default:
			return res.getString(nl.dcc.fieldtripbuffer.R.string.UNKOWN);
		}
	}

	private Timer timer;

	private BufferInfo buffer;

	private SparseArray<ClientInfo> clients = new SparseArray<ClientInfo>();
	private final ArrayList<ClientInfo> clientsArray = new ArrayList<ClientInfo>();
	private TextView adress;
	private TextView uptime;
	private TextView dataType;
	private TextView nChannels;
	private TextView fSample;
	private TextView nEvents;
	private TextView nSamples;
	private ListView clientList;
	private boolean initalUpdateCalled;
	private final SimpleDateFormat minSec = new SimpleDateFormat("mm:ss");
	private ClientInfoAdapter adapter;

	OnClickListener stopBuffer = new OnClickListener() {
		@Override
		public void onClick(final View v) {
			// Create Intent for stopping the buffer.
			final Intent intent = new Intent(getActivity(), BufferService.class);
			// Stop the buffer
			getActivity().stopService(intent);

			// Replace this fragment with the StartBuffer Fragment.
			// Create a fragment transaction
			final FragmentTransaction transaction = getFragmentManager()
					.beginTransaction();

			// Replace current fragment with a new RunningBuffer fragment
			transaction.replace(nl.dcc.fieldtripbuffer.R.id.activity_main_container,
					new StartBufferFragment());

			transaction
			.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
			// Commit the transaction
			transaction.commit();
		}
	};

	private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(final Context context, final Intent intent) {
			if (intent.getIntExtra(C.MESSAGE_TYPE, -1) == C.UPDATE) {
				final BufferInfo bufferInfo = (BufferInfo) intent
						.getParcelableExtra(C.BUFFER_INFO);
				final ClientInfo[] clientInfo = (ClientInfo[]) intent
						.getParcelableArrayExtra(C.CLIENT_INFO);

				if (bufferInfo != null) {
					buffer = bufferInfo;
					updateBufferInfo();
					if (!initalUpdateCalled) {
						initialUpdate();
					}
				}

				if (clientInfo != null) {
					Log.i(C.TAG, "Received Client Info.");
					updateClients(clientInfo);
				}

			}

		}
	};

	private void flush(final int flush) {
		final AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());

		final Resources res = getActivity().getResources();

		alert.setTitle(res.getString(nl.dcc.fieldtripbuffer.R.string.confirmation));

		switch (flush) {
		case C.REQUEST_FLUSH_HEADER:
			alert.setMessage(res.getString(nl.dcc.fieldtripbuffer.R.string.confirmationflushheader));
			break;
		case C.REQUEST_FLUSH_SAMPLES:
			alert.setMessage(res.getString(nl.dcc.fieldtripbuffer.R.string.confirmationflushsamples));
			break;
		case C.REQUEST_FLUSH_EVENTS:
			alert.setMessage(res.getString(nl.dcc.fieldtripbuffer.R.string.confirmationflushevents));
			break;
		default:
		}

		alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
			@Override
			public void onClick(final DialogInterface dialog,
					final int whichButton) {
				final Intent intent = new Intent(C.FILTER);
				intent.putExtra(C.MESSAGE_TYPE, flush);
				LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(
						intent);
			}
		});

		alert.setNegativeButton("Cancel",
				new DialogInterface.OnClickListener() {
					@Override
					public void onClick(final DialogInterface dialog,
							final int whichButton) {
					}
				});

		alert.show();
	}

	private void initialUpdate() {
		adress.setText(buffer.adress);
		timer = new Timer();
		timer.start();
		initalUpdateCalled = true;
	}

	@Override
	public void onCreate(final Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		LocalBroadcastManager.getInstance(getActivity()).registerReceiver(
				mMessageReceiver, new IntentFilter(C.FILTER));
		if (savedInstanceState != null) {
			buffer = savedInstanceState.getParcelable(C.BUFFER_INFO);
			clients = savedInstanceState
					.getSparseParcelableArray(C.CLIENT_INFO);
		}
		setHasOptionsMenu(true);
	}

	@Override
	public void onCreateOptionsMenu(final Menu menu, final MenuInflater inflater) {
		inflater.inflate(nl.dcc.fieldtripbuffer.R.menu.running_menu, menu);
	}

	@Override
	public View onCreateView(final LayoutInflater inflater,
			final ViewGroup container, final Bundle savedInstanceState) {
		final View rootView = inflater.inflate(nl.dcc.fieldtripbuffer.R.layout.fragment_runningbuffer,
				container, false);

		// Adding a clicklistener to the button
		rootView.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_stop)
		.setOnClickListener(stopBuffer);

		// Grabbing all the view elements we will need to update
		adress = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_adress);
		uptime = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_uptime);
		dataType = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_datatype);
		nChannels = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_nchannels);
		fSample = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_fsample);
		nEvents = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_nevents);
		nSamples = (TextView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_nsamples);
		clientList = (ListView) rootView
				.findViewById(nl.dcc.fieldtripbuffer.R.id.fragment_runningbuffer_clientinfo);

		// If there is a saved instance we will immediatly update the view
		// elements
		if (savedInstanceState != null) {
			buffer = savedInstanceState.getParcelable(C.BUFFER_INFO);
			clients = savedInstanceState
					.getSparseParcelableArray(C.CLIENT_INFO);
			for (int i = 0; i < clients.size(); i++) {
				clientsArray.add(clients.valueAt(i));
			}
			initialUpdate();
			updateBufferInfo();
		} else {

			initalUpdateCalled = false;
			// Sending a update request to the service.
			final Intent intent = new Intent(C.FILTER);
			intent.putExtra(C.MESSAGE_TYPE, C.UPDATE_REQUEST);
			LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(
					intent);
		}

		adapter = new ClientInfoAdapter(getActivity(),
				nl.dcc.fieldtripbuffer.R.layout.clientinfo_list_item, clientsArray);

		clientList.setAdapter(adapter);

		return rootView;
	}

	@Override
	public void onDestroy() {
		LocalBroadcastManager.getInstance(getActivity()).unregisterReceiver(
				mMessageReceiver);
		super.onDestroy();
	}

	@Override
	public boolean onOptionsItemSelected(final MenuItem item) {
		// handle item selection
		switch (item.getItemId()) {
		case nl.dcc.fieldtripbuffer.R.id.put_dummy_header:
			final Intent intent = new Intent(C.FILTER);
			intent.putExtra(C.MESSAGE_TYPE, C.REQUEST_PUT_HEADER);
			LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(
					intent);
			return true;
		case nl.dcc.fieldtripbuffer.R.id.flush_header:
			flush(C.REQUEST_FLUSH_HEADER);
			return true;
		case nl.dcc.fieldtripbuffer.R.id.flush_samples:
			flush(C.REQUEST_FLUSH_SAMPLES);
			return true;
		case nl.dcc.fieldtripbuffer.R.id.flush_events:
			flush(C.REQUEST_FLUSH_EVENTS);
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	@Override
	public void onSaveInstanceState(final Bundle outState) {
		outState.putParcelable(C.BUFFER_INFO, buffer);
		outState.putSparseParcelableArray(C.CLIENT_INFO, clients);
	}

	@Override
	public void onStart() {
		super.onStart();
		LocalBroadcastManager.getInstance(getActivity()).registerReceiver(
				mMessageReceiver, new IntentFilter(C.FILTER));
	}

	@Override
	public void onStop() {
		LocalBroadcastManager.getInstance(getActivity()).unregisterReceiver(
				mMessageReceiver);
		timer.running = false;
		super.onStop();
	}

	private void updateBufferInfo() {
		final Resources res = getResources();
		if (buffer.fSample != -1 && buffer.nChannels != -1) {

			dataType.setText(res.getString(nl.dcc.fieldtripbuffer.R.string.datatype) + " "
					+ dataTypeToString(buffer.dataType, res));
			nChannels.setText(Html.fromHtml(res
					.getString(nl.dcc.fieldtripbuffer.R.string.numberofchannels)
					+ " "
					+ Integer.toString(buffer.nChannels)));
			fSample.setText(Html.fromHtml(res
					.getString(nl.dcc.fieldtripbuffer.R.string.samplingfrequency)
					+ " "
					+ Float.toString(buffer.fSample)));
			nEvents.setText(Html.fromHtml(res
					.getString(nl.dcc.fieldtripbuffer.R.string.numberofevents)
					+ " "
					+ Integer.toString(buffer.nEvents)));
			nSamples.setText(Html.fromHtml(res
					.getString(nl.dcc.fieldtripbuffer.R.string.numberofsamples)
					+ " "
					+ Integer.toString(buffer.nSamples)));

		} else {
			dataType.setText(res.getString(nl.dcc.fieldtripbuffer.R.string.noheader));
			nChannels.setText("");
			fSample.setText("");
			nEvents.setText("");
			nSamples.setText("");
		}
	}

	public void updateClients(final ClientInfo[] clientinfo) {
		for (final ClientInfo client : clientinfo) {
			if (clients.get(client.clientID) == null) {
				clients.put(client.clientID, client);
				clientsArray.add(client);
			} else {
				clients.get(client.clientID).update(client);
			}
		}
		Log.i(C.TAG,
				"Updating Client list " + Integer.toString(clientinfo.length));
		adapter.notifyDataSetChanged();
	}
}
