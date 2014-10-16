package nl.dcc.buffer_bci.desktop;

import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import nl.dcc.buffer_bci.VisSpeller;

public class DesktopLauncher {
	public static void main(final String[] arg) {
		final LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
		config.title = "Visual Speller";
		config.fullscreen = false;
		config.vSyncEnabled = true;
		config.width = 1280;
		config.height = 800;
		new LwjglApplication(new VisSpeller(), config);
	}
}
