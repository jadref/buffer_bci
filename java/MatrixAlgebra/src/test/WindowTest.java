package nl.dcc.buffer_bci.matrixalgebra.test;

import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Tuple;
import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.Windows;
import junit.framework.TestCase;
import org.junit.Assert;

import static org.junit.Assert.assertArrayEquals;

/**
 * Created by Pieter on 4-3-2015.
 * Testing the window functions
 */
public class WindowTest extends TestCase {

    public void testHanning() throws Exception {
        double[] ret = Windows.getWindow(6, Windows.WindowType.HANNING, true);
        double[] good = new double[]{.1981, .6431, 1., 1., .6431, .1981};
        assertArrayEquals(good, ret, 0.001);
    }

    public void testGaussian() throws Exception {
        double[] ret = Windows.getWindow(6, Windows.WindowType.GAUSSIAN, true);
        double[] good = new double[]{.6188, .8521, 1., 1., .8521, .6188};
        assertArrayEquals(good, ret, 0.001);
    }

    public void testWindowLocations() throws Exception {
        Tuple<int[], Integer> ret = Windows.computeWindowLocation(27, 4, .2);
        int[] good = new int[]{0, 6, 11, 17};
        Assert.assertArrayEquals(good, ret.x);
        assertEquals(7, ret.y.intValue());
    }
}
