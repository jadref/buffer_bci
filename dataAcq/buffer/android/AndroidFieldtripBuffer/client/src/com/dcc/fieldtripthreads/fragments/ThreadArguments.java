package com.dcc.fieldtripthreads.fragments;

import java.util.ArrayList;

import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.text.InputType;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.dcc.fieldtripthreads.C;
import com.dcc.fieldtripthreads.R;
import com.dcc.fieldtripthreads.ThreadService;
import com.dcc.fieldtripthreads.base.Argument;
import com.dcc.fieldtripthreads.base.ThreadBase;
import com.dcc.fieldtripthreads.threads.ThreadList;

public class ThreadArguments extends Fragment {
	ListView threadlist;
	ArrayList<Object> argumentViews;
	ArrayList<TextView> warnings;
	Argument[] arguments;
	ThreadBase thread;
	int index;

	OnClickListener accept = new OnClickListener() {

		@Override
		public void onClick(final View arg0) {
			updateArguments();
			for (Argument a : arguments) {
				a.validate();
			}
			thread.validateArguments(arguments);
			updateWarnings();
			for (Argument a : arguments) {
				if (a.isInvalid()) {
					return;
				}
			}

			final Intent intent = new Intent(getActivity(), ThreadService.class);
			intent.putExtra(C.THREAD_INDEX, index);
			intent.putExtra(C.N_ARGUMENTS, arguments.length);
			for (int i = 0; i < arguments.length; i++) {
				intent.putExtra(C.THREAD_ARGUMENTS + i, arguments[i]);
			}
			getActivity().startService(intent);

			final FragmentTransaction transaction = getFragmentManager()
					.beginTransaction();

			transaction.replace(R.id.activity_main_container,
					new ThreadManager());
			transaction
			.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_FADE);
			getFragmentManager().popBackStack(null,
					FragmentManager.POP_BACK_STACK_INCLUSIVE);
			getFragmentManager().popBackStack(null,
					FragmentManager.POP_BACK_STACK_INCLUSIVE);
			transaction.commit();

		}

	};

	@Override
	public View onCreateView(final LayoutInflater inflater,
			final ViewGroup container, final Bundle savedInstanceState) {
		final View rootView = inflater.inflate(R.layout.thread_arguments,
				container, false);

		index = getArguments().getInt(C.THREAD_INDEX);

		Resources res = getActivity().getResources();
		try {
			thread = (ThreadBase) ThreadList.list[index].newInstance();

			LinearLayout layout = (LinearLayout) rootView
					.findViewById(R.id.thead_argument_layout);

			ImageButton button = (ImageButton) rootView
					.findViewById(R.id.thread_argument_accept);

			button.setOnClickListener(accept);

			TextView title = (TextView) rootView
					.findViewById(R.id.thread_argument_title);

			title.setText(thread.getName() + " "
					+ res.getString(R.string.thread_argument_title));

			argumentViews = new ArrayList<Object>();
			warnings = new ArrayList<TextView>();
			arguments = thread.getArguments();
			for (Argument a : arguments) {
				View argumentView = null;
				int type = a.getType();
				if (type == Argument.TYPE_BOOLEAN) {
					argumentView = inflater.inflate(R.layout.argument_boolean,
							layout, false);
					ToggleButton boolSwitch = (ToggleButton) argumentView
							.findViewById(R.id.argument_togglebutton);
					if (a.getBoolean()) {
						boolSwitch.toggle();
					}
					argumentViews.add(boolSwitch);
				} else if (type == Argument.TYPE_RADIO) {
					argumentView = inflater.inflate(R.layout.argument_radio,
							layout, false);
					RadioGroup group = (RadioGroup) argumentView
							.findViewById(R.id.argument_radiogroup);
					String[] options = a.getOptions();
					RadioButton[] buttons = new RadioButton[options.length];

					for (int i = 0; i < options.length; i++) {
						buttons[i] = new RadioButton(getActivity());
						buttons[i].setText(options[i]);
						group.addView(buttons[i]);
					}
					buttons[a.getInteger()].toggle();
					argumentViews.add(buttons);
				} else if (type == Argument.TYPE_CHECK) {
					argumentView = inflater.inflate(R.layout.argument_check,
							layout, false);
					LinearLayout group = (LinearLayout) argumentView
							.findViewById(R.id.argument_checkgroup);
					String[] options = a.getOptions();
					CheckBox[] buttons = new CheckBox[options.length];
					boolean[] checked = a.getChecked();

					for (int i = 0; i < options.length; i++) {
						buttons[i] = new CheckBox(getActivity());
						buttons[i].setText(options[i]);
						group.addView(buttons[i]);
						if (i < checked.length) {
							if (checked[i]) {
								buttons[i].toggle();
							}
						}
					}
					argumentViews.add(buttons);
				} else {
					argumentView = inflater.inflate(R.layout.argument_string,
							layout, false);
					EditText text = (EditText) argumentView
							.findViewById(R.id.argument_value);
					argumentViews.add(text);
					switch (a.getType()) {
					case Argument.TYPE_STRING:
						text.setText(a.getString());
						break;
					case Argument.TYPE_INTEGER_SIGNED:
						text.setText(Integer.toString(a.getInteger()));
						text.setInputType(InputType.TYPE_CLASS_NUMBER
								| InputType.TYPE_NUMBER_FLAG_SIGNED);
						break;
					case Argument.TYPE_INTEGER_UNSIGNED:
						text.setText(Integer.toString(a.getInteger()));
						text.setInputType(InputType.TYPE_CLASS_NUMBER);
						break;
					case Argument.TYPE_DOUBLE_SIGNED:
						text.setText(Double.toString(a.getDouble()));
						text.setInputType(InputType.TYPE_CLASS_NUMBER
								| InputType.TYPE_NUMBER_FLAG_SIGNED
								| InputType.TYPE_NUMBER_FLAG_DECIMAL);
						break;
					case Argument.TYPE_DOUBLE_UNSIGNED:
						text.setText(Double.toString(a.getDouble()));
						text.setInputType(InputType.TYPE_CLASS_NUMBER
								| InputType.TYPE_NUMBER_FLAG_DECIMAL);
						break;
					}
				}

				TextView description = (TextView) argumentView
						.findViewById(R.id.argument_description);
				warnings.add((TextView) argumentView
						.findViewById(R.id.argument_warning));

				description.setText(a.getDescription());

				layout.addView(argumentView);
			}

		} catch (java.lang.InstantiationException | IllegalAccessException e) {
			Log.e(C.TAG, "Failed to instantiate class in ThreadArguments!");

			TextView title = (TextView) rootView
					.findViewById(R.id.thread_argument_title);

			title.setText(thread.getName() + "Could not instantiate "
					+ res.getString(R.string.thread_argument_title));
		} catch (Exception e) {
			TextView title = (TextView) rootView
					.findViewById(R.id.thread_argument_title);

			title.setText(thread.getName() + "Wrong arguments received "
					+ res.getString(R.string.thread_argument_title));
		}

		return rootView;
	}

	private void updateArguments() {
		for (int index = 0; index < arguments.length; index++) {
			Argument a = arguments[index];
			int type = a.getType();
			if (type == Argument.TYPE_BOOLEAN) {
				ToggleButton boolSwitch = (ToggleButton) argumentViews
						.get(index);
				a.setValue(boolSwitch.isChecked());

			} else if (type == Argument.TYPE_RADIO) {
				RadioButton[] buttons = (RadioButton[]) argumentViews
						.get(index);

				for (int i = 0; i < buttons.length; i++) {
					if (buttons[i].isChecked()) {
						a.setValue(i);
						break;
					}
				}

			} else if (type == Argument.TYPE_CHECK) {
				CheckBox[] buttons = (CheckBox[]) argumentViews.get(index);
				boolean[] checked = new boolean[buttons.length];

				for (int i = 0; i < buttons.length; i++) {
					checked[i] = buttons[i].isChecked();
				}
				a.setValue(checked);
			} else {
				String text = ((EditText) argumentViews.get(index)).getText()
						.toString();
				try {
					switch (a.getType()) {
					case Argument.TYPE_STRING:
						a.setValue(text);
						break;
					case Argument.TYPE_INTEGER_SIGNED:
					case Argument.TYPE_INTEGER_UNSIGNED:
						a.setValue(Integer.parseInt(text));
						break;
					case Argument.TYPE_DOUBLE_SIGNED:
					case Argument.TYPE_DOUBLE_UNSIGNED:
						a.setValue(Double.parseDouble(text));
						break;
					}
				} catch (NumberFormatException e) {
					a.invalidate("Please enter a number.");
				}
			}
		}

	}

	private void updateWarnings() {
		for (int i = 0; i < arguments.length; i++) {
			TextView warning = warnings.get(i);
			Argument argument = arguments[i];
			if (argument.isInvalid() && warning.getVisibility() == View.GONE) {
				warning.setText(argument.getInvalidationMessage());
				warning.setVisibility(View.VISIBLE);
			} else if (argument.isValid()
					&& warning.getVisibility() == View.VISIBLE) {
				warning.setVisibility(View.GONE);
			}
		}

	}
}
