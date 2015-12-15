package nl.dcc.buffer_bci.matrixalgebra.linalg;

import nl.dcc.buffer_bci.matrixalgebra.miscellaneous.*;
import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.linear.*;
import org.apache.commons.math3.stat.correlation.Covariance;
import org.apache.commons.math3.stat.descriptive.AbstractUnivariateStatistic;
import org.apache.commons.math3.stat.descriptive.moment.StandardDeviation;
import org.apache.commons.math3.stat.descriptive.moment.Variance;
import org.apache.commons.math3.stat.descriptive.rank.Median;
import org.apache.commons.math3.stat.regression.SimpleRegression;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;
import org.apache.commons.math3.util.MathArrays;

import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.IOException;

import static org.apache.commons.math3.stat.StatUtils.max;

/**
 * Created by Pieter on 27-1-2015.
 * Wrapper for linear algebra functions on matrices.
 * 2D array with lots of functions from the Math Commons library
 */
public class Matrix extends Array2DRowRealMatrix {

	 public static final String TAG=Matrix.class.getSimpleName();
	 public static final int VERB = 1; // debugging verbosity level

    /**
     * Uninitialized matrix
     */
    public Matrix() {
        super();
    }

    /**
     * Column matrix
     *
     * @param v values in the first column
     */
    public Matrix(double[] v) {
        super(v);
    }

    /**
     * Matrix with values
     *
     * @param d the values in the matrix. First index is rows, second columns.
     */
    public Matrix(double[][] d) {
        super(d);
    }

    /**
     * Matrix with values
     *
     * @param d         the values in the matrix. First index is rows, second columns.
     * @param copyArray If the array should be copied.
     */
    public Matrix(double[][] d, boolean copyArray) {
        super(d, copyArray);
    }

    /**
     * Empty matrix with specific dimensions
     *
     * @param rowDimension    number of rows
     * @param columnDimension number of columns
     */
    public Matrix(int rowDimension, int columnDimension) {
        super(rowDimension, columnDimension);
    }

    /**
     * Extend functionality of RealMatrix with Matrix properties
     *
     * @param m the to-be-copied RealMatrix
     */
    public Matrix(RealMatrix m) {
        super(m.getData());
    }

    /**
     * Creates a matrix with all zeros
     *
     * @param dim0 the number of rows
     * @param dim1 the number of columns
     * @return Matrix with dimensions dim0xdim1
     */
    public static Matrix zeros(int dim0, int dim1) {
        ParameterChecker.checkNonNegative(dim0);
        ParameterChecker.checkNonNegative(dim1);

        double[][] zeros = new double[dim0][dim1];
        return new Matrix(zeros);
    }

    /**
     * Creates a matrix with all ones
     *
     * @param dim0 the number of rows
     * @param dim1 the number of columns
     * @return Matrix with dimensions dim0xdim1
     */
    public static Matrix ones(int dim0, int dim1) {
        ParameterChecker.checkNonNegative(dim0);
        ParameterChecker.checkNonNegative(dim1);

        double[][] zeros = new double[dim0][dim1];
        return new Matrix(new Array2DRowRealMatrix(zeros).scalarAdd(1.0));
    }

    /**
     * Identity matrix
     *
     * @param dim row and column dimension of the matrix.
     * @return Square matrix with dimensions dimxdim
     */
    public static Matrix eye(int dim) {
        ParameterChecker.checkNonNegative(dim);

        double[] ones = new double[dim];
        for (int i = 0; i < dim; i++)
            ones[i] = 1.0;
        return new Matrix(new DiagonalMatrix(ones));
    }

    /**
     * Car matrix with values 1 - (1 / size) on the diagonal and -(1 / size) off the diagonal
     *
     * @param size The size of the matrix
     * @return Matrix with dimensions sizexsize
     */
    public static Matrix car(int size) {
        ParameterChecker.checkNonNegative(size);

        return new Matrix(Matrix.eye(size).scalarAdd(-1.0 / ((double) size)));
    }

    /**
     * Array with values in an interval and step size
     *
     * @param start of the interval
     * @param end   of the interval
     * @param step  size between the values
     * @return int array with size (start - end) / step
     */
    public static int[] range(int start, int end, int step) {
        ParameterChecker.checkNonZero(step);
        int size = (int) Math.ceil(((double) (end - start)) / step);
		  if ( size<1 ) return new int[0];
        int[] arr = new int[size];
        int index = 0;
        for (int i = start; i < end; i += step) {
            arr[index] = i;
            index++;
        }
        return arr;
    }

