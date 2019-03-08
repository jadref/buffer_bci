/*
 *   Copyright 2015 oddlydrawn
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

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Pixmap.Format;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.NinePatch;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureAtlas.AtlasRegion;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Button.ButtonStyle;
import com.badlogic.gdx.scenes.scene2d.ui.CheckBox;
import com.badlogic.gdx.scenes.scene2d.ui.CheckBox.CheckBoxStyle;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Label.LabelStyle;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Slider;
import com.badlogic.gdx.scenes.scene2d.ui.Slider.SliderStyle;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton.TextButtonStyle;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.NinePatchDrawable;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.viewport.StretchViewport;
import com.tumblr.oddlydrawn.stupidworm.screens.LicenseScreen;
import com.tumblr.oddlydrawn.stupidworm.screens.LoadingScreen;
import com.tumblr.oddlydrawn.stupidworm.screens.MainMenuScreen;

public class MainMenuInterface {
	final String LABEL_FASTER = "Faster?";
	final String LABEL_COLOR = "Color?";
	final String LABEL_SOUND = "Sound?";
	final String LABEL_ANIMATE = "Animate?";
	final String LABEL_OUTLINE = "Outline?";
	final String LABEL_PERM_OUTLINE = "Perm Outline?";
	final String LABEL_LEVEL_SELECT = "Level:";
	final String LABEL_FASTER_SELECT = "Faster Speed:";
	final float TITLE_SPRITE_POS_X = -128;
	final float TITLE_SPRITE_POS_Y = 80;
	boolean isFaster = false;
	boolean isColor = false;
	boolean isSound = false;
	boolean isAnimate = false;
	boolean isOutline = false;
	boolean isPermOutline = false;
	int levelNumber = 0;
	int fasterSpeed = 0;
	private final String HI_SCORE_STRING = "HiScore: ";
	private int[][] allScores;
	Stage stage;
	Skin skin;
	OrthographicCamera cam;
	SpriteBatch batch;
	SavedStuff savedStuff;
	TextureRegion levelPreviewRegion;
	Sprite titleSprite;
	Game game;
	StringBuilder hiScoreBuilder;
	int hiScore;
	String highScoreString;
	Assets assets;
	AtlasRegion checked;
	AtlasRegion unchecked;
	AtlasRegion background;
	AtlasRegion knob;
	NinePatch patchBox;
	BitmapFont finePrint;
	BitmapFont font;
	Table table;
	
	public MainMenuInterface () {
		
	}
	
	public void init(Game game, Assets assets) {
		hiScoreBuilder = new StringBuilder();
		savedStuff = new SavedStuff();
		skin = new Skin();
		stage = new Stage();
		batch = new SpriteBatch();
		cam = new OrthographicCamera(MainMenuScreen.WIDTH, MainMenuScreen.HEIGHT);
		Gdx.input.setInputProcessor(stage);
		stage.setViewport(new StretchViewport(MainMenuScreen.WIDTH, MainMenuScreen.HEIGHT));
		batch.setProjectionMatrix(cam.combined);
		this.game = game;
		this.assets = assets;
		
		loadMainMenuAssets();
		setUpSkin();
		createTable();
		createStageActors();
		addStageActorsToStage();
		setActorsToDefaults();
		addListenersToActors();
	}
	
	public void loadMainMenuAssets() {
		checked = assets.getChecked();
		unchecked = assets.getUnchecked();
		background = assets.getBackground();
		knob = assets.getKnob();
		patchBox = assets.getPatchBox();
		finePrint = assets.getFinePrint();
		font = assets.getFont();
		titleSprite = assets.getTitleSprite();
	}
	
	private void setUpSkin() {
		Pixmap pixmap = new Pixmap(1, 1, Format.RGBA8888);
		pixmap.setColor(Color.LIGHT_GRAY);
		pixmap.fill();
		skin.add("grey", new Texture(pixmap));
		titleSprite.setX(TITLE_SPRITE_POS_X);
		titleSprite.setY(TITLE_SPRITE_POS_Y);

		LabelStyle labelStyle = new LabelStyle();
		skin.add("default", finePrint);
		labelStyle.font = skin.getFont("default");
		skin.add("default", labelStyle);

		CheckBoxStyle checkBoxStyle = new CheckBoxStyle();
		checkBoxStyle.checkboxOff = skin.newDrawable("grey", Color.LIGHT_GRAY);
		checkBoxStyle.checkboxOn = skin.newDrawable("grey", Color.LIGHT_GRAY);
		checkBoxStyle.font = skin.getFont("default");
		checkBoxStyle.checkboxOff = new TextureRegionDrawable(unchecked);
		checkBoxStyle.checkboxOn = new TextureRegionDrawable(checked);
		skin.add("default", checkBoxStyle);

		SliderStyle sliderStyle = new SliderStyle();
		sliderStyle.background = new TextureRegionDrawable(background);
		sliderStyle.knob = new TextureRegionDrawable(knob);
		skin.add("default-horizontal", sliderStyle);

		ButtonStyle buttonStyle = new ButtonStyle();
		skin.add("default", buttonStyle);

		TextButtonStyle textButtonStyle = new TextButtonStyle();
		textButtonStyle.font = skin.getFont("default");
		textButtonStyle.up = new NinePatchDrawable(patchBox);
		skin.add("default", textButtonStyle);
	}
	
	private void createTable() {
		table = new Table();
		table.setFillParent(true);
		table.align(Align.left);
		stage.addActor(table);
	}
	
	CheckBox faster;
	CheckBox color;
	CheckBox animate;
	CheckBox sound;
	CheckBox outline;
	CheckBox permOutline;
	Slider fasterSlider;
	Slider levelSlider;
	TextButton start;
	TextButton license;

	Label fasterLabel;
	Label levelLabel;
	
	private void createStageActors() {
		faster = new CheckBox(LABEL_FASTER, skin);

		color = new CheckBox(LABEL_COLOR, skin);

		animate = new CheckBox(LABEL_ANIMATE, skin);

		sound = new CheckBox(LABEL_SOUND, skin);
		table.setPosition(210, 30);

		outline = new CheckBox(LABEL_OUTLINE, skin);

		permOutline = new CheckBox(LABEL_PERM_OUTLINE, skin);

		fasterLabel = new Label(LABEL_FASTER_SELECT, skin);
		fasterLabel.setPosition(240 - fasterLabel.getWidth() / 2, 115);

		fasterSlider = new Slider(0, 5, 1, false, skin);
		fasterSlider.setWidth(outline.getWidth());
		fasterSlider.setPosition(240 - fasterSlider.getWidth() / 2, 100);

		levelLabel = new Label(LABEL_LEVEL_SELECT, skin);
		levelLabel.setPosition(240 - levelLabel.getWidth() / 2, 85);

		levelSlider = new Slider(0, 5, 1, false, skin);
		levelSlider.setWidth(outline.getWidth());
		levelSlider.setPosition(240 - levelSlider.getWidth() / 2, 70);

		start = new TextButton("Start", skin);
		start.setPosition(210, 36);

		license = new TextButton("License", skin);
		license.setPosition(205, 2);

		fasterLabel.setY(215);
		fasterSlider.setY(200);

		levelLabel.setY(185);
		levelSlider.setY(170);
	}
	
	private void addStageActorsToStage() {
		table.add(faster).align(Align.left);

		table.row();
		table.add(color).align(Align.left);

		table.row();
		table.add(animate).align(Align.left);

		table.row();
		table.add(sound).align(Align.left);

		table.row();
		table.add(outline).align(Align.left);

		table.row();
		table.add(permOutline).align(Align.left);

		stage.addActor(fasterLabel);
		stage.addActor(fasterSlider);
		stage.addActor(levelLabel);
		stage.addActor(levelSlider);

		table.row();
		stage.addActor(start);
		stage.addActor(license);
		
		table.setPosition(210, -40);
	}
	
	private void setActorsToDefaults () {
		loadSavedStuff();

		// If preferences were set, this ticks the checkboxes and sets the sliders
		// to what they were saved
		faster.setChecked(isFaster);
		color.setChecked(isColor);
		animate.setChecked(isAnimate);
		sound.setChecked(isSound);
		outline.setChecked(isOutline);
		permOutline.setChecked(isPermOutline);
		permOutline.setVisible(isOutline);
		levelSlider.setValue(levelNumber);
		fasterSlider.setValue(fasterSpeed);
	}
	
	private void addListenersToActors() {
		faster.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isFaster = faster.isChecked();
			}
		});
		color.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isColor = color.isChecked();
			}
		});
		animate.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isAnimate = animate.isChecked();
			}
		});
		sound.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isSound = sound.isChecked();
			}
		});
		outline.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isOutline = outline.isChecked();

				// Hides the permanent outline option if they don't want outlines.
				permOutline.setVisible(isOutline);
				if (isOutline == false) {
					isPermOutline = false;
					permOutline.setChecked(false);
				}
			}
		});
		permOutline.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				isPermOutline = permOutline.isChecked();
			}
		});
		start.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				hide();
				dispose();
				game.setScreen(new LoadingScreen(game));
			}
		});
		license.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				hide();
				dispose();
				game.setScreen(new LicenseScreen(game));
			}
		});
		//FINISH
		levelSlider.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				levelNumber = (int)levelSlider.getValue();
			}
		});
		fasterSlider.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				fasterSpeed = (int)fasterSlider.getValue();
			}
		});
	}
	
	private void hide() {
		setPreferences();
		savePreferences();
	}
	
	private void loadSavedStuff () {
		savedStuff.loadPreferencesAndScore();
		
		levelNumber = savedStuff.getLevelNumber();
		isFaster = savedStuff.isFaster();
		isColor = savedStuff.isColor();
		isAnimate = savedStuff.isAnimate();
		isSound = savedStuff.isSound();
		isOutline = savedStuff.isOutline();
		isPermOutline = savedStuff.isPermOutline();
		levelNumber = savedStuff.getLevelNumber();
		fasterSpeed = savedStuff.getFasterSpeed();
		
		savedStuff.loadAllScoresIntoArray();
		allScores = savedStuff.getAllScores();
	}
	
	private void setPreferences() {
		savedStuff.setFaster(isFaster);
		savedStuff.setColor(isColor);
		savedStuff.setAnimate(isAnimate);
		savedStuff.setSound(isSound);
		savedStuff.setOutline(isOutline);
		savedStuff.setPermOutline(isPermOutline);
		savedStuff.setFasterSpeed(fasterSpeed);
		savedStuff.setLevelNumber(levelNumber);
	}
	
	private void savePreferences() {
		savedStuff.savePreferences();
	}
	public void render(float delta) {
		// 286, 134
		batch.setProjectionMatrix(cam.combined);
		batch.begin();
		titleSprite.draw(batch);
		setLevelPreview();
		if (levelNumber != 0) {
			batch.draw(levelPreviewRegion, 50, -27);
		}
		hiScoreBuilder.setLength(0);
		hiScoreBuilder.append(HI_SCORE_STRING);
		if (isFaster) {
			hiScore = allScores[levelNumber][fasterSpeed];
		} else {
			hiScore = allScores[levelNumber][SavedStuff.NUMBER_OF_SPEEDS - 1];	
		}
		hiScoreBuilder.append(hiScore);
		highScoreString = hiScoreBuilder.toString();
		font.draw(batch, highScoreString, 50, 73);
		
		batch.end();
		stage.act(delta);
		stage.draw();
	}
	
	private void setLevelPreview () {
		switch (levelNumber) {
		case 1:
			levelPreviewRegion = assets.getLevelOnePreviewRegion();
			break;
		case 2:
			levelPreviewRegion = assets.getLevelTwoPreviewRegion();
			break;
		case 3:
			levelPreviewRegion = assets.getLevelThreePreviewRegion();
			break;
		case 4:
			levelPreviewRegion = assets.getLevelFourPreviewRegion();
			break;
		case 5:
			levelPreviewRegion = assets.getLevelFivePreviewRegion();
			break;
		default:
			break;
		}
	}
	
	public void resize(int width, int height) {
		stage.getViewport().update(width, height, true);
	}
	
	public void dispose() {
		batch.dispose();
		stage.dispose();
		skin.dispose();
		font.dispose();
		assets.disposeMainMenu();
	}
}
