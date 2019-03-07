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

import java.util.Random;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer.ShapeType;
import com.badlogic.gdx.math.Rectangle;

public class Renderer {
	private final String FONT_LOC = "data/font/dfont.fnt";
	private final String SCORE_STRING = "Score: ";
	private final String HI_SCORE_STRING = "HiScore: ";
	private final float HALF = 0.5f;
	private final float DEFAULT_RED = 0.8f;
	private final int SCORE_STRING_HEIGHT = 40;
	private final int SCORE_HORIZ_POS = 10;
	private final int HI_SCORE_STRING_HORIZ_POS = 36;
	private final int HI_SCORE_HORIZ_POS = 49;
	private final int V_PAD = 2;
	private ShapeRenderer shapeRenderer;
	private OrthographicCamera cam;
	private Random random;
	private Rectangle oneFood;
	private Color color;
	private Worm worm;
	private Food food;
	private Rectangle rect;
	private Vector2Marked[] wholeWorm;
	private SpriteBatch batch;
	private BitmapFont font;
	private String tmpString;
	private float drawOffset;
	private float r = 1;
	private float g = 255;
	private float b = 255;
	private float halfTileSize;
	private int[][] levelArray;
	private int score;
	private int hiScore;
	private int scoreHeight;
	private int hiScoreWidth;
	private int scoreNumberWidth;
	private int scoreHiNumberWidth;
	private boolean filled = true;

	public Renderer (OrthographicCamera cam, Worm worm, Food food, Level level) {
		font = new BitmapFont(Gdx.files.internal(FONT_LOC));
		this.cam = cam;
		this.worm = worm;
		wholeWorm = worm.getAllBody();
		this.food = food;
		levelArray = level.getLevelArray();
		shapeRenderer = new ShapeRenderer();
		random = new Random();
		color = new Color();
		color.r = Color.WHITE.r;
		color.g = Color.WHITE.g;
		color.b = Color.WHITE.b;
		color.a = Color.WHITE.a;
		rect = new Rectangle();
		batch = new SpriteBatch();
	}

	public void update (float animSize) {
		Gdx.gl.glClearColor(0.2f, 0.2f, 0.2f, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		cam.update();
		shapeRenderer.setProjectionMatrix(cam.combined);
		if (filled) {
			shapeRenderer.begin(ShapeType.Filled);
		} else {
			shapeRenderer.begin(ShapeType.Line);
		}
		renderWorld();
		renderWorm(animSize);
		renderFood();
		shapeRenderer.end();

		batch.setProjectionMatrix(cam.combined);
		batch.begin();
		renderTextUI();
		batch.end();
	}

	private void renderWorld () {
		// walls
		shapeRenderer.setColor(Color.GRAY);
		for (int y = Level.TILES_HEIGHT - 1; y >= 0; y--) {
			for (int x = 0; x < Level.TILES_WIDTH; x++) {
				if (levelArray[x][y] == Level.WALL) {
					rect.x = x * Level.SIZE;
					rect.y = y * Level.SIZE;
					rect.width = Level.SIZE;
					rect.height = Level.SIZE;
					shapeRenderer.rect(rect.x, rect.y, rect.width, rect.height);
				}
			}
		}
	}

	private void renderFood () {
		// food
		shapeRenderer.setColor(Color.WHITE);
		for (int i = 0; i < food.getRectangles().size(); i++) {
			oneFood = food.getRectangles().get(i);
			shapeRenderer.rect(oneFood.x, oneFood.y, oneFood.width, oneFood.height);
		}
	}

	private void renderWorm (float animSize) {
		shapeRenderer.setColor(color);
		halfTileSize = Level.SIZE * HALF;
		// XXX I set up the problem wrong, though, and I subtract Level's size to fix it
		drawOffset = HALF * animSize + halfTileSize;
		drawOffset -= Level.SIZE;
		for (int i = 0; i < worm.getBodyLength(); i++) {
			if (wholeWorm[i].getMarked() == true) {
				rect.x = wholeWorm[i].x - drawOffset;
				rect.y = wholeWorm[i].y - drawOffset;
				rect.height = animSize;
				rect.width = animSize;
			} else {
				rect.x = wholeWorm[i].x;
				rect.y = wholeWorm[i].y;
				rect.height = Level.SIZE;
				rect.width = Level.SIZE;
			}
			shapeRenderer.rect(rect.x, rect.y, rect.width, rect.height);
		}
	}

	private void renderTextUI () {
		// Draws regular Score.
		score = worm.getScore();
		tmpString = Integer.toString(score);
		font.draw(batch, SCORE_STRING, 0, scoreHeight);
		font.draw(batch, tmpString, scoreNumberWidth, scoreHeight);

		// Draws HiScore.
		tmpString = Integer.toString(hiScore);
		font.draw(batch, HI_SCORE_STRING, hiScoreWidth, scoreHeight);
		font.draw(batch, tmpString, scoreHiNumberWidth, scoreHeight);
	}

	public void changeColor () {
		r = random.nextFloat();
		g = random.nextFloat();
		b = random.nextFloat();
		// It might be too dark, this might fix that.
		if ((r < HALF && g < HALF) && (g < HALF && b < HALF)) {
			r = DEFAULT_RED;
		}
		color.r = r;
		color.g = g;
		color.b = b;
	}

	public void changeOutline () {
		filled = !filled;
	}

	public OrthographicCamera getCam () {
		return cam;
	}

	public void setHiScore (int hiScore) {
		this.hiScore = hiScore;
	}

	public void init () {
		scoreHeight = SCORE_STRING_HEIGHT * Level.SIZE + V_PAD;
		scoreNumberWidth = SCORE_HORIZ_POS * Level.SIZE;
		hiScoreWidth = HI_SCORE_STRING_HORIZ_POS * Level.SIZE;
		scoreHiNumberWidth = HI_SCORE_HORIZ_POS * Level.SIZE;
	}

	public void dispose () {
		font.dispose();
		shapeRenderer.dispose();
		batch.dispose();
	}
}
