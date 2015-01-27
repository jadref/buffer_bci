package com.dcc.fieldtripbuffer.fragments;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import android.content.Context;
import android.content.res.Resources;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import com.dcc.fieldtripbuffer.C;
import com.dcc.fieldtripbuffer.R;
import com.dcc.fieldtripbuffer.monitor.ClientInfo;

public class ClientInfoAdapter extends ArrayAdapter {
	private final static CharSequence getStatusText(final ClientInfo client,
			final Resources res) {

		String status = "";

		if (client.error != C.ERROR_NONE) {
			switch (client.error) {
			case C.ERROR_PROTOCOL:
				status = res.getString(R.string.error_protocol);
				break;
			case C.ERROR_VERSION:
				status = res.getString(R.string.error_version);
				break;
			case C.ERROR_CONNECTION:
				status = res.getString(R.string.error_connection);
				break;
			}

		}

		switch (client.lastActivity) {
		case C.CONNECTED:
			status = res.getString(R.string.client_connected);
			break;
		case C.DISCONNECTED:
			status = res.getString(R.string.client_disconnected);
			break;
		case C.GOTSAMPLES:
			status = String.format(res.getString(R.string.client_gotsamples),
					client.diff);
			break;
		case C.GOTEVENTS:
			status = String.format(res.getString(R.string.client_gotevents),
					client.diff);
			break;
		case C.GOTHEADER:
			status = res.getString(R.string.client_gotheader);
			break;
		case C.PUTSAMPLES:
			status = String.format(res.getString(R.string.client_putsamples),
					client.diff);
			break;
		case C.PUTEVENTS:
			status = String.format(res.getString(R.string.client_putevents),
					client.diff);
			break;
		case C.PUTHEADER:
			status = res.getString(R.string.client_putheader);
			break;
		case C.FLUSHSAMPLES:
			status = res.getString(R.string.client_flushedsamples);
			break;
		case C.FLUSHEVENTS:
			status = res.getString(R.string.client_flushedevents);
			break;
		case C.FLUSHHEADER:
			status = res.getString(R.string.client_flushheader);
			break;
		case C.POLL:
			status = res.getString(R.string.client_poll);
			break;
		case C.WAIT:
			status = String.format(res.getString(R.string.client_wait),
					client.waitSamples, client.waitEvents, client.waitTimeout);
			break;
		case C.STOPWAITING:
			status = res.getString(R.string.client_stopwaiting);
			break;
		}

		return hourMinSec.format(new Date(client.timeLastActivity)) + " "
				+ status;
	}

	private final Context context;
	private final List<ClientInfo> clientinfo;

	private static final SimpleDateFormat hourMinSec = new SimpleDateFormat(
			"hh:mm:ss");
	private static final SimpleDateFormat hourMin = new SimpleDateFormat(
			"hh:mm");

	public ClientInfoAdapter(final Context context, final int resource,
			final List<ClientInfo> objects) {
		super(context, resource, objects);
		this.context = context;
		clientinfo = objects;
	}

	@Override
	public View getView(final int position, final View convertView,
			final ViewGroup parent) {
		final LayoutInflater inflater = (LayoutInflater) context
				.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		final View view = inflater.inflate(R.layout.clientinfo_list_item,
				parent, false);

		final ClientInfo client = clientinfo.get(position);
		final Resources res = context.getResources();

		final TextView adress = (TextView) view
				.findViewById(R.id.clientinfo_list_item_adress);
		final TextView time = (TextView) view
				.findViewById(R.id.clientinfo_list_item_time);
		final TextView status = (TextView) view
				.findViewById(R.id.clientinfo_list_item_status);

		adress.setText(client.adress);

		if (client.connected) {
			time.setText(res.getString(R.string.connected) + " "
					+ hourMin.format(new Date(client.time)));
		} else {
			time.setText(res.getString(R.string.disconnected) + " "
					+ hourMin.format(new Date(client.time)));
		}

		status.setText(getStatusText(client, res));

		return view;
	}
}
