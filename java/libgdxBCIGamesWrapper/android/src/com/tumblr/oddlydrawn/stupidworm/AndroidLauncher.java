package com.tumblr.oddlydrawn.stupidworm;

import android.os.Bundle;

import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;
import com.tumblr.oddlydrawn.stupidworm.screens.MainMenuScreen;
import nl.ru.bcigames.VisualStimuliSystem.OverlayGame;

public class AndroidLauncher extends AndroidApplication {
	@Override
	protected void onCreate (Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		AndroidApplicationConfiguration config = new AndroidApplicationConfiguration();
		initialize(new OverlayGame(), config);
	}
}
