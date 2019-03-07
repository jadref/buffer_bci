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

import com.badlogic.gdx.maps.tiled.TiledMap;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer;
import com.badlogic.gdx.maps.tiled.TiledMapTileLayer.Cell;
import com.badlogic.gdx.maps.tiled.TmxMapLoader;
import com.badlogic.gdx.math.Vector2;

/** @author oddlydrawn */
public class Level {
	public static final int TILES_WIDTH = 60;
	public static final int TILES_HEIGHT = 40;
	public static final int WALL = 1;
	public final static int SIZE = 8;
	private final String COLLIDES = "collides";
	private final String START = "start";
	private final String LEVEL_PREFIX = "data/maps/level";
	private final String LEVEL_POSTFIX = ".tmx";
	private String level;
	private int[][] levelArray;
	private Vector2 startCoords;
	private int tmpX;
	private int tmpY;

	public Level (int levelNum) {
		startCoords = new Vector2();

		// Loads the level the user selected at the MainMenuScreen, obtained from God
		String lvl = Integer.toString(levelNum);
		level = LEVEL_PREFIX + lvl + LEVEL_POSTFIX;
		levelArray = new int[TILES_WIDTH][TILES_HEIGHT];
	}

	public void loadLevel () {
		TiledMap tiledMap;
		TiledMapTileLayer layer;
		Cell cell;

		// Creates the map objects and loads the appropriate level.
		tiledMap = new TiledMap();
		cell = new Cell();
		tiledMap = new TmxMapLoader().load(level);

		// Gets the collision layer from the map.
		layer = (TiledMapTileLayer)tiledMap.getLayers().get(0);
		cell = layer.getCell(0, 0);
		int width = layer.getWidth();
		int height = layer.getHeight();

		// Goes through all the tiles in the layer, looking for tiles with walls
		// and a single tile with the start position for the worm.
		for (int x = 0; x < width; x++) {
			for (int y = 0; y < height; y++) {
				cell = layer.getCell(x, y);
				if (cell != null) {
					if (hasCollides(cell)) {
						levelArray[x][y] = 1;
					} else if (hasStart(cell)) {
						startCoords.x = x * SIZE;
						startCoords.y = y * SIZE;
						levelArray[x][y] = 0;
					} else {
						levelArray[x][y] = 0;
					}
				}
			}
		}
		tiledMap.dispose();
	}

	private boolean hasCollides (Cell cell) {
		if (cell.getTile().getProperties().containsKey(COLLIDES)) {
			return true;
		}
		return false;
	}

	private boolean hasStart (Cell cell) {
		if (cell.getTile().getProperties().containsKey(START)) {
			return true;
		}
		return false;
	}

	public Vector2 getStartCoords () {
		return startCoords;
	}

	public boolean isWallAt (float x, float y) {
		tmpX = (int)x;
		tmpY = (int)y;
		tmpX /= SIZE;
		tmpY /= SIZE;
		if (levelArray[tmpX][tmpY] == WALL) return true;

		return false;
	}

	public int[][] getLevelArray () {
		return levelArray;
	}
}
