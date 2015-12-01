package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;

/**
 * Created by Lars on 1-12-2015.
 */
public class BlankScreen extends CursorControlScreen {

    @Override
    public void draw() {
        Gdx.gl.glClearColor(0,0,0,0);
    }

    @Override
    public void update(float delta) {

    }
}