    /**
     * Array with values in an interval and step size
     *
     * @param start of the interval
     * @param end   of the interval
     * @param step  size between the values
     * @return double array of size (end - start) / step
     */
    public static double[] range(double start, double end, double step) {
        ParameterChecker.checkNonZero(step);

        int size = (int) ((end - start) / step);
        double[] arr = new double[size];
        int index = 0;
        for (double i = start; i < end; i += step)
            arr[index] = i;
        return arr;
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("#").append(this.getClass().getSimpleName()).append(getRowDimension()).append("x").append(getColumnDimension()).append(" \n");
        for (int i = 0; i < getRowDimension(); i++) {
            for (int j = 0; j < getColumnDimension(); j++)
                sb.append(getData()[i][j]).append(" ");
            if (i < getRowDimension() - 1) sb.append("\n");
        }
        return sb.toString();
    }

    /**
     * String representation of the size of the matrix
     *
     * @return (rows, columns)
     */
    public String shapeString() {
        return "(" + this.getRowDimension() + ", " + this.getColumnDimension() + ")";
    }

    /**
     * Dimensions on a particular axis
     *
     * @param axis should be 0 or 1. 0 are the rows, 1 the columns.
     * @return size of the Matrix on the rows or columns
     */
    public int getDimension(int axis) {
        ParameterChecker.checkAxis(axis);

        return axis == 0 ? this.getRowDimension() : this.getColumnDimension();
    }

    /**
     * Transposes the matrix: X'_{ij} = X_{ji}
     */
    public Matrix transpose() {
        return new Matrix(super.transpose());
    }

    /**
     * Reshape the matrix into a new form. New size should have the same number of elements as current size.
     *
     * @param rows    new number of rows
     * @param columns new number of columns
     * @return new Matrix with reshaped values
     */
    public Matrix reshape(int rows, int columns) {
        ParameterChecker.checkEquals(rows * columns, this.getRowDimension() * this.getColumnDimension());
        return new Matrix(ArrayFunctions.reshape(this.getData(), rows, columns));
    }

    /**
     * Round the values of the matrix
     *
     * @param decimals the number of decimals to round to
     * @return new Matrix with rounded values
     */
    public Matrix round(int decimals) {
        ParameterChecker.checkNonNegative(decimals);

        double[][] data = this.getData();
        double factor = Math.pow(10, decimals);
        for (int i = 0; i < data.length; i++)
            for (int j = 0; j < data[i].length; j++)
                data[i][j] = Math.round(data[i][j] * factor) / factor;
        return new Matrix(data);
    }

    /**
     * Flip the matrix upside down. Columns are inverted.
     *
     * @return new matrix with inverted columns.
     */
    public Matrix flipUD() {
        double[][] newMatrix = this.getData();
        double[][] oldMatrix = this.getData();
        for (int r = 0; r < oldMatrix.length; r++)
            System.arraycopy(oldMatrix[r], 0, newMatrix[newMatrix.length - r - 1], 0, oldMatrix[r].length);
        return new Matrix(newMatrix);
    }

    /**
     * Flip the matrix from left to right. Rows are inverted.
     *
     * @return new matrix with inverted rows.
     */
    public Matrix flipLR() {
        double[][] newMatrix = this.getData();
        double[][] oldMatrix = this.getData();
        for (int r = 0; r < oldMatrix.length; r++)
            for (int c = 0; c < oldMatrix[r].length; c++)
                newMatrix[r][newMatrix[r].length - c - 1] = oldMatrix[r][c];
        return new Matrix(newMatrix);
    }

    /**
     * Repeats the current matrix into a particular direction.
     *
     * @param repeats number of times to repeat
     * @param axis    direction in which to repeat (0 is rows, 1 is columns)
     * @return new matrix with repeated values along a particular axis. Total matrix is repeated, not the specific
     * values.
     */
    public Matrix repeat(int repeats, int axis) {
        ParameterChecker.checkAxis(axis);
        ParameterChecker.checkRepeats(repeats);

        if (axis == 1) return this.transpose().repeat(repeats, 0).transpose();
        else {
            double[][] newData = new double[this.getRowDimension() * repeats][this.getColumnDimension()];
            for (int r = 0; r < this.getRowDimension(); r++)
                for (int t = 0; t < repeats; t++)
                    newData[t * this.getRowDimension() + r] = this.getRow(r);
            return new Matrix(newData);
        }
    }

