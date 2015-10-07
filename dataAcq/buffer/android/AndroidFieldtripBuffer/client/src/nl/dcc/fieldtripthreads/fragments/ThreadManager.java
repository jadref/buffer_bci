package nl.dcc.fieldtripthreads.fragments;

import java.util.ArrayList;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.util.SparseArray;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ListView;

import nl.dcc.fieldtripthreads.C;
import nl.dcc.fieldtripthreads.R;
import nl.dcc.fieldtripthreads.ThreadInfo;
import nl.dcc.fieldtripthreads.ThreadService;

public class ThreadManager extends Fragment {

	private SparseArray<ThreadInfo> threads = new SparseArray<ThreadInfo>();

	private final ArrayList<ThreadInfo> threadsArray = new ArrayList<ThreadInfo>();
	private ListView threadlist;

	private ThreadListAdapter adapter;

	private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(final Context context, final Intent intent) {
			if (intent.getIntExtra(C.MESSAGE_TYPE, -1) == C.UPDATE) {
				final ThreadInfo[] threadInfo = (ThreadInfo[]) intent
						.getParcelableArrayExtra(C.THREAD_LIST);

				if (threadInfo != null) {
					Log.i(C.TAG, "Received Client Info.");
					updateThreadInfo(threadInfo);
				}

			}
		}
	};

	OnClickListener launchThread = new OnClickListener() {
		@Override
		public void onClick(final View v) {
			// Create a fragment transaction
			final FragmentTransaction transaction = getFragmentManager()
					.beginTransaction();

			transaction.replace(R.id.activity_main_container,
					new ThreadChooser());
			transaction
					.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
			transaction.addToBackStack(C.THREAD_MANAGEMENT);
			transaction.commit();
		}
	};

	OnClickListener stopall = new OnClickListener() {
		@Override
		public void onClick(final View v) {
			// Create a fragment transaction
			final Intent intent = new Intent(getActivity(), ThreadService.class);
			// Stop the buffer
			getActivity().stopService(intent);
			threads.clear();
			threadsArray.clear();
			adapter.clear();
			adapter.notifyDataSetChanged();
			serviceRunning = false;
		}
	};

	private Resources res;
	private boolean serviceRunning = true;

	public boolean changed(final ThreadInfo old, final ThreadInfo newer) {
		return old.running != newer.running || old.status != newer.status
				|| old.title != newer.title;
	}

	@Override
	public void onCreate(final Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		LocalBroadcastManager.getInstance(getActivity()).registerReceiver(
				mMessageReceiver, new IntentFilter(C.FILTER));
		if (savedInstanceState != null) {
			threads = savedInstanceState
					.getSparseParcelableArray(C.THREAD_LIST);
		}
		res = getActivity().getResources();
		setHasOptionsMenu(true);
	}

	@Override
	public View onCreateView(final LayoutInflater inflater,
			final ViewGroup container, final Bundle savedInstanceState) {
		final View rootView = inflater.inflate(R.layout.thread_manager,
				container, false);

		threadlist = (ListView) rootView.findViewById(R.id.threadlist);

		// If there is a saved instance we will immediatly update the view
		// elements
		if (savedInstanceState != null) {
			threads = savedInstanceState
					.getSparseParcelableArray(C.THREAD_LIST);
			for (int i = 0; i < threads.size(); i++) {
				threadsArray.add(threads.valueAt(i));
			}
		} else {
			// Sending a update request to the service.
			final Intent intent = new Intent(C.FILTER);
			intent.putExtra(C.MESSAGE_TYPE, C.UPDATE_REQUEST);
			LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(
					intent);
		}

		adapter = new ThreadListAdapter(getActivity(),
				R.layout.thread_list_item, threadsArray);

		threadlist.setAdapter(adapter);

		((Button) rootView.findViewById(R.id.launchbutton))
		.setOnClickListener(launchThread);

		((Button) rootView.findViewById(R.id.stop_threads))
		.setOnClickListener(stopall);

		return rootView;
	}

	@Override
	public void onDestroy() {
		LocalBroadcastManager.getInstance(getActivity()).unregisterReceiver(
				mMessageReceiver);
		super.onDestroy();
	}

	@Override
	public void onSaveInstanceState(final Bundle outState) {
		outState.putSparseParcelableArray(C.THREAD_LIST, threads);
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
		super.onStop();
	}

	public void updateThreadInfo(final ThreadInfo[] clientinfo) {
		if (serviceRunning) {
			for (final ThreadInfo thread : clientinfo) {
				if (threads.get(thread.threadID) == null) {
					threads.put(thread.threadID, thread);
					threadsArray.add(thread);
				} else {
					if (changed(threads.get(thread.threadID), thread)) {
						threads.get(thread.threadID).update(thread);
					}
				}
			}
			Log.i(C.TAG,
					"Updating Thread list "
							+ Integer.toString(clientinfo.length));
			adapter.notifyDataSetChanged();
		}
	}
}
