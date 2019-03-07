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

import com.badlogic.gdx.math.Rectangle;

/** @author Marit Hagens */

public class Worm {
	private final int UP = 1;
	private final int RIGHT = 2;
	private final int DOWN = 3;
	private final int LEFT = 4;
	private final int WORM_MAX_SIZE = 2000;
	private final float SIZE;
	private Vector2Marked[] allBody = new Vector2Marked[WORM_MAX_SIZE];
	private float tmpX;
	private float tmpY;
	private float headX;
	private float headY;
	private float verticalLevelBounds;
	private float horizontalLevelBounds;
	private int dir;
	private int tileWidth;
	private int tileHeight;
	private int bodyLength;
	private int score;
	private int originalLength;

	private boolean update = true;

	public Worm (Rectangle bounds, int wormLength) {
		SIZE = bounds.width;
		dir = 1;
		tmpX = bounds.x;
		tmpY = bounds.y;
		for (int i = 0; i < WORM_MAX_SIZE; i++) {
			allBody[i] = new Vector2Marked(tmpX, tmpY);
		}
		bodyLength = wormLength;
		updateBody();
		originalLength = wormLength;
		tileWidth = Level.TILES_WIDTH;
		tileHeight = Level.TILES_HEIGHT;

		// subtract 2 * SIZE is the padding space for font
		// the other subtracted size is the height/width of the head
		verticalLevelBounds = tileHeight * SIZE - SIZE * 3;
		horizontalLevelBounds = tileWidth * SIZE - SIZE;
	}

	/**
	 * Snake updates the position if update is true
	 * 		Step wise game:		update if true if the snake got input to move
	 * 		Non-step wise game:	line 108 commented out and update is always true
	 */
	public void update () {
		if(update) {
			score = bodyLength - originalLength;
			// Moves the body.
			updateBody();

			// Moves the head. [0] is the head.
			headX = getHeadX();
			headY = getHeadY();
			if (dir == UP) {
				headY += SIZE;
				// If it's out of bounds, wrap around.
				if (headY > verticalLevelBounds) {
					headY = 0;
				}
			} else if (dir == RIGHT) {
				headX += SIZE;
				// If it's out of bounds, wrap around.
				if (headX > horizontalLevelBounds) {
					headX = 0;
				}
			} else if (dir == DOWN) {
				headY -= SIZE;
				// If it's out of bounds, wrap around.
				if (headY < 0) {
					headY = verticalLevelBounds;
				}
			} else {
				headX -= SIZE;
				// If it's out of bounds, wrap around.
				if (headX < 0) {
					headX = horizontalLevelBounds;
				}
			}
			setHeadX(headX);
			setHeadY(headY);

			//update = false;		// Comment out if you do not want step by step movement
		}
	}

	// Works from the tail to the head, gives last tail bit second-to-the-last's
	// position, and gives second-to-the-last tail bit third-to-the-last's
	// position and pulls itself up like so forever,
	// until it reaches this.update(), which contains the update for the head
	private void updateBody () {
		for (int i = bodyLength; i > 0; i--) {
			tmpX = allBody[i - 1].x;
			tmpY = allBody[i - 1].y;
			// Does the same thing with marked positions, so the animation/grow
			// moves down the entire length of the body.
			if (allBody[i - 1].getMarked() == true) {
				allBody[i].setMarked();
				allBody[i - 1].removeMarked();
			}
			allBody[i].x = tmpX;
			allBody[i].y = tmpY;
		}
	}

	/**
	 * Snake got input to move forward
	 */
	public void moveForward() {
		update = true;
	}

	/**
	 * Snake got input to turn right
	 */
	public void turnRight () {
		dir++;
		if (dir > LEFT) dir = UP;
		update = true;
	}

	/**
	 * Snake got input to turn left
	 */
	public void turnLeft () {
		dir--;
		if (dir < UP) dir = LEFT;
		update = true;
	}

	public void setPos (Vector2Marked pos) {
		tmpX = pos.x;
		tmpY = pos.y;
		allBody[0].set(tmpX, tmpY);
	}

	public void bodyPlusPlus () {
		allBody[bodyLength + 1].x = allBody[bodyLength].x;
		allBody[bodyLength + 1].y = allBody[bodyLength].y;
		// Since marked position moves down the entire body, it moves it down to
		// one square larger than the worm to remove it, this removes that or
		// there will be animation when the next body bit appears
		allBody[bodyLength].removeMarked();
		bodyLength++;
	}

	public void markHead () {
		// Marks the head for animation - growing/shrinking bit
		allBody[0].setMarked();
	}

	public Vector2Marked[] getAllBody () {
		return allBody;
	}

	public Vector2Marked getBodySegment (int segment) {
		return allBody[segment];
	}

	public Vector2Marked getHead () {
		return allBody[0];
	}

	public int getHeadIntX () {
		return (int)allBody[0].x;
	}

	public int getHeadIntY () {
		return (int)allBody[0].y;
	}

	private float getHeadX () {
		return allBody[0].x;
	}

	private float getHeadY () {
		return allBody[0].y;
	}

	private void setHeadX (float x) {
		allBody[0].x = x;
	}

	private void setHeadY (float y) {
		allBody[0].y = y;
	}

	public int getBodyLength () {
		return bodyLength;
	}

	public int getScore () {
		return score;
	}
}