    /**
     * Absolute values of the matrix
     *
     * @return new matrix with non-zero elements
     */
    public Matrix abs() {
        Matrix m = new Matrix(this.copy());
        m.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
            @Override
            public double visit(int row, int column, double value) {
                return Math.abs(value);
            }
        });
        return m;
    }

    /**
     * Element wise square root of the matrix
     *
     * @return new matrix
     */
    public Matrix sqrt() {
        Matrix m = new Matrix(this.copy());
        m.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
            @Override
            public double visit(int row, int column, double value) {
                return Math.sqrt(value);
            }
        });
        return m;
    }

    /**
     * Mean along all values of the matrix
     *
     * @return new matrix with one element, which is the mean of the current matrix
     */
    public double mean() {
		  return this.sum() / this.getRowDimension() / this.getColumnDimension();
    }

    /**
     * Mean along a particular axis
     *
     * @param axis the axis (0 is rows, 1 is columns)
     * @return new matrix with one column that are the means of the rows or columns of the current matrix.
     */
    public Matrix mean(int axis) {
        ParameterChecker.checkAxis(axis, true);

        double scalar;
		  if (axis == 0) scalar = this.getRowDimension();
        else if (axis == 1) scalar = this.getColumnDimension();
        else throw new IllegalArgumentException("Wrong axis selected. Should be either -1, 0 or 1 but is " + axis);
        scalar = 1.0 / scalar;
        return new Matrix(this.sum(axis).scalarMultiply(scalar));
    }

    /**
     * Median along a particular axis
     *
     * @param axis the axis (0 is rows, 1 is columns)
     * @return new matrix with one column that are the medians of the rows or columns of the current matrix.
     */
    public Matrix median(int axis) {
        Median med = new Median();
        return this.evaluateUnivariateStatistic(axis, med);
    }

    /**
     * Element wise addition of the current matrix and another. Matrices should have same shape.
     *
     * @param b the other matrix
     * @return new matrix were each element is this_{ij} + b_{ij}
     */
    public Matrix add(final Matrix b) {
        return new Matrix(super.add(b));
    }

    /**
     * Element wise subtraction of the current matrix and another. Matrices should have same shape.
     *
     * @param b the other matrix
     * @return new matrix were each element is this_{ij} - b_{ij}
     */
    public Matrix subtract(final Matrix b) {
        return new Matrix(super.subtract(b));
    }

    /**
     * Element wise multiplication of the current matrix with another. Matrices should have same shape.
     *
     * @param b the other matrix
     * @return new matrix were each element is the this_{ij}*b_{ij}
     */
    public Matrix multiplyElements(final Matrix b) {
        ParameterChecker.checkEquals(this.getRowDimension(), b.getRowDimension());
        ParameterChecker.checkEquals(this.getColumnDimension(), b.getColumnDimension());

        RealMatrix c = this.copy();
        c.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
            public double visit(int row, int column, double value) {
                return value * b.getEntry(row, column);
            }
        });
        return new Matrix(c);
    }

    /**
     * Element wise multiplication and summation one matrix with another. 
	  * Matrices should have same shape.
     *
     * @param b the other matrix
     * @return the accumulated sum \sum_{i,j} a[i,j]*b[i,j]
     */
    public double multiplyAccumulateElements(final Matrix b) {
        ParameterChecker.checkEquals(this.getRowDimension(), b.getRowDimension());
        ParameterChecker.checkEquals(this.getColumnDimension(), b.getColumnDimension());

        double res = 
				walkInOptimizedOrder(new DefaultRealMatrixPreservingVisitor() {
						  double res=0.0;
						  public void visit(int row, int column, double value) {
								res += value * b.getEntry(row, column);
						  }
						  public double end(){ return res; }
					 });
        return res;
    }

    /**
     * Element wise division of the current matrix with another. Matrices should have same shape.
     *
     * @param b the other matrix
     * @return new matrix were each element is the this_{ij}/b_{ij}
     */
    public Matrix divideElements(final Matrix b) {
        ParameterChecker.checkEquals(this.getRowDimension(), b.getRowDimension());
        ParameterChecker.checkEquals(this.getColumnDimension(), b.getColumnDimension());

        RealMatrix c = this.copy();
        c.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
            public double visit(int row, int column, double value) {
                return value / b.getEntry(row, column);
            }
        });
        return new Matrix(c);
    }

    /**
     * Compute a univariate statistic over the matrix.
     *
     * @param axis direction of computation
     * @param stat the statistic
     * @return new matrix with one column
     */
    public Matrix evaluateUnivariateStatistic(int axis, AbstractUnivariateStatistic stat) {
        ParameterChecker.checkAxis(axis, true);

        double[] data;
        if (axis == -1) {
            return this.flatten().evaluateUnivariateStatistic(0, stat);
        } else if (axis == 0) {
            data = new double[this.getColumnDimension()];
            for (int c = 0; c < this.getColumnDimension(); c++)
                data[c] = stat.evaluate(this.getColumn(c));
        } else {
            data = new double[this.getRowDimension()];
            for (int r = 0; r < this.getRowDimension(); r++)
                data[r] = stat.evaluate(this.getRow(r));
        }
        return new Matrix(data);
    }

    /**
     * Sum of all the elements in the matrix
     *
     * @return Matrix with one value
     */
    public double sum() {
        double res = 
				walkInOptimizedOrder(new DefaultRealMatrixPreservingVisitor() {
						  double res=0.0;
						  public void visit(int row, int column, double value) {res += value;}
						  public double end(){ return res; }
					 });
        return res;
    }

    /**
     * Sum of the elements along a particular direction
     *
     * @param axis the direction (0 is rows, 1 is columns)
     * @return the new matrix with one column
     */
    public Matrix sum(int axis) {
        ParameterChecker.checkAxis(axis, true);

        double[][] data = this.getData();
        if (axis == -1) {
            return this.sum(0).sum(0);
        } else if (axis == 0) {
            double[] mean = new double[this.getColumnDimension()];
            for (int i = 0; i < this.getRowDimension(); i++) {
                for (int j = 0; j < this.getColumnDimension(); j++) {
                    mean[j] += data[i][j];
                }
            }
            return new Matrix(mean);
        } else if (axis == 1) {
            return this.transpose().sum(0);
        } else {
            throw new IllegalArgumentException("Wrong axis selected. Should be either -1, 0 or 1 but is " + axis);
        }
    }

    /**
     * Covariance of the columns of the matrix
     *
     * @return covariance matrix with size columnsxcolumns
     */
    public Matrix covariance() {
        Covariance cov = new Covariance(this.transpose(), true);
        return new Matrix(cov.getCovarianceMatrix());
    }

    /**
     * Variance of the values in a particular direction
     *
     * @param axis the direction (0 is rows, 1 is columns)
     * @return new matrix with one column
     */
    public Matrix variance(int axis) {
        Variance var = new Variance(false);
        return this.evaluateUnivariateStatistic(axis, var);
    }

    /**
     * Standard deviation of the values in a particular direction
     *
     * @param axis the direction (0 is rows, 1 is columns)
     * @return new matrix with one column
     */
    public Matrix std(int axis) {
        StandardDeviation std = new StandardDeviation();
        return this.evaluateUnivariateStatistic(axis, std);
    }

    /**
     * Flatten the matrix into a matrix with one column
     *
     * @return new matrix with one column
     */
    public Matrix flatten() {
        double[] data = new double[this.getRowDimension() * this.getColumnDimension()];
        for (int r = 0; r < this.getRowDimension(); r++)
            for (int c = 0; c < this.getColumnDimension(); c++)
                data[r * this.getColumnDimension() + c] = this.getEntry(r, c);
        return new Matrix(data);
    }

    /**
     * Detrend the matrix into a particular direction. Can be either the subtraction of a constant (mean) or linear
     * detrending (with intercept and slope)
     *
     * @param axis the direction (0 is rows, 1 is columns)
     * @param type "constant" or "linear"
     * @return new matrix with detrended values
     */
    public Matrix detrend(int axis, String type) {
        ParameterChecker.checkAxis(axis);
        ParameterChecker.checkString(type, new String[]{"constant", "linear"});

        if (type.equalsIgnoreCase("constant")) {
            Matrix mean = this.mean(axis);
            int otherAxis = axis == 0 ? 1 : 0;
            mean = mean.repeat(this.getDimension(axis), 1);
            mean = axis == 0 ? mean.transpose() : mean;
            return new Matrix(this.subtract(mean));
        } else {
            double[][] ret = this.getData();
            if (axis == 0) {
                for (int c = 0; c < this.getColumnDimension(); c++) {
                    SimpleRegression regression = new SimpleRegression();
                    double[] column = this.getColumn(c);
                    for (int i = 0; i < column.length; i++)
                        regression.addData(i, column[i]);
                    double slope = regression.getSlope();
                    double intercept = regression.getIntercept();
                    for (int r = 0; r < this.getRowDimension(); r++)
                        ret[r][c] = ret[r][c] - intercept - r * slope;
                }
            } else {
                for (int r = 0; r < this.getRowDimension(); r++) {
                    SimpleRegression regression = new SimpleRegression();
                    double[] row = this.getRow(r);
                    for (int i = 0; i < row.length; i++)
                        regression.addData(i, row[i]);
                    double slope = regression.getSlope();
                    double intercept = regression.getIntercept();
                    for (int c = 0; c < this.getColumnDimension(); c++)
                        ret[r][c] = ret[r][c] - intercept - c * slope;
                }
            }
            return new Matrix(ret);
        }
    }

    /**
     * Forward fast fourier transform onto a particular axis
     *
     * @param axis the axis (0 is rows, 1 is columns)
     * @return The new matrix with a fft applied to each row or column
     */
    public Matrix fft2(int axis) {
        return fft2(axis, TransformType.FORWARD);
    }

    /**
     * Inverse fast fourier transform onto a particular axis
     *
     * @param axis the axis (0 is rows, 1 is columns)
     * @return The new matrix with an ifft applied to each row or column
     */
    public Matrix ifft2(int axis) {
        return fft2(axis, TransformType.INVERSE);
    }

    /**
     * Forward or Inverse *squared* fast fourier transform onto a particular axis
     *
	  * N.B. returns the squared complex fourier component!
	  *
     * @param axis      the axis (0 is rows, 1 is columns)
     * @param direction TransformType.FORWARD or TransformType.INVERSE
     * @return The new matrix with a fft or ifft applied to each row or column
     */
    public Matrix fft2(int axis, TransformType direction) {
        ParameterChecker.checkAxis(axis);

        FastFourierTransformer fft = new FastFourierTransformer(DftNormalization.STANDARD);
        double[][] ft = new double[this.getRowDimension()][this.getColumnDimension()];
        if (axis == 0) {
            for (int c = 0; c < this.getColumnDimension(); c++) {
                Complex[] complexResult = fft.transform(this.getColumn(c), direction);
                for (int i = 0; i < complexResult.length; i++)
                    ft[i][c] = complexResult[i].abs()*complexResult[i].abs();
            }
        } else {
				// TODO: This is inefficient....
            return this.transpose().fft2(0, direction).transpose();
        }
        return new Matrix(ft);
    }

    /**
     * fft on an array with complex values
     *
     * @param axis      the axis (0 is rows, 1 is columns)
     * @param direction TransformType.FORWARD or TransformType.INVERSE
     * @return The new matrix with a fft or ifft applied to each row or column
     */
    public Complex[][] fft(int axis, TransformType direction) {
        ParameterChecker.checkAxis(axis);

        FastFourierTransformer fft = new FastFourierTransformer(DftNormalization.STANDARD);
        Complex[][] ft = new Complex[this.getRowDimension()][this.getColumnDimension()];
        if (axis == 0) {
            for (int c = 0; c < this.getColumnDimension(); c++) {
                // FIXME use data lengths with powers of 2
                Complex[] complexResult = fft.transform(this.getColumn(c), direction);
                for (int i = 0; i < complexResult.length; i++)
                    ft[i][c] = complexResult[i];
            }
        } else {
            for (int r = 0; r < this.getRowDimension(); r++) {
                Complex[] complexResult = fft.transform(this.getRow(r), direction);
                System.arraycopy(complexResult, 0, ft[r], 0, complexResult.length);
            }
        }
        return ft;
    }

    /**
     * Eigenvalue decomposition of the matrix
     *
     * @return Tuple with the eigenvectors and eigenvalues in descending order
     */
    public Tuple<Matrix, RealVector> eig() {
        return eig("descending");
    }

    /**
     * Eigenvalue decomposition of the matrix.
     *
     * @param order of the eigenvalues
     * @return Tuple with the eigenvectors and eigenvalues in a particular order
     */
    public Tuple<Matrix, RealVector> eig(String order) {
        ParameterChecker.checkString(order, new String[]{"descending", "ascending"});

        EigenDecomposition eig = new EigenDecomposition(this);
        RealMatrix oldVectors = new Array2DRowRealMatrix(eig.getV().getData());
        double[] oldValues = eig.getRealEigenvalues();
        RealMatrix newVectors = new Array2DRowRealMatrix(eig.getV().getData());
        double[] newValues = eig.getRealEigenvalues();
        Integer[] sortIdx = ArrayFunctions.getSortIdx(oldValues);
        for (int i = 0; i < sortIdx.length; i++) {
            Integer id = sortIdx[i];
            newVectors.setColumn(i, oldVectors.getColumn(id));
            newValues[i] = oldValues[id];
        }
        if (order.equalsIgnoreCase("descending")) {
            return new Tuple<Matrix, RealVector>(new Matrix(newVectors), new ArrayRealVector(newValues));
        } else {
            Matrix eigenVectors = new Matrix(newVectors).flipLR();
            ArrayFunctions.reverseDoubleArrayInPlace(newValues);
            RealVector eigenValues = new ArrayRealVector(newValues);
            return new Tuple<Matrix, RealVector>(eigenVectors, eigenValues);
        }
    }

    /**
     * Singular values decomposition of the matrix
     *
     * @return the left singular values (U), the scaling diagonal matrix (Sigma) and the right singular values (V^T).
     */
    public Triple<Matrix, Matrix, Matrix> svd() {
        SingularValueDecomposition svd = new SingularValueDecomposition(this);
        return new Triple<Matrix, Matrix, Matrix>(new Matrix(svd.getU()), new Matrix(svd.getS()), new Matrix(svd
                .getVT()));
    }

    /**
     * Spatial filtering of the matrix
     *
     * @param type "car" or "whiten"
     * @return new matrix with spatially filtered values
     */
    public Matrix spatialFilter(String type) {
        return spatialFilter(type, 1e-15);
    }

    /**
     * Spatial filtering of the matrix
     *
     * @param type        "car" or "whiten"
     * @param whitenThres threshold for the whitening
     * @return new matrix with spatially filtered values
     */
    public Matrix spatialFilter(String type, double whitenThres) {
        ParameterChecker.checkString(type, new String[]{"car", "whiten"});
        ParameterChecker.checkNonNegative(whitenThres);

        if (type.equalsIgnoreCase("car")) {
            return new Matrix(this.preMultiply(Matrix.car(this.getRowDimension())));
        } else {
            // Get eigen decomposition of the covariance matrix
            Tuple<Matrix, RealVector> eigenDecomposition = this.covariance().eig("ascending");
            Matrix eigenVectors = eigenDecomposition.x;
            double[] eigenValues = eigenDecomposition.y.toArray();
            // Use the decomposition to create the multiplication matrix for the whiten spatial filter
            double[] diagValues = new double[eigenValues.length];
            double max = max(diagValues);
            for (int i = 0; i < eigenValues.length; i++)
                diagValues[i] = eigenValues[i] > max * whitenThres ? Math.pow(eigenValues[i], -.5) : 0.0;
            RealMatrix diag = new DiagonalMatrix(diagValues);
            RealMatrix transform = eigenVectors.multiply(diag).multiply(eigenVectors.transpose());
            return new Matrix(this.preMultiply(transform));
        }
    }

    /**
     * Convolve the matrix with a function on a particular axis
     *
     * @param function The function to convolve with.
     * @param axis     Direction of the convolution (0 is rows, 1 is columns)
     * @return new matrix with values convolved with the function.
     */
    public Matrix convolve(double[] function, int axis) {
        ParameterChecker.checkNonZero(function.length);
        ParameterChecker.checkAxis(axis);

        if (axis == 0) {
            int newLength = this.getColumnDimension() + function.length - 1;
            double[][] data = new double[this.getRowDimension()][newLength];
            for (int r = 0; r < this.getRowDimension(); r++) {
                data[r] = MathArrays.convolve(this.getRow(r), function);
            }
            return new Matrix(data);
        } else {
            return this.transpose().convolve(function, 0).transpose();
        }
    }

    /**
     * Removes outliers from the matrix based on the variance of mean.
     *
     * @param axis           direction to remove outliers in (0 is rows, 1 is columns)
     * @param lowerThreshold scaling of the feature to get the lower boundary
     * @param upperThreshold scaling of the feature to get the upper boundary
     * @param maxIter        number of iteration
     * @param feat           "var" or "mu"
     * @return matrix with possible removed rows or columns because they are outliers.
     */
    public Matrix removeOutliers(int axis, double lowerThreshold, double upperThreshold, int maxIter, String feat) {
        ParameterChecker.checkAxis(axis);
        ParameterChecker.checkNonZero(maxIter);
        ParameterChecker.checkNonNegative(maxIter);
        ParameterChecker.checkString(feat, new String[]{"var", "mu"});

        Matrix m = this;
        if (maxIter > 1) m = m.removeOutliers(axis, lowerThreshold, upperThreshold, maxIter - 1, feat);
        if (m == null) return null;

        Matrix feature;
        if (feat.equalsIgnoreCase("var")) {
            feature = m.variance(axis).abs().sqrt();
        } else {
            feature = m.mean(axis);
        }

        double median = feature.median(-1).getData()[0][0];
        double std = feature.std(-1).getData()[0][0];
        double high = median + upperThreshold * std;
        double low = median + lowerThreshold * std;

        int inlierCount = 0;
        for (double val : feature.getColumn(0)) {
            inlierCount += (low < val) && (val < high) ? 1 : 0;
        }

        if (inlierCount <= 0) return null;
        else {
            int index = 0;
            Matrix ret;
            if (axis == 0) {
                ret = new Matrix(m.getRowDimension(), inlierCount);
                for (int c = 0; c < m.getColumnDimension(); c++) {
                    double featureValue = feature.getColumn(0)[c];
                    if (low < featureValue && featureValue < high) {
                        ret.setColumn(index, m.getColumn(c));
                        index++;
                    }
                }
            } else {
                ret = new Matrix(inlierCount, m.getColumnDimension());
                for (int r = 0; r < m.getRowDimension(); r++) {
                    double featureValue = feature.getColumn(0)[r];
                    if (low < featureValue && featureValue < high) {
                        ret.setRow(index, m.getRow(r));
                        index++;
                    }
                }
            }

            return ret;
        }
    }

    /**
     * Welch method on the matrix
     *
     * @param dim      direction to apply it on (0 is rows, 1 is columns)
     * @param taper    window function
     * @param start    start indexes
     * @param detrend  if the input matrix should be detrended (=1) or centered (=2) or nothing (=0)
     * @return precise estimation of the power of the frequencies of the matrix.
     */
    public Matrix welch(final int dim, int len_samp, Windows.WindowType wtype) {
		  return welch(dim,len_samp,wtype,true);
	 }
    public Matrix welch(final int dim, int len_samp, Windows.WindowType wtype, boolean unitAmplitude) {
		  double[] taper = Windows.getWindow(len_samp,wtype,unitAmplitude);
		  return welch(dim,taper,WelchOutputType.AMPLITUDE,null,0);
	 }
    public Matrix welch(final int dim, final double[] taper) {
		  return welch(dim,taper,WelchOutputType.AMPLITUDE,null,0); 
	 }
    public Matrix welch(final int dim, final double[] taper, int detrendP) {
		  return welch(dim,taper,WelchOutputType.AMPLITUDE,null,detrendP); 
	 }
    public Matrix welch(final int dim, final double[] taper, WelchOutputType outType, int[] start, int detrendP) {
        ParameterChecker.checkAxis(dim, false);
        ParameterChecker.checkNonZero(taper.length);

        // TODO: add output type, default is 'amp'
        outType = WelchOutputType.AMPLITUDE;

        // Abbreviations
        int otherDim = dim == 0 ? 1 : 0;
        int sizeDim = this.getDimension(dim);
        int sizeOtherDim = this.getDimension(otherDim);

		  // Compute fft width needed (nearest larger power of 2)
		  // int width = 0; 
		  // //System.out.println(TAG+"taper.len=" + taper.length);
		  // while( (taper.length >> ++width) > 1) {
		  // 		//System.out.println(TAG+"width=" + width + " taper>>width= " + (taper.length>>width)); 
		  // }
		  // width=1<<width;
		  int width = 1 << (int)Math.ceil(Math.log(taper.length)/Math.log(2));
		  if ( VERB>1 ) System.out.println(TAG+"1<<width="+width);
		  // Compute the updated taper if needed.		  
		  // N.B. technically don't need this as can just zero-pad the sub-matrix...
		  final double[] taper2;
		  if ( width  > taper.length ) {
				System.err.println(TAG+"::welch Warning: taper is not power of 2, zero-padding: " + taper.length + " -> " + width);
				taper2=new double[width];
				for ( int i=0;            i<taper.length;  i++) taper2[i]=taper[i];
				for ( int i=taper.length; i<taper2.length; i++) taper2[i]=0; // zero pad the end
		  } else {
				taper2=taper;
		  }

		  // if not given compute start locations assuming 50% overlap in windows
		  if ( start == null ) { 
				start = Matrix.range(0,sizeDim-width+1,taper.length);				
		  }
		  if ( start.length==0 ) {
				System.err.println(TAG+"No start points?: sz="+sizeDim+" wdth="+width+" taper.len="+taper.length);
		  }

        // Create W
		  // Compute the size of the output, i.e. X x #freqs
        int wWidth, wHeight;
        int reducedDim = (int) Math.round(((Math.ceil(((double) width - 1) / 2) + 1)));
        if (dim == 0) {
            wHeight = reducedDim;
            wWidth = this.getColumnDimension();
        } else {
            wHeight = this.getRowDimension();
            wWidth = reducedDim;
        }
        Matrix W = Matrix.zeros(wHeight, wWidth);

        // Create indexes
        ArrayList<int[]> idx = new ArrayList<int[]>();
        idx.add(Matrix.range(0, this.getRowDimension(), 1));
        idx.add(Matrix.range(0, this.getColumnDimension(), 1));
        ArrayList<int[]> wIdx = new ArrayList<int[]>();
        wIdx.add(Matrix.range(0, wHeight, 1));
        wIdx.add(Matrix.range(0, wWidth, 1));

        // Sum over the windows
        for (int wi : start ) { 
            // Window the dimension
            idx.set(dim, Matrix.range(wi, wi + width, 1));

            // Get submatrix
            Matrix wX = new Matrix(this.getSubMatrix(idx.get(0), idx.get(1)));

            if (detrendP==2) // Subtract mean from window
                wX = wX.subtract(wX.mean(dim).repeat(wX.getDimension(dim), dim));

            if (detrendP==1) // Detrend window
                wX = wX.detrend(dim, "linear");

            // Apply taper to this window
            wX.walkInOptimizedOrder(new DefaultRealMatrixChangingVisitor() {
                @Override
                public double visit(int row, int column, double value) {
                    if (dim == 0) return value * taper2[row];
                    else return value * taper2[column];
                }
            });
				
				if ( VERB>1 ) System.out.println(TAG+"Welch: data+taper="+wX.toString());

            // squared Fourier
            wX = new Matrix(wX.fft2(dim).scalarMultiply(2.0));
				if ( VERB>1 ) System.out.println(TAG+"Welch: data+fft2="+wX.toString());

            // Positive frequency only
            wX = new Matrix(wX.getSubMatrix(wIdx.get(0), wIdx.get(1)));
				if ( VERB>1 ) System.out.println(TAG+"Welch: data+fft2+freqIdx="+wX.toString());

            switch (outType) {
				case AMPLITUDE:
					 W = new Matrix(W.add(wX.sqrt()));
					 break;
				case POWER:
					 W = new Matrix(W.add(wX));
					 break;
				default:
					 throw new IllegalArgumentException("Only amp is supported");
            }
        }
		  double tapersum=0; for ( int i=0;i<taper.length; i++ ) tapersum+=taper[i];
        W = new Matrix(W.scalarMultiply(1. / (start.length * tapersum)));
        return W;
    }

	 public static Matrix fromString(BufferedReader bufferedReader) throws IOException {
		  if ( bufferedReader == null ) {
				System.out.println(TAG+"could not allocate reader");
				throw new IOException("Couldnt allocate a reader");
		  }
		  int width=-1;
		  // tempory store for all the values loaded from file
		  ArrayList<double[]> rows=new ArrayList<double[]>(10);
		  String line;
		  int nEmptyLines=0;
		  if ( VERB>0 ) System.out.println(TAG+"Starting new matrix");
		  if ( VERB>0 ) if ( bufferedReader.ready() ) System.out.println(TAG+"reader is ready");	else System.out.println(TAG+"reader is *not* ready");
		  while ( (line = bufferedReader.readLine()) != null ) {
				// skip comment lines
				if ( line == null || line.startsWith("#") ){
					 continue;
				} if ( line.length()==0 ) { // double empty line means end of this array
					 nEmptyLines++;
					 if ( nEmptyLines >1 && width>0 ) { // end of matrix by 2 empty lines
						  if ( VERB>0 ) System.out.println(TAG+"Got 2 empty lines");
						  break;
					 } else { // skip them
						  continue;
					 }
				}
				if ( VERB>0 ) System.out.println(TAG+"Reading line " + rows.size());
				
				// split the line into entries on the split character
				String[] values = line.split("[ ,	]"); // split on , or white-space
				if ( width>0 && values.length != width ) {
					 throw new IOException("Row widths are not consistent!");
				} else if ( width<0 ) {
					 if ( values[0].equals("null") || values[0].equals("[]") ){
						  if ( VERB>0 ) System.out.println(TAG+"Got null value");
						  break;
					 } else {
						  width = values.length;
					 }
				}					 
				// read the row
				double[] cols = new double[width]; // tempory store for the cols data
				for ( int i=0; i<values.length; i++ ) {
					 try { 
						  cols[i] = Double.valueOf(values[i]);
					 } catch ( NumberFormatException e ) {
						  throw new IOException("Not a double number " + values[i]);
					 }
				}
				// add to the tempory store
				rows.add(cols);
		  }
		  if ( line==null ) if ( VERB>0 ) System.out.println(TAG+"line == null");
		  
		  if ( width<0 ) return null; // didn't load anything

		  // Now put the data into a Matrix
		  Matrix ret = new Matrix(rows.size(),width);
		  for ( int i=0; i<rows.size(); i++) ret.setRow(i,rows.get(i));
		  return ret;		  
    }
}
