package nl.dcc.fieldtripbuffer.fragments;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.EditText;

import nl.dcc.fieldtripbuffer.BufferService;
import nl.dcc.fieldtripbuffer.C;
import nl.dcc.fieldtripbuffer.R;

public class StartBufferFragment extends Fragment {
	OnClickListener startBuffer = new OnClickListener() {
		@Override
		public void onClick(final View v) {
			// Create Intent for starting the buffer.
			final Intent intent = new Intent(getActivity(), BufferService.class);

			if (getView() == null) {
				return;
			}

			// Grab port number and add to intent.
			final EditText editTextPort = (EditText) getView().findViewById(
					R.id.fragment_startbuffer_port);
			try {
				intent.putExtra("port",
						Integer.parseInt(editTextPort.getText().toString()));
			} catch (final NumberFormatException e) {
				intent.putExtra("port", 1972);
			}

			// Grab nSamples and add to intent.
			final EditText editTextnSamples = (EditText) getView()
					.findViewById(R.id.fragment_startbuffer_nSamples);
			try {
				intent.putExtra("nSamples",
						Integer.parseInt(editTextnSamples.getText().toString()));
			} catch (final NumberFormatException e) {
				intent.putExtra("nSamples", 10000);
			}

			// Grab nEvents and add to intent.
			final EditText editTextnEvents = (EditText) getView().findViewById(
					R.id.fragment_startbuffer_nEvents);
			try {
				intent.putExtra("nEvents",
						Integer.parseInt(editTextnEvents.getText().toString()));
			} catch (final NumberFormatException e) {
				intent.putExtra("nEvents", 1000);
			}

			// Start the buffer.
			Log.i(C.TAG, "Attempting to start Buffer Service");
			getActivity().startService(intent);

			// Replace this fragment with the RunningBuffer Fragment.

			// Create a fragment transaction
			final FragmentTransaction transaction = getFragmentManager()
					.beginTransaction();

			// Replace current fragment with a new RunningBuffer fragment
			transaction.replace(R.id.activity_main_container,
					new RunningBufferFragment());

			transaction
			.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
			// Commit the transaction
			transaction.commit();
		}
	};

	@Override
	public View onCreateView(final LayoutInflater inflater,
			final ViewGroup container, final Bundle savedInstanceState) {
		final View rootView = inflater.inflate(R.layout.fragment_startbuffer,
				container, false);

		rootView.findViewById(R.id.fragment_startbuffer_start)
		.setOnClickListener(startBuffer);

		return rootView;
	}
}
