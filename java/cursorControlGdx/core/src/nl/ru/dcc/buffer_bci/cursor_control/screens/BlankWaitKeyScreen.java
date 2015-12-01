package nl.ru.dcc.buffer_bci.cursor_control.screens;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.InputAdapter;

/**
 * Created by Lars on 1-12-2015.
 */
public class BlankWaitKeyScreen extends BlankScreen {
    private boolean active = false;

    public BlankWaitKeyScreen() {
        Gdx.input.setInputProcessor(new InputAdapter() {
            @Override
            public boolean keyUp(int keycode) {
                if(active) {
                    setDuration(0); // Force finish.
                }
                return true;
            }
        });
    }

    @Override
    public void start() {
        super.start();

        active = true;
    }
}
