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

import java.util.ArrayList;

import com.badlogic.gdx.math.Rectangle;

/** @author oddlydrawn */
public class CheckCollision {
	ArrayList<Rectangle> foodList;
	Vector2Marked bodySegment;
	Rectangle headRect;
	Rectangle bodyRect;
	Rectangle foodRect;
	Level level;
	Worm worm;
	Food food;
	int[][] levelArray;
	int bodyLength;
	int levelTile;
	int numFood;
	int tmpX;
	int tmpY;

	public CheckCollision (Food food, Worm worm, Level level) {
		this.food = food;
		this.worm = worm;
		this.level = level;
		bodyRect = new Rectangle();
		foodRect = new Rectangle();
		foodList = food.getRectangles();
		setWorm(worm);
		setLevel(level);
	}

	public boolean wormAndWorm () {
		updateHead();
		bodyLength = worm.getBodyLength();
		// headRect is zero
		for (int i = 1; i < bodyLength; i++) {
			bodySegment = worm.getBodySegment(i);
			bodyRect.x = bodySegment.x;
			bodyRect.y = bodySegment.y;
			bodyRect.width = Level.SIZE;
			bodyRect.height = Level.SIZE;
			if (headRect.overlaps(bodyRect)) return true;
		}
		return false;
	}

	public boolean wormAndWall () {
		tmpX = worm.getHeadIntX();
		tmpY = worm.getHeadIntY();
		return wallCollidesWith(tmpX, tmpY);
	}

	public boolean wormAndFood () {
		updateHead();
		numFood = food.getNum();
		for (int i = 0; i < numFood; i++) {
			foodRect = foodList.get(i);
			if (foodRect.overlaps(headRect)) {
				food.removeOne(i);
				return true;
			}
		}
		return false;
	}

	public boolean thisAndAll (Rectangle testRect) {
		numFood = food.getNum();
		for (int i = 0; i < numFood; i++) {
			foodRect = foodList.get(i);
			if (foodRect.overlaps(testRect)) return true;
		}

		tmpX = (int)testRect.x;
		tmpY = (int)testRect.y;
		if (wallCollidesWith(tmpX, tmpY)) return true;

		bodyLength = worm.getBodyLength();
		for (int i = 0; i < bodyLength; i++) {
			bodySegment = worm.getBodySegment(i);
			bodyRect.x = bodySegment.x;
			bodyRect.y = bodySegment.y;
			bodyRect.width = Level.SIZE;
			bodyRect.height = Level.SIZE;
			if (testRect.overlaps(bodyRect)) return true;
		}
		return false;
	}

	private boolean wallCollidesWith (float x, float y) {
		tmpX = (int)x / Level.SIZE;
		tmpY = (int)y / Level.SIZE;

		levelTile = levelArray[tmpX][tmpY];
		return (levelTile == Level.WALL);
	}

	private void updateHead () {
		headRect.x = worm.getHeadIntX();
		headRect.y = worm.getHeadIntY();
	}

	public void setWorm (Worm w) {
		tmpX = w.getHeadIntX();
		tmpY = w.getHeadIntY();
		headRect = new Rectangle(tmpX, tmpY, Level.SIZE, Level.SIZE);
	}

	public void setLevel (Level level) {
		levelArray = level.getLevelArray();
	}
}
