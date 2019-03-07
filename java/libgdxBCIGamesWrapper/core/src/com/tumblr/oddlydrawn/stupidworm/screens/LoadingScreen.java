/*
 *   Copyright 2013 oddlydrawn
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

package com.tumblr.oddlydrawn.stupidworm.screens;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;

/** @author oddlydrawn */
public class LoadingScreen implements Screen {
	final String NOW_LOADING = "Now Loading...";
	final String FONT = "data/font/dfont.fnt";
	final float X_POS = 300;
	final float Y_POS = 30;
	final float WIDTH = 480;
	final float HEIGHT = 320;
	Game game;
	BitmapFont font;
	SpriteBatch batch;
	OrthographicCamera cam;
	float timer;

	public LoadingScreen (Game g) {
		cam = new OrthographicCamera();
		cam = new OrthographicCamera(WIDTH, HEIGHT);
		cam.setToOrtho(false, WIDTH, HEIGHT);
		font = new BitmapFont(Gdx.files.internal(FONT));
		batch = new SpriteBatch();
		game = g;
	}

	@Override
	public void render (float delta) {
		Gdx.gl.glClearColor(0, 0, 0.1f, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

		// Draws the now loading font
		batch.setProjectionMatrix(cam.combined);
		batch.begin();
		font.draw(batch, NOW_LOADING, X_POS, Y_POS);
		batch.end();

		// Starts the game after timer is greater than zero.
		timer += delta;
		if (timer > 0) {
			dispose();
			game.setScreen(new GameScreen(game));
		}
	}

	@Override
	public void resize (int width, int height) {
	}

	@Override
	public void show () {
	}

	@Override
	public void hide () {
	}

	@Override
	public void pause () {
	}

	@Override
	public void resume () {
	}

	@Override
	public void dispose () {
		batch.dispose();
		font.dispose();
	}
}
