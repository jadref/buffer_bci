package bci.donders.nl.signalviewer;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import android.os.Build;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.app.Activity;
import android.view.Menu;
import android.view.Window;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;

import nl.dcc.buffer_bci.SignalProxy;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.Header;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import nl.fcdonders.fieldtrip.bufferserver.BufferServer;
import nl.fcdonders.fieldtrip.bufferserver.SystemOutMonitor;


public class Viewer extends Activity  {

    public static int VERB = 0; // debugging verbosity level
    public long printInterval_ms = 5000; // time between debug prints

    //    protected String processName = TAG;
//    public void setprocessName(String name) {
//        this.processName = name;
//    }
    protected String hostname = "localhost";
    protected int port = 1972;
    protected String endType = "stimulus.test";
    protected String endValue = "end";
    protected String predictionEventType = "classifier.prediction";

    protected double predictionFilter = 1.0;
    protected int timeout_ms = 1000;
    protected boolean normalizeLatitude = true;
    //    protected List<PreprocClassifier> classifiers = null;
    protected BufferClientClock C = null;
    protected int trialLength_ms = -1;
    protected int trialLength_samp = 20;
    protected double overlap = .5;
    protected int step_ms = -1;
    protected int step_samp = -1;
    protected double fs = -1.0;
    protected Header header = null;
    protected boolean run = true;
    SamplesEventsCount status = null;
    int nEvents, nSamples;
    int max_bins = 500;
    int max_plots = 4;
    double[][] D = new double[max_plots][max_bins];
    int index = 0;

    private ArrayList<String> copyAssets() {
        AssetManager assetManager = getAssets();
        String[] files = null;
        ArrayList<String> newfiles = new ArrayList<>();
        try {
            files = assetManager.list("");
        } catch (IOException e) {
//            Log.e("tag", "Failed to get asset file list.", e);
        }
        if (files != null) for (String filename : files) {
            InputStream in = null;
            FileOutputStream out = null;
            try {
                in = assetManager.open(filename);
                File outFile = new File(getExternalFilesDir(null), filename);
                newfiles.add(outFile.getAbsolutePath());
                out = new FileOutputStream(outFile);
                copyFile(in, out);
            } catch(IOException e) {
                System.out.println("Failed to copy asset file: " + filename);
            }
            finally {
                if (in != null) {
                    try {
                        in.close();
                    } catch (IOException e) {
                        // NOOP
                    }
                }
                if (out != null) {
                    try {
                        out.close();
                    } catch (IOException e) {
                        // NOOP
                    }
                }
            }
        }

        return newfiles;
    }
    private void copyFile(InputStream in, FileOutputStream out) throws IOException {
        byte[] buffer = new byte[1024];
        int read;
        while((read = in.read(buffer)) != -1){
            out.write(buffer, 0, read);
        }
    }

