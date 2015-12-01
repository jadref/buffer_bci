package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;

/**
 * Created by Lars on 1-12-2015.
 */
public abstract class CursorControlScreen implements Screen {
    private int duration_ms;
    private long startTime = 0;

    private int width = 640, height = 480;

    public int getWidth(){
        return width;
    }

    public int getHeight() {
        return height;
    }

    public void setDuration(int ms) {
        duration_ms = ms;
    }

    public int getDuration() {
        return duration_ms;
    }

    public long getTimeLeft() {
        return (startTime + duration_ms) - System.currentTimeMillis();
    }

    @Override
    public void render(float delta) {
        update(delta);
        draw();
    }

    public void start() {
        startTime = System.currentTimeMillis();
        Gdx.app.log(this.getClass().getSimpleName(), "Start at: " + startTime + ", duration: " + duration_ms);
    }

    public boolean isDone() {
        boolean done = startTime + duration_ms < System.currentTimeMillis();
        if(done)
            Gdx.app.log(this.getClass().getSimpleName(), "Run-time: " + (System.currentTimeMillis() - startTime));
        return done;
    }


    public abstract void draw();
    public abstract void update(float delta);



    @Override
    public void show() {

    }

    @Override
    public void resize(int width, int height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {
    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose() {

    }
}
