package nl.dcc.fieldtripthreads;

import android.app.ActivityManager;
import android.app.ActivityManager.RunningServiceInfo;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;

import nl.dcc.fieldtripthreads.fragments.ThreadChooser;
import nl.dcc.fieldtripthreads.fragments.ThreadManager;

public class MainActivity extends ActionBarActivity {
	private boolean isThreadServiceRunning() {
		final ActivityManager manager = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
		for (final RunningServiceInfo service : manager
				.getRunningServices(Integer.MAX_VALUE)) {
			if (ThreadService.class.getName().equals(
					service.service.getClassName())) {
				return true;
			}
		}
		return false;
	}

	@Override
	protected void onCreate(final Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		if (savedInstanceState == null) {
			if (isThreadServiceRunning()) {
				getSupportFragmentManager().beginTransaction()
						.add(R.id.activity_main_container, new ThreadManager())
						.commit();
			} else {
				getSupportFragmentManager().beginTransaction()
				.add(R.id.activity_main_container, new ThreadChooser())
				.commit();
			}
		}
	}

}