    static String convertStreamToString(InputStream is) {
        java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A");
        return s.hasNext() ? s.next() : "";
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB) // API 11
    public static <T> void executeAsyncTask(AsyncTask<T, ?, ?> asyncTask, T... params) {
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB)
            asyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, params);
        else
            asyncTask.execute(params);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        System.out.println("Started");
        super.onCreate(savedInstanceState);
        AsyncTask as = new AsyncTask() {
            @Override
            protected Object doInBackground(Object[] params) {
                System.out.println("Opened proxy2");
                BufferServer buffer = new BufferServer(port);
                buffer.addMonitor(new SystemOutMonitor(0));
                buffer.run();
                buffer.cleanup();
                System.out.println("Opened buffer");
                return null;
            }
        };
        AsyncTask bs = new AsyncTask() {
            @Override
            protected Object doInBackground(Object[] params) {
                try {
                    System.out.println("Opened proxy1");
                    SignalProxy.start_proxy(new String[] {hostname+":"+port});
                    System.out.println("Opened proxy");
                } catch (IOException e) {
                    e.printStackTrace();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                return null;
            }
        };
        executeAsyncTask(as);

        try {
            Thread.sleep(5000);
            System.out.println("podf");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        executeAsyncTask(bs);
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("Done?");

//        System.out.println("Working Directory = " +
//                System.getProperty("user.dir"));
//
//        try {
//            AssetManager assetManager = getAssets();
//            String toPath = "/data/data/";  // Your application path
//            ArrayList<String> files = copyAssets();
//            for (String s : files) {
//                if (s.endsWith("BufferClient.jar"))
//                {
//                    Runtime.getRuntime().exec(new String[]{"java", "-jar", s});
//                }
//            }
////            Process start_signalproxy = Runtime.getRuntime().exec(new String[]{"java", "-jar", "A.jar"});
//        }
//        catch(Exception e)
//        {
//            e.printStackTrace();
//            System.out.println("O NOES.");
//            return;
//        }

        C = new BufferClientClock();

        connect();
        setNullFields();
        nEvents = header.nEvents;
        nSamples = header.nSamples;

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        TruitonBarChartView mView = new TruitonBarChartView(this);
        setContentView(mView);
    }

    /**
     * Connects to the buffer
     */
    protected void connect() {
        while (header == null && run) {
            try {
                System.out.println("Connecting to " + hostname + ":" + port);
                System.out.println("before: "+C.isConnected());
                if (!C.isConnected()) {
                    C.connect(hostname, port);
                }
                //C.setAutoReconnect(true);
                System.out.println("after: "+C.isConnected());
                if (C.isConnected()) {
                    header = C.getHeader();
                }
            } catch (Exception e) {
                e.printStackTrace();
                header = null;
            }
            if (header == null) {
                System.out.println("Invalid Header... waiting");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Array with values in an interval and step size
     *
     * @param start of the interval
     * @param end of the interval
     * @param step size between the values
     * @return int array with size (start - end) / step
     */
    public static int[] range(int start, int end, int step) {
        int size = (int) Math.ceil(((double) (end - start)) / step);
        if (size < 1) {
            return new int[0];
        }
        int[] arr = new int[size];
        int index = 0;
        for (int i = start; i < end; i += step) {
            arr[index] = i;
            index++;
        }
        return arr;
    }

    protected void setNullFields() {
        // Set trial length
        if (header != null) {
            fs = header.fSample;
        } else {
            throw new RuntimeException("First connect to the buffer");
        }

        // Set wait time
        if (step_ms > 0) {
            step_samp = Double.valueOf(Math.round(step_ms / 1000.0 * fs)).intValue();
        } else if (overlap > 0) {
            step_samp = Long.valueOf(Math.round(trialLength_samp * overlap)).intValue();
        }
        if (VERB > 0) {
            System.out.println("trlen_samp=" + trialLength_samp + " step_samp=" + step_samp);
        }
    }

    private void update_data() {
        double[][] dv;
        try {
            if (VERB > 1) {
                System.out.println(" Waiting for " + (nSamples + trialLength_samp + 1) + " samples");
            }
            status = C.waitForSamples(nSamples + trialLength_samp + 1, this.timeout_ms);
        } catch (Exception e) {
            e.printStackTrace();
            // connection to buffer failed = quit
            run = false;
            return;
        }
        if (status.nSamples < nSamples) {
            System.out.println(" Buffer restart detected");
            nSamples = status.nSamples;
            dv = null;
            return;
        }
        // Process any new data
        int onSamples = nSamples;
        int[] startIdx = range(onSamples, status.nSamples - trialLength_samp - 1, step_samp);
//        System.out.println(onSamples + "\t" + trialLength_samp + "\t" + step_samp);
//        System.out.println(Arrays.toString(startIdx));
        if (startIdx.length > 0) {
            nSamples = startIdx[startIdx.length - 1] + step_samp;
        }

        for (int fromId : startIdx) {
            // Get the data
            int toId = fromId + trialLength_samp - 1;
            double[][] data = null;
            try {
                data = C.getDoubleData(fromId, toId);
                for (int j = 0; j < data.length; j++) {
                    for (int i = 0; i < max_plots; i++) {
                        D[i][index] = data[j][i];
                    }
                    index++;
                    index = index % max_bins;
                }
            } catch (Exception e) {
                e.printStackTrace();
                continue;
            }
            if (VERB > 1) {
                System.out.println(String.format(" Got data @ %d->%d samples", fromId, toId));
            }
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
//        getMenuInflater().inflate(R.menu.truiton_main, menu);
        return false;
    }
}
