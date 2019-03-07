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

public class Food {
	ArrayList<Rectangle> foodList = new ArrayList<Rectangle>();
	private final float OUT_OF_BOUNDS = -50;
	Rectangle food;
	int eatenIndex;

	public Food () {
		foodList = new ArrayList<Rectangle>();
	}

	public void createOne (float x, float y, float SIZE) {
		food = foodList.get(eatenIndex);
		food.setX(x);
		food.setY(y);
		food.setWidth(SIZE);
		food.setHeight(SIZE);
	}

	public void createInitial (float x, float y, float SIZE) {
		food = new Rectangle(x, y, SIZE, SIZE);
		foodList.add(food);
	}

	public ArrayList<Rectangle> getFood () {
		return foodList;
	}

	public void removeOne (int index) {
		food = foodList.get(index);
		food.setX(OUT_OF_BOUNDS);
		food.setY(OUT_OF_BOUNDS);
		eatenIndex = index;
	}

	public ArrayList<Rectangle> getRectangles () {
		return foodList;
	}

	public int getNum () {
		return foodList.size();
	}

	public void update () {
		// TODO Create different colored fruits which disappear after a certain
		// amount of time then turn into regular fruits. Random chance involved

		// calculate distance, in updates, from food to fruit + random wiggle time room thing
	}
}
