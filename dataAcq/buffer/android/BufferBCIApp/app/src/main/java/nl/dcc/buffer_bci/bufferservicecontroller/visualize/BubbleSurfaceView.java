package nl.dcc.buffer_bci.bufferservicecontroller.visualize;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

public class BubbleSurfaceView extends SurfaceView implements SurfaceHolder.Callback {

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    // Variables go here
    DrawThread drawThread;
    BufferThread bufferThread;
    private SurfaceHolder sh;
    private Context ctx;

    public BubbleSurfaceView(Context context) {
        super(context);
        sh = getHolder();
        sh.addCallback(this);
        paint.setColor(Color.BLUE);
        paint.setStyle(Paint.Style.FILL);
        ctx = context;
        setFocusable(true); // make sure we get key events
    }

    public BubbleSurfaceView(Context context, AttributeSet attrs) {
        this(context);
    }

    public BubbleSurfaceView(Context context, AttributeSet attrs, int defStyle) {
        this(context);
    }

    public void surfaceCreated(SurfaceHolder holder) {
        Canvas canvas = sh.lockCanvas();
        canvas.drawColor(Color.BLACK);
        canvas.drawCircle(100, 200, 50, paint);

        sh.unlockCanvasAndPost(canvas);

        bufferThread = new BufferThread("localhost", 1972);
        bufferThread.setRunning(true);
        bufferThread.start();

        drawThread = new DrawThread(sh, ctx, null, bufferThread);
        drawThread.setRunning(true);
        drawThread.start();
    }

    public DrawThread getDrawThread() {
        return drawThread;
    }

    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        if ( drawThread != null ) drawThread.setSurfaceSize(width, height);
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        boolean retry = true;
        if ( drawThread != null ) {
            drawThread.setRunning(false);
            while (retry) {
                try {
                    synchronized (sh) {
                        drawThread.join();
                    }
                    retry = false;
                } catch (InterruptedException e) {
                }
            }
        }
        if ( bufferThread != null ) {
            bufferThread.setRunning(false);
        }
    }
}