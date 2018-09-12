package nl.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;

/**
 * Created by Lars on 1-12-2015.
 */
public abstract class StimulusScreen implements Screen {
    protected int duration_ms;
    protected long startTime = 0;

    private int width = 640, height = 480;

    public int getWidth(){
        return width;
    }

    public int getHeight() {
        return height;
    }

    public void setDuration(int ms){duration_ms = ms; }
    public void setDuration(float duration){ setDuration((int)(1000*duration));}

    public int getDuration() {
        return duration_ms;
    }

    public long getTimeLeft() {
        return (startTime + duration_ms) - System.currentTimeMillis();
    }

    public void start() {
        startTime = System.currentTimeMillis();
        donelogged=false;
        Gdx.app.log(this.getClass().getSimpleName(), "Start at: " + startTime + ", duration: " + duration_ms);
    }

    private boolean donelogged=false;
    public boolean isDone() {
        boolean done = startTime + duration_ms < System.currentTimeMillis();
        if(done) {
            if (!donelogged) { // guard for logging lots of times..
                Gdx.app.log(this.getClass().getSimpleName(), "Run-time: " + (System.currentTimeMillis() - startTime));
                donelogged=true;
            }
        } else {
            donelogged=false;
        }
        return done;
    }


    public abstract void draw();
    public abstract void update(float delta);

    //-------------------- methods from GDXScreen from here -----------

    @Override
    public void render(float delta) {
        update(delta);
        draw();
    }

    @Override
    // redirect show->start the screen and it's clock
    public void show() {
        this.start();
    }

    @Override
    public void resize(int width, int height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public void pause() {
        // Hmmm, not supported yet!
    }

    @Override
    public void resume() {
        // Hmmm, not supported yet!
    }

    @Override
    public void hide() {
        // Hmm, not supported yet!
    }

    @Override
    public void dispose() {
        // Hmm, not supported yet!
    }
}
