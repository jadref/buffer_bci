/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package signalviewer;

import com.orsoncharts.marker.Marker;
import java.awt.BasicStroke;
import java.awt.BorderLayout;
import java.awt.Color;
import java.io.IOException;
import javax.swing.BoxLayout;
import javax.swing.JFrame;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.Header;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.XYPlot;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

/**
 *
 * @author H.G. van den Boorn
 */
public class SignalViewer extends JFrame {
//    protected static final String TAG = ContinuousClassifier.class.getSimpleName();

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
    ChartPanel[] panels = new ChartPanel[4];

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws InterruptedException {
        SignalViewer S = new SignalViewer();
    }

    public SignalViewer() throws InterruptedException {
        C = new BufferClientClock();

        connect();
        setNullFields();
        nEvents = header.nEvents;
        nSamples = header.nSamples;
        getPlot();

        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        this.getContentPane().setLayout(new BoxLayout(getContentPane(), BoxLayout.PAGE_AXIS));
        for (int i = 0; i < max_plots; i++) {
            this.getContentPane().add(panels[i]);
        }
        this.pack();
        this.setVisible(true);

        while (true) {
//            for (int i = 0; i < max_plots; i++) {
//                this.getContentPane().remove(panels[i]);
//            }
            getPlot();
            for (int i = 0; i < max_plots; i++) {
                panels[i].setMaximumDrawHeight(400);
            }
//            this.pack();
            this.revalidate();
            this.repaint();
//            Thread.sleep(50);
        }
    }

    /**
     * Connects to the buffer
     */
    protected void connect() {
        while (header == null && run) {
            try {
                System.out.println("Connecting to " + hostname + ":" + port);
                if (!C.isConnected()) {
                    C.connect(hostname, port);
                }
                //C.setAutoReconnect(true);
                if (C.isConnected()) {
                    header = C.getHeader();
                }
            } catch (IOException e) {
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
        } catch (IOException e) {
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
//                    for (double[] ar : data) {

//                    }
                }
//                Matrix A = new Matrix(B);
//                data = new Matrix(A.transpose());
            } catch (IOException e) {
                e.printStackTrace();
                continue;
            }
            if (VERB > 1) {
                System.out.println(String.format(" Got data @ %d->%d samples", fromId, toId));
            }

//            // Apply all classifiers and add results
//            Matrix f = new Matrix(classifiers.get(0).getOutputSize(), 1);
//            Matrix fraw = new Matrix(classifiers.get(0).getOutputSize(), 1);
//            ClassifierResult result = null;
//            for (PreprocClassifier c : classifiers) {
//                result = c.apply(data);
//                f = new Matrix(f.add(result.f));    // accumulate predictions over classifiers
//                fraw = new Matrix(fraw.add(result.fraw));
//            }
        }

//        // Deal with new events
//        if (status.nEvents > nEvents) {
//            BufferEvent[] events = null;
//            try {
//                events = C.getEvents(nEvents, status.nEvents - 1);
//            } catch (IOException e) {
//                e.printStackTrace();
//            }
//
//            for (BufferEvent event : events) {
//                String type = event.getType().toString();
//                String value = event.getValue().toString();
//                if (VERB > 1) {
//                    System.out.println(TAG + "got(" + event + ")");
//                }
//                if (type.equals(endType) && value.equals(endValue)) {
//                    if (VERB > 1) {
//                        System.out.println(TAG + "Got end event. Exiting!");
//                    }
//                    endEvent = true;
//                }
//            }
//            nEvents = status.nEvents;
//        }
    }

    private void getPlot() {
        update_data();

//        ChartPanel[] panels = new ChartPanel[max_plots];
        for (int j = 0; j < max_plots; j++) {
            XYSeries series = new XYSeries("Planned");
            for (int i = 0; i < max_bins; i++) {
                series.add((double) i, D[j][i]);
            }

            XYSeriesCollection dataset = new XYSeriesCollection();
            dataset.addSeries(series);
            JFreeChart chart = ChartFactory.createXYLineChart("Line Chart Demo", "X", "Y", dataset);
            chart.setTitle("");
            chart.removeLegend();
            XYPlot plot = (XYPlot) chart.getPlot();

// draw a horizontal line across the chart at y == 0
//        plot.addRangeMarker(new Marker(0, Color.red, new BasicStroke(1), Color.red, 1f));
//            ChartPanel panel = new ChartPanel(chart);
            if (panels[j] == null) {
                panels[j] = new ChartPanel(chart);
            } else {
                panels[j].setChart(chart);
//                panels[j].setMaximumDrawHeight(200);
                panels[j].revalidate();
                panels[j].repaint();
            }
//            panels[j] = panel;
        }
//        return panels;
    }
}
