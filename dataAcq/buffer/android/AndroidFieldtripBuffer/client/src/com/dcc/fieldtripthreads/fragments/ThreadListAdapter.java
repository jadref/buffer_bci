package com.dcc.fieldtripthreads.fragments;

import java.text.SimpleDateFormat;
import java.util.List;

import android.content.Context;
import android.content.res.Resources;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageButton;
import android.widget.TextView;

import com.dcc.fieldtripthreads.R;
import com.dcc.fieldtripthreads.ThreadInfo;

public class ThreadListAdapter extends ArrayAdapter {
	private final Context context;
	private final List<ThreadInfo> threadinfo;

	private static final SimpleDateFormat hourMinSec = new SimpleDateFormat(
			"hh:mm:ss");
	private static final SimpleDateFormat hourMin = new SimpleDateFormat(
			"hh:mm");

	public ThreadListAdapter(final Context context, final int resource,
			final List<ThreadInfo> objects) {
		super(context, resource, objects);
		this.context = context;
		threadinfo = objects;
	}

	@Override
	public View getView(final int position, final View convertView,
			final ViewGroup parent) {
		final LayoutInflater inflater = (LayoutInflater) context
				.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		final View view = inflater.inflate(R.layout.thread_list_item, parent,
				false);

		final ThreadInfo thread = threadinfo.get(position);
		final Resources res = context.getResources();

		final TextView title = (TextView) view.findViewById(R.id.threadname);
		final TextView status = (TextView) view.findViewById(R.id.threadstatus);
		final ImageButton button = (ImageButton) view
				.findViewById(R.id.threadbutton);

		title.setText(thread.title);
		status.setText(thread.status);

		if (thread.running) {
			button.setImageDrawable(res.getDrawable(R.drawable.ic_action_play));
		} else {
			button.setImageDrawable(res.getDrawable(R.drawable.ic_action_pause));
		}

		return view;
	}
}
