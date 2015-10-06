package nl.dcc.fieldtripthreads;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;

import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiManager.WifiLock;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;
import android.os.PowerManager.WakeLock;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.TaskStackBuilder;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.util.SparseArray;
import android.widget.Toast;

import nl.dcc.fieldtripthreads.base.AndroidHandle;
import nl.dcc.fieldtripthreads.base.Argument;
import nl.dcc.fieldtripthreads.base.ThreadBase;
import nl.dcc.fieldtripthreads.threads.ThreadList;

public class ThreadService extends Service {

	private class Handle implements AndroidHandle {
		private final Context context;
		private final int threadID;

		public Handle(final Context context, final int threadID) {
			this.context = context;
			this.threadID = threadID;
		}

		@Override
		public FileInputStream openReadFile(final String path)
				throws IOException {
			if (isExternalStorageReadable()) {
				return new FileInputStream(new File(
						Environment.getExternalStorageDirectory(), path));
			} else {
				throw new IOException("Could not open external storage.");
			}
		}

		@Override
		public FileOutputStream openWriteFile(final String path)
				throws IOException {
			if (isExternalStorageWritable()) {
				return new FileOutputStream(new File(
						Environment.getExternalStorageDirectory(), path));
			} else {
				throw new IOException("Could not open external storage.");
			}
		}

		@Override
		public void toast(final String message) {
			makeToast(message, Toast.LENGTH_SHORT);
		}

		@Override
		public void toastLong(final String message) {
			makeToast(message, Toast.LENGTH_LONG);
		}

		@Override
		public void updateStatus(final String status) {
			synchronized (threadInfo) {
				threadInfo.get(threadID).status = status;
			}
		}
	}

	private class Updater extends Thread {

		private boolean run = true;
		private final Context context;

		public Updater(final Context context) {
			this.context = context;
		}

		@Override
		public void run() {
			while (run) {
				try {
					Thread.sleep(1000);
					sendUpdates();
				} catch (InterruptedException e) {
				}
			}
		}

		private void sendUpdates() {
			final Intent intent = new Intent(C.FILTER);
			intent.putExtra(C.MESSAGE_TYPE, C.UPDATE);

			ThreadInfo[] p = new ThreadInfo[threadInfo.size()];

			for (int i = 0; i < threadInfo.size(); i++) {
				p[i] = threadInfo.valueAt(i);
				p[i].running = wrappers.valueAt(i).isAlive();
			}

			intent.putExtra(C.THREAD_LIST, p);
			LocalBroadcastManager.getInstance(context).sendBroadcast(intent);

		}

		public void stopUpdating() {
			run = false;
		}
	}

	private class WrapperThread extends Thread {

		public final ThreadBase base;

		public WrapperThread(final ThreadBase base) {
			this.base = base;
			setName(base.getName());
		}

		@Override
		public void run() {
			Looper.prepare();
			try {
				base.mainloop();
			} catch (Exception e) {
				handleException(e, base);
			}
		}
	}

	private final SparseArray<ThreadBase> threads = new SparseArray<ThreadBase>();

	private final SparseArray<WrapperThread> wrappers = new SparseArray<WrapperThread>();

	private final SparseArray<ThreadInfo> threadInfo = new SparseArray<ThreadInfo>();

