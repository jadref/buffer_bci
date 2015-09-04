package nl.dcc.buffer_bci.signalprocessing;
import nl.dcc.buffer_bci.matrixalgebra.linalg.Matrix;

/**
 * Created by Pieter on 23-2-2015.
 * Result of a Classifier
 */
public class ClassifierResult {

    public final Matrix f, fraw, p, X;

    public ClassifierResult(Matrix f, Matrix fraw, Matrix p, Matrix X) {
        this.f = f;
        this.fraw = fraw;
        this.p = p;
        this.X = X;
    }

    public ClassifierResult(ClassifierResult classifierResult) {
        this.f = classifierResult.f;
        this.fraw = classifierResult.fraw;
        this.p = classifierResult.p;
        this.X = classifierResult.X;
    }

    public String toString() {
        return "Classifier result: " + "f" + f.shapeString() + ", fraw" + fraw.shapeString() + ", p" + p.shapeString
                () + ", X" + X.shapeString();
    }
}
