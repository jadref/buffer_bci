package nl.ru.dcc.buffer_bci.cursor_control;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import nl.ru.dcc.buffer_bci.BufferBciInput;
import nl.ru.dcc.buffer_bci.cursor_control.screens.CursorControlScreen;

public class CursorControlGame extends ApplicationAdapter {
	CursorControlScreen screen;
    BufferBciInput input;

	@Override
	public void create () {
        input = new BufferBciInput(500, false);

        while(!input.connect("localhost", 1972))
            Gdx.app.log("CursorControlGame", "Could not connect to buffer!");

        Gdx.app.log("CursorControlGame", "Connected to buffer!");
	}

	@Override
	public void render () {
        screen.render(Gdx.graphics.getDeltaTime());
	}

    private void setScreen(CursorControlScreen screen) {
        this.screen = screen;
    }

    public void runScreen(CursorControlScreen screen) {
        this.screen = screen;
        this.screen.start();
    }

    public void runScreen() {
        if(this.screen != null)
            this.screen.start();
    }
}