	private WakeLock wakeLock;
	private WifiLock wifiLock;
	private int nextId = 0;
	private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(final Context context, final Intent intent) {
			int id;
			switch (intent.getIntExtra(C.MESSAGE_TYPE, -1)) {
			case C.THREAD_STOP:
				id = intent.getIntExtra(C.THREAD_ID, -1);
				if (id != -1) {
					threads.get(id).stop();
					threads.remove(id);
					wrappers.remove(id);
					threadInfo.remove(id);
				}
				break;
			case C.THREAD_PAUSE:
				id = intent.getIntExtra(C.THREAD_ID, -1);
				threads.get(id).stop();
				break;
			case C.THREAD_START:
				id = intent.getIntExtra(C.THREAD_ID, -1);
				wrappers.get(id).start();
			default:
			}
		}

	};

	private Updater updater;

	private final Handler handler = new Handler();

	public void handleException(final Exception e, final ThreadBase base) {
		makeToast(base.getName() + " crashed!", Toast.LENGTH_LONG);
		try {
			if (isExternalStorageWritable()) {

				PrintWriter writer = new PrintWriter(new FileOutputStream(
						new File(Environment.getExternalStorageDirectory(),
								"Stack_trace_" + base.getName())));

				e.printStackTrace(writer);
				writer.flush();
				makeToast(
						"Stack trace written to " + "Stack_trace_"
								+ base.getName(), Toast.LENGTH_LONG);

			} else {

				throw new IOException("Could not open external storage.");
			}
		} catch (IOException e1) {
			makeToast("Failed to write stack trace!", Toast.LENGTH_LONG);
		}
	}

	/* Checks if external storage is available to at least read */
	public boolean isExternalStorageReadable() {
		String state = Environment.getExternalStorageState();
		if (Environment.MEDIA_MOUNTED.equals(state)
				|| Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
			return true;
		}
		return false;
	}

	/* Checks if external storage is available for read and write */
	public boolean isExternalStorageWritable() {
		String state = Environment.getExternalStorageState();
		if (Environment.MEDIA_MOUNTED.equals(state)) {
			return true;
		}
		return false;
	}

	private void makeToast(final String message, final int duration) {
		Runnable r = new Runnable() {
			@Override
			public void run() {
				Toast.makeText(getApplicationContext(), message, duration)
				.show();
			}
		};

		handler.post(r);
	}

	@Override
	public IBinder onBind(final Intent intent) {
		return null;
	}

	/**
	 * Called when the service is stopped. Stops the buffer.
	 */
	@Override
	public void onDestroy() {
		Log.i(C.TAG, "Stopping Thread Service.");

		if (wakeLock != null) {
			wakeLock.release();
		}
		if (wifiLock != null) {
			wifiLock.release();
		}
		if (updater != null) {
			updater.stopUpdating();
		}
		for (int i = 0; i < threadInfo.size(); i++) {
			int id = threadInfo.valueAt(i).threadID;
			try {
				threads.get(id).stop();
			} catch (Exception e) {
				handleException(e, threads.get(id));
			}
		}

		final Intent intent = new Intent(C.FILTER);
		intent.putExtra(C.MESSAGE_TYPE, C.SERVICE_STOPPED);
		LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
		LocalBroadcastManager.getInstance(this).unregisterReceiver(
				mMessageReceiver);
	}

	@Override
	public int onStartCommand(final Intent intent, final int flags,
			final int startId) {

		if (wakeLock == null && wifiLock == null) {
			updater = new Updater(this);
			updater.start();
			final int port = intent.getIntExtra("port", 1972);
			// Get Wakelocks

			final PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
			wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,
					C.WAKELOCKTAG);
			wakeLock.acquire();

			final WifiManager wifiMan = (WifiManager) getSystemService(WIFI_SERVICE);
			wifiLock = wifiMan.createWifiLock(C.WAKELOCKTAGWIFI);
			wifiLock.acquire();

			// Create Foreground Notification

			// Create notification text
			final Resources res = getResources();
			final String notification_text = res
					.getString(R.string.notification_text);

			final NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(
					this)
			.setSmallIcon(R.drawable.ic_launcher)
			.setContentTitle(res.getString(R.string.notification_title))
			.setContentText(notification_text);

			// Creates an intent for when the notification is clicked
			final Intent resultIntent = new Intent(this, MainActivity.class);

			// Creates a backstack so hitting back would return the user to the
			// home screen.
			final TaskStackBuilder stackBuilder = TaskStackBuilder.create(this);
			// Adds the back stack for the Intent (but not the Intent itself)
			stackBuilder.addParentStack(MainActivity.class);
			// Adds the Intent that starts the Activity to the top of the stack
			stackBuilder.addNextIntent(resultIntent);
			final PendingIntent resultPendingIntent = stackBuilder
					.getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT);
			mBuilder.setContentIntent(resultPendingIntent);

			// Turn this service into a foreground service
			startForeground(1, mBuilder.build());
			Log.i(C.TAG, "Fieldtrip Thread Service moved to foreground.");

			// Add message listener
			LocalBroadcastManager.getInstance(this).registerReceiver(
					mMessageReceiver, new IntentFilter(C.FILTER));
		}

		startThread(intent);
		return START_NOT_STICKY;
	}

	private void startThread(final Intent intent) {
		int index = intent.getIntExtra(C.THREAD_INDEX, -1);

		int nArgs = intent.getIntExtra(C.N_ARGUMENTS, 0);

		Argument[] arguments = new Argument[nArgs];

		for (int i = 0; i < nArgs; i++) {
			arguments[i] = (Argument) intent
					.getSerializableExtra(C.THREAD_ARGUMENTS + i);
		}

		Class c = ThreadList.list[index];

		try {

			ThreadBase thread = (ThreadBase) c.newInstance();
			try {
				thread.setArguments(arguments);
				thread.setHandle(new Handle(this, nextId));
			} catch (Exception e) {
				handleException(e, thread);
			}
			threads.put(nextId, thread);
			WrapperThread wrapper = new WrapperThread(thread);
			wrappers.put(nextId, wrapper);

			threadInfo.put(nextId, new ThreadInfo(nextId, wrapper.getName(),
					"", true));

			wrapper.start();
			nextId = nextId + 1;

		} catch (InstantiationException | IllegalAccessException e) {
			// TODO Auto-generated catch block
			Log.w(C.TAG, "Instantiation failed!");

		}
	}
}
