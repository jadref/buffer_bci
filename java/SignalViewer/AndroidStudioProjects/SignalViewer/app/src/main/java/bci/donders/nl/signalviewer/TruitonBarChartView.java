/* ===========================================================
 * AFreeChart : a free chart library for Android(tm) platform.
 *              (based on JFreeChart and JCommon)
 * ===========================================================
 * Original Author:  Niwano Masayoshi (for ICOMSYSTECH Co.,Ltd);
 * Contributor(s):   Mohit Gupt;
 *
 * Changes
 * -------
 * 19-Nov-2010 : Version 0.0.1 (NM);
 * 31-Mar-2013 : Restructuring
 */

package bci.donders.nl.signalviewer;

import org.afree.chart.ChartFactory;
import org.afree.chart.AFreeChart;
import org.afree.chart.axis.CategoryAxis;
import org.afree.chart.axis.CategoryLabelPositions;
import org.afree.chart.axis.NumberAxis;
import org.afree.chart.plot.CategoryPlot;
import org.afree.chart.plot.PlotOrientation;
import org.afree.chart.renderer.category.BarRenderer;
import org.afree.data.category.CategoryDataset;
import org.afree.data.category.DefaultCategoryDataset;
import org.afree.data.xy.DefaultXYDataset;
import org.afree.data.xy.XYDataset;
import org.afree.data.xy.XYSeries;
import org.afree.data.xy.XYSeriesCollection;
import org.afree.graphics.GradientColor;
import org.afree.graphics.SolidColor;

import android.content.Context;
import android.graphics.Color;

public class TruitonBarChartView extends DemoView {

    /**
     * constructor
     * @param context
     */
    public TruitonBarChartView(Context context) {
        super(context);

        XYDataset dataset = createDataset();
        AFreeChart chart = createChart(dataset);

        setChart(chart);
    }

    /**
     * Returns a sample dataset.
     *
     * @return The dataset.
     */
    private static XYDataset createDataset() {

        XYSeries series = new XYSeries("London Temperature hourly");
        int hour = 0;
        for (int i=0; i<24; i++) {
            series.add(hour++, Math.sin(i));
        }

        XYSeriesCollection ds = new XYSeriesCollection();
        ds.addSeries(series);
        return ds;
    }

    /**
     * Creates a sample chart.
     *
     * @param dataset  the dataset.
     *
     * @return The chart.
     */
    private static AFreeChart createChart(XYDataset dataset) {

        // create the chart...
//        AFreeChart chart = ChartFactory.createBarChart(
//                "Truiton's Performance by AFreeChart Bar Chart",      // chart title
//                "Year",               // domain axis label
//                "Sales/Expenses",         // range axis label
//                dataset,                  // data
//                PlotOrientation.VERTICAL, // orientation
//                true,                     // include legend
//                true,                     // tooltips?
//                false                     // URLs?
//        );
        AFreeChart chart = ChartFactory.createXYLineChart(
                "Truiton's Performance by AFreeChart Bar Chart",      // chart title
                "Year",               // domain axis label
                "Sales/Expenses",         // range axis label
                dataset,                  // data
                PlotOrientation.VERTICAL, // orientation
                true,                     // include legend
                true,                     // tooltips?
                false
        );
//        // NOW DO SOME OPTIONAL CUSTOMISATION OF THE CHART...
//
//        // set the background color for the chart...
//        chart.setBackgroundPaintType(new SolidColor(Color.WHITE));
//
//        // get a reference to the plot for further customisation...
//        CategoryPlot plot = (CategoryPlot) chart.getPlot();
//
//        // set the range axis to display integers only...
//        NumberAxis rangeAxis = (NumberAxis) plot.getRangeAxis();
//        rangeAxis.setStandardTickUnits(NumberAxis.createIntegerTickUnits());
//
//        // disable bar outlines...
//        BarRenderer renderer = (BarRenderer) plot.getRenderer();
//        renderer.setDrawBarOutline(false);
//
//        // set up gradient paints for series...
//        GradientColor gp0 = new GradientColor(Color.BLUE, Color.rgb(51, 102, 204));
//        GradientColor gp1 = new GradientColor(Color.RED, Color.rgb(255, 0, 0));
//        renderer.setSeriesPaintType(0, gp0);
//        renderer.setSeriesPaintType(1, gp1);
//
//        CategoryAxis domainAxis = plot.getDomainAxis();
//        domainAxis.setCategoryLabelPositions(
//                CategoryLabelPositions.createUpRotationLabelPositions(
//                        Math.PI / 6.0));
//        // OPTIONAL CUSTOMISATION COMPLETED.

        return chart;

    }
}