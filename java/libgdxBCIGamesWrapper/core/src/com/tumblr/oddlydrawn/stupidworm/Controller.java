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

package com.tumblr.oddlydrawn.stupidworm;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;

/** @author oddlydrawn */
public class Controller {
	final private int STRAIGHT = 1; // 1
	final private int RIGHT = 2; // 2
	final private int LEFT = 3; // 3
	Worm worm;
	int dir = STRAIGHT;
	int inputX;
	int screenWidthPx;
	boolean letGo;

	public Controller (Worm worm) {
		this.worm = worm;
		screenWidthPx = Gdx.graphics.getWidth();
		letGo = true;
	}

	public void update () {
		if (dir == LEFT) worm.turnLeft();
		if (dir == RIGHT) worm.turnRight();
		dir = STRAIGHT;
	}

	public void processInput () {
		inputX = Gdx.input.getX();

		if (pressedRight()) {
			if (letGo) dir = RIGHT;
			letGo = false;
		} else if (pressedLeft()) {
			if (letGo) dir = LEFT;
			letGo = false;
		} else {
			letGo = true;
		}
	}

	public boolean pressedRight () {
		// If right half of the screen is touched or right key, same for left.
		if (Gdx.input.isKeyPressed(Keys.RIGHT)) return true;
		if (Gdx.input.isTouched() && inputX > screenWidthPx / 2) return true;
		return false;
	}

	public boolean pressedLeft () {
		if (Gdx.input.isKeyPressed(Keys.LEFT)) return true;
		if (Gdx.input.isTouched() && inputX <= screenWidthPx / 2) return true;
		return false;
	}
}