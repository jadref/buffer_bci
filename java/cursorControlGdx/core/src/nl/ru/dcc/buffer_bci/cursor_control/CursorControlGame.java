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
        input = new BufferBciInput(500);
        input.connect("localhost", 1972);
	}

	@Override
	public void render () {
	}
}
