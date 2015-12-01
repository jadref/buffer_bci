package nl.ru.dcc.buffer_bci.cursor_control.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import nl.ru.dcc.buffer_bci.cursor_control.CursorControlGame;

public class DesktopLauncher {
	public static void main (String[] arg) {
		LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
		new LwjglApplication(new CursorControlGame(), config);
	}
}
