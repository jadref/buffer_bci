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

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.NinePatch;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.badlogic.gdx.graphics.g2d.TextureAtlas.AtlasRegion;
import com.badlogic.gdx.graphics.g2d.TextureRegion;

public class Assets {

	final String FINE_PRINT = "data/font/fine_print.fnt";
	final String FONT_LOC = "data/font/dfont.fnt";
	final String TEXTURE_ATLAS_LOC = "data/pack.atlas";
	final String CHECKED_REGION_STRING = "checked";
	final String UNCHECKED_REGION_STRING = "unchecked";
	final String BACKGROUN_REGION_STRING = "background";
	final String KNOB_REGION_STRING = "knob";
	final String TITLE_REGION_STRING = "nahwc_title";
	final String PATCH_BOX_REGION_STRING = "box";
	final String LEVEL_ONE_REGION_STRING = "level1";
	final String LEVEL_TWO_REGION_STRING = "level2";
	final String LEVEL_THREE_REGION_STRING = "level3";
	final String LEVEL_FOUR_REGION_STRING = "level4";
	final String LEVEL_FIVE_REGION_STRING = "level5";


	TextureAtlas atlas;
	Sprite titleSprite;
	TextureRegion levelOnePreviewRegion;
	TextureRegion levelTwoPreviewRegion;
	TextureRegion levelThreePreviewRegion;
	TextureRegion levelFourPreviewRegion;
	TextureRegion levelFivePreviewRegion;
	BitmapFont finePrint;
	BitmapFont font;
	AtlasRegion checked;
	AtlasRegion unchecked;
	AtlasRegion background;
	AtlasRegion knob;
	NinePatch patchBox;

	public Assets () {
		
	}
	
	public void initMainMenu() {
		atlas = new TextureAtlas(Gdx.files.internal(TEXTURE_ATLAS_LOC));
		
		checked = atlas.findRegion(CHECKED_REGION_STRING);
		unchecked = atlas.findRegion(UNCHECKED_REGION_STRING);
		background = atlas.findRegion(BACKGROUN_REGION_STRING);
		knob = atlas.findRegion(KNOB_REGION_STRING);
		
		titleSprite = atlas.createSprite(TITLE_REGION_STRING);
		
		levelOnePreviewRegion = new TextureRegion(atlas.findRegion(LEVEL_ONE_REGION_STRING));
		levelTwoPreviewRegion = new TextureRegion(atlas.findRegion(LEVEL_TWO_REGION_STRING));
		levelThreePreviewRegion = new TextureRegion(atlas.findRegion(LEVEL_THREE_REGION_STRING));
		levelFourPreviewRegion = new TextureRegion(atlas.findRegion(LEVEL_FOUR_REGION_STRING));
		levelFivePreviewRegion = new TextureRegion(atlas.findRegion(LEVEL_FIVE_REGION_STRING));
		
		patchBox = new NinePatch(atlas.createPatch(PATCH_BOX_REGION_STRING));


		finePrint = new BitmapFont(Gdx.files.internal(FINE_PRINT));
		font = new BitmapFont(Gdx.files.internal(FONT_LOC));
	}
	
	public void disposeMainMenu() {
		atlas.dispose();
		font.dispose();
		finePrint.dispose();
	}

	public Sprite getTitleSprite () {
		return titleSprite;
	}

	public TextureRegion getLevelOnePreviewRegion () {
		return levelOnePreviewRegion;
	}

	public TextureRegion getLevelTwoPreviewRegion () {
		return levelTwoPreviewRegion;
	}

	public TextureRegion getLevelThreePreviewRegion () {
		return levelThreePreviewRegion;
	}

	public TextureRegion getLevelFourPreviewRegion () {
		return levelFourPreviewRegion;
	}

	public TextureRegion getLevelFivePreviewRegion () {
		return levelFivePreviewRegion;
	}

	public BitmapFont getFinePrint () {
		return finePrint;
	}

	public BitmapFont getFont () {
		return font;
	}

	public AtlasRegion getChecked () {
		return checked;
	}

	public AtlasRegion getUnchecked () {
		return unchecked;
	}

	public AtlasRegion getBackground () {
		return background;
	}

	public AtlasRegion getKnob () {
		return knob;
	}

	public NinePatch getPatchBox () {
		return patchBox;
	}

	public void setTitleSprite (Sprite titleSprite) {
		this.titleSprite = titleSprite;
	}

	public void setLevelOnePreviewRegion (TextureRegion levelOnePreviewRegion) {
		this.levelOnePreviewRegion = levelOnePreviewRegion;
	}

	public void setLevelTwoPreviewRegion (TextureRegion levelTwoPreviewRegion) {
		this.levelTwoPreviewRegion = levelTwoPreviewRegion;
	}

	public void setLevelThreePreviewRegion (TextureRegion levelThreePreviewRegion) {
		this.levelThreePreviewRegion = levelThreePreviewRegion;
	}

	public void setLevelFourPreviewRegion (TextureRegion levelFourPreviewRegion) {
		this.levelFourPreviewRegion = levelFourPreviewRegion;
	}

	public void setLevelFivePreviewRegion (TextureRegion levelFivePreviewRegion) {
		this.levelFivePreviewRegion = levelFivePreviewRegion;
	}

	public void setFinePrint (BitmapFont finePrint) {
		this.finePrint = finePrint;
	}

	public void setFont (BitmapFont font) {
		this.font = font;
	}

	public void setChecked (AtlasRegion checked) {
		this.checked = checked;
	}

	public void setUnchecked (AtlasRegion unchecked) {
		this.unchecked = unchecked;
	}

	public void setBackground (AtlasRegion background) {
		this.background = background;
	}

	public void setKnob (AtlasRegion knob) {
		this.knob = knob;
	}

	public void setPatchBox (NinePatch patchBox) {
		this.patchBox = patchBox;
	}
}
