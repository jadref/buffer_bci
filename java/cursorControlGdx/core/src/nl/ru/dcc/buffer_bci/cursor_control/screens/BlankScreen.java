package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;

/**
 * Created by Lars on 1-12-2015.
 */
public class BlankScreen extends CursorControlScreen {

    @Override
    public void draw() {
        Gdx.gl.glClearColor(0,0,0,0);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
    }

    @Override
    public void update(float delta) {

    }
}
