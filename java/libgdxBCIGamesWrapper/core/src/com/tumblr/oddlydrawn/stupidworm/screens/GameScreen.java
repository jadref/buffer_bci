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

import com.badlogic.gdx.Screen;
import com.tumblr.oddlydrawn.stupidworm.NahwcGame;


/** @author oddlydrawn */
public class GameScreen implements Screen {
	Game game;
	NahwcGame nahwcGame;

	public GameScreen (Game g) {
		game = g;
		nahwcGame = new NahwcGame();
	}

	@Override
	public void render (float delta) {
		if (nahwcGame.getIfGameOver() == false) {
			nahwcGame.runGame();
		} else {
			nahwcGame.dispose();
			game.setScreen(new MainMenuScreen(game));
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
	}
}
