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
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Pixmap.Format;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.NinePatch;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Button;
import com.badlogic.gdx.scenes.scene2d.ui.Button.ButtonStyle;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Label.LabelStyle;
import com.badlogic.gdx.scenes.scene2d.ui.ScrollPane;
import com.badlogic.gdx.scenes.scene2d.ui.ScrollPane.ScrollPaneStyle;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton.TextButtonStyle;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.NinePatchDrawable;
import com.badlogic.gdx.utils.viewport.StretchViewport;

/** @author oddlydrawn */
public class LicenseScreen implements Screen {
	final String TEXTURE_ATLAS_LOC = "data/pack.atlas";
	final String LABEL_PADDING = " ";
	final String FONT_LOC = "data/font/fine_print.fnt";
	final String LICENSE_LOC = "data/LICENSE-2.0.txt";
	final String PATCH_BOX_REGION_STRING = "box";
	final float WIDTH = 480;
	final float HEIGHT = 320;
	final float TABLE_PADDING = 5f;
	String licenseString = "mew";
	Stage stage;
	Skin skin;
	SpriteBatch batch;
	Game game;
	TextureAtlas atlas;

	public LicenseScreen (Game g) {
		game = g;
		stage = new Stage();
		skin = new Skin();
		batch = new SpriteBatch();
		FileHandle handle;
		handle = Gdx.files.internal(LICENSE_LOC);
		licenseString = handle.readString();

		atlas = new TextureAtlas(Gdx.files.internal(TEXTURE_ATLAS_LOC));

		NinePatch patchBox;
		patchBox = new NinePatch(atlas.createPatch(PATCH_BOX_REGION_STRING));

		Gdx.input.setInputProcessor(stage);
		stage.setViewport(new StretchViewport(WIDTH, HEIGHT));
		Table table = new Table();
		table.setFillParent(true);
		stage.addActor(table);

		Pixmap pixmap = new Pixmap(1, 1, Format.RGBA8888);
		pixmap.setColor(Color.LIGHT_GRAY);
		pixmap.fill();

		// The following defines the defaults for Scene2D's skin
		skin.add("grey", new Texture(pixmap));
		skin.add("default", new BitmapFont(Gdx.files.internal(FONT_LOC)));

		LabelStyle labelStyle = new LabelStyle();
		labelStyle.font = skin.getFont("default");
		skin.add("default", labelStyle);

		ScrollPaneStyle scrollPaneStyle = new ScrollPaneStyle();
		skin.add("default", scrollPaneStyle);

		ButtonStyle buttonStyle = new ButtonStyle();
		skin.add("default", buttonStyle);

		TextButtonStyle textButtonStyle = new TextButtonStyle();
		textButtonStyle.font = skin.getFont("default");
		textButtonStyle.up = new NinePatchDrawable(patchBox);
		skin.add("default", textButtonStyle);

		// Creates Actors (the entire LICENSE text file) for Scene2D
		Label license = new Label(licenseString, skin);
		ScrollPane scrollPane = new ScrollPane(license, skin);
		scrollPane.setFlickScroll(true);
		table.add(scrollPane);

		// Creates the padding between the text and the button.
		table.row();
// Label padding = new Label(LABEL_PADDING, skin);
// table.add(padding);

		// Creates the 'Okay' button
		table.row();
		TextButton okay = new TextButton("Okay", skin);
		table.add(okay);
		okay.addListener(new ChangeListener() {
			public void changed (ChangeEvent event, Actor actor) {
				dispose();
				game.setScreen(new MainMenuScreen(game));
			}
		});

		// Adds padding on top and on the bottom of the table.
		table.padTop(TABLE_PADDING);
		table.padBottom(TABLE_PADDING);
		table.pack();
	}

	public void resize (int width, int height) {
		stage.getViewport().update(width, height, true);

	}

	public void render (float delta) {
		Gdx.gl.glClearColor(0.2f, 0.2f, 0.2f, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		stage.act(delta);
		stage.draw();
	}

	public void dispose () {
		stage.dispose();
		batch.dispose();
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

}
