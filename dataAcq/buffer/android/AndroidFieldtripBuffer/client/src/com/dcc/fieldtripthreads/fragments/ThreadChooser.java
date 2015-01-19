package com.dcc.fieldtripthreads.fragments;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import com.dcc.fieldtripthreads.C;
import com.dcc.fieldtripthreads.R;
import com.dcc.fieldtripthreads.base.ThreadBase;
import com.dcc.fieldtripthreads.threads.ThreadList;

public class ThreadChooser extends Fragment {
	ListView threadlist;

	@Override
	public View onCreateView(final LayoutInflater inflater,
			final ViewGroup container, final Bundle savedInstanceState) {
		final View rootView = inflater.inflate(R.layout.thread_chooser,
				container, false);

		threadlist = (ListView) rootView
				.findViewById(R.id.threads_chooser_list);

		String[] names = new String[ThreadList.list.length];

		for (int i = 0; i < names.length; i++) {
			ThreadBase tb;
			try {
				tb = (ThreadBase) ThreadList.list[i].newInstance();
				names[i] = tb.getName();
			} catch (java.lang.InstantiationException | IllegalAccessException e) {
				Log.e(C.TAG, "Couldn't instantiate class!");
			}
		}

		ArrayAdapter<String> adapter = new ArrayAdapter<String>(getActivity(),
				android.R.layout.simple_list_item_1, names);

		threadlist.setAdapter(adapter);

		threadlist.setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(final AdapterView<?> arg0, final View arg1,
					final int position, final long arg3) {
				Bundle bundle = new Bundle();
				bundle.putInt(C.THREAD_INDEX, position);
				ThreadArguments newFragment = new ThreadArguments();
				newFragment.setArguments(bundle);
				final FragmentTransaction transaction = getFragmentManager()
						.beginTransaction();

				transaction.replace(R.id.activity_main_container, newFragment);
				transaction
						.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
				transaction.addToBackStack(null);
				transaction.commit();
			}

		});

		return rootView;
	}
}
