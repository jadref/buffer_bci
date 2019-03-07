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
import com.badlogic.gdx.files.FileHandle;
import com.tumblr.oddlydrawn.stupidworm.screens.MainMenuScreen;

public class SavedStuff {
	private final float UPDATE_SPEED_DECREASE_ZERO = 0.0003125f; // 0.0003125f
	private final float UPDATE_SPEED_DECREASE_ONE = 0.000625f; // 0.000625f
	private final float UPDATE_SPEED_DECREASE_TWO = 0.00125f; // 0.00125f
	private final float UPDATE_SPEED_DECREASE_THREE = 0.0025f; // 0.0025f
	private final float UPDATE_SPEED_DECREASE_FOUR = 0.005f; // 0.005f
	private final float UPDATE_SPEED_DECREASE_FIVE = 0.01f; // 0.01f
	private final String PREFERENCES_FILENAME = "nahwc-prefs.txt";
	private final String SCORES_STRING = "scores";
	private final String NO_FAST_STRING = "noFast";
	private final String FILE_EXT = ".txt";
	private final String DEFAULT_PREF_STRING = "00000010";
	private String scoreString;
	private String scoresFile;
	private float timeToUpdate = 1f; // 0.2f
	private float decreaseSpeed;
	private int levelNumber;
	private int fasterSpeed;
	private int hiScore;
	private boolean isFaster;
	private boolean isColor;
	private boolean isAnimate;
	private boolean isSound;
	private boolean isOutline;
	private boolean isPermOutline;
	
	public SavedStuff () {
		
	}
	
	private int[][] allScores;
	public static int NUMBER_OF_LEVELS = 6;
	public static int NUMBER_OF_SPEEDS = 7;

	public void loadAllScoresIntoArray () {
		allScores = new int[NUMBER_OF_LEVELS][NUMBER_OF_SPEEDS];
		

		// Creates correct filename for scores file
		FileHandle handle;
		StringBuilder scoresFileBuilder = new StringBuilder();
		
		for(int x = 0; x < NUMBER_OF_LEVELS; x++) {
			for(int y = 0; y < NUMBER_OF_SPEEDS; y++) {
				levelNumber = x;
				fasterSpeed = y;
				if (fasterSpeed == NUMBER_OF_SPEEDS - 1) {
					isFaster = false;
				} else {
					isFaster = true;
				}
				
				scoresFileBuilder.setLength(0);
				scoresFileBuilder.append(SCORES_STRING);
				scoresFileBuilder.append(String.valueOf(levelNumber));
				if (isFaster) {
					scoresFileBuilder.append(String.valueOf(fasterSpeed));
				} else {
					scoresFileBuilder.append(NO_FAST_STRING);
				}
				scoresFileBuilder.append(FILE_EXT);
				scoresFile = scoresFileBuilder.toString();

				// Checks if scores file exists, creates one if not
				if (Gdx.files.local(scoresFile).exists()) {
					handle = Gdx.files.local(scoresFile);
				} else {
					handle = Gdx.files.local(scoresFile);
					scoreString = Integer.toString(0);
					handle.writeString(scoreString, false);
				}

				scoreString = handle.readString();
				try {
					hiScore = Integer.parseInt(scoreString);
				} catch (NumberFormatException e) {
					hiScore = 0;
				}
				allScores[levelNumber][fasterSpeed] = hiScore;
			}
		}	
		loadPreferencesAndScore();
	}
	
	private void printAllScores () {
		for(int x = 0; x < NUMBER_OF_LEVELS; x++) {
			for(int y = 0; y < NUMBER_OF_SPEEDS; y++) {
				levelNumber = x;
				fasterSpeed = y;
				System.out.print("  " + allScores[levelNumber][fasterSpeed]);
			}
			System.out.println();
		}
	}
	
	public void loadPreferencesAndScore() {
		loadPreferences();
		loadScore();
	}
	
	private void loadPreferences () {
		// Loads the preferences saved from the MainMenuScreen.
		String prefString;
		FileHandle prefHandle;
		if (Gdx.files.local(PREFERENCES_FILENAME).exists()) {
			prefHandle = Gdx.files.local(PREFERENCES_FILENAME);
		} else {
			prefHandle = Gdx.files.local(PREFERENCES_FILENAME);
			prefString = DEFAULT_PREF_STRING;
			prefHandle.writeString(prefString, false);
		}
		prefString = prefHandle.readString();

		char one = '1';
		// True if character at string index is '1', false if '0'
		isFaster = (one == prefString.charAt(0));
		isColor = (one == prefString.charAt(1));
		isAnimate = (one == prefString.charAt(2));
		isSound = (one == prefString.charAt(3));
		isOutline = (one == prefString.charAt(4));
		isPermOutline = (one == prefString.charAt(5));
		levelNumber = Character.getNumericValue(prefString.charAt(6));
		fasterSpeed = Character.getNumericValue(prefString.charAt(7));

		if (fasterSpeed == 0) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_ZERO;
		} else if (fasterSpeed == 1) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_ONE;
		} else if (fasterSpeed == 2) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_TWO;
		} else if (fasterSpeed == 3) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_THREE;
		} else if (fasterSpeed == 4) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_FOUR;
		} else if (fasterSpeed == 5) {
			decreaseSpeed = UPDATE_SPEED_DECREASE_FIVE;
		}

		// Initital speed up
		timeToUpdate -= 5 * decreaseSpeed;
	}

	private void loadScore () {
		// Creates correct filename for scores file
		FileHandle handle;
		StringBuilder scoresFileBuilder = new StringBuilder();
		scoresFileBuilder.append(SCORES_STRING);
		scoresFileBuilder.append(String.valueOf(levelNumber));
		if (isFaster) {
			scoresFileBuilder.append(String.valueOf(fasterSpeed));
		} else {
			scoresFileBuilder.append(NO_FAST_STRING);
		}
		scoresFileBuilder.append(FILE_EXT);
		scoresFile = scoresFileBuilder.toString();

		// Checks if scores file exists, creates one if not
		if (Gdx.files.local(scoresFile).exists()) {
			handle = Gdx.files.local(scoresFile);
		} else {
			handle = Gdx.files.local(scoresFile);
			scoreString = Integer.toString(0);
			handle.writeString(scoreString, false);
		}

		scoreString = handle.readString();
		try {
			hiScore = Integer.parseInt(scoreString);
		} catch (NumberFormatException e) {
			hiScore = 0;
		}
	}
	
	public void saveScore (int hiScore) {
		FileHandle handle = Gdx.files.local(scoresFile);
		scoreString = Integer.toString(hiScore);
		handle.writeString(scoreString, false);
	}
	
	public void savePreferences () {
		// Creates a string full of preferences.
		StringBuilder stringBuilder = new StringBuilder();
		if (isFaster) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}
		if (isColor) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}
		if (isAnimate) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}
		if (isSound) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}
		if (isOutline) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}
		if (isPermOutline) {
			stringBuilder.append("1");
		} else {
			stringBuilder.append("0");
		}

		String s;
		s = String.valueOf(levelNumber);
		stringBuilder.append(s);
		s = String.valueOf(fasterSpeed);
		stringBuilder.append(s);
		
		String prefString = stringBuilder.toString();
		
		FileHandle handle = Gdx.files.local(PREFERENCES_FILENAME);
		// Saves said preference string.
		handle.writeString(prefString, false);
	}

	public int[][] getAllScores() {
		return allScores;
	}
	
	public int getLevelNumber () {
		return levelNumber;
	}

	public float getTimeToUpdate () {
		return timeToUpdate;
	}

	public float getDecreaseSpeed () {
		return decreaseSpeed;
	}

	public int getFasterSpeed () {
		return fasterSpeed;
	}

	public int getHiScore () {
		return hiScore;
	}

	public boolean isFaster () {
		return isFaster;
	}

	public boolean isColor () {
		return isColor;
	}

	public boolean isAnimate () {
		return isAnimate;
	}

	public boolean isSound () {
		return isSound;
	}

	public boolean isOutline () {
		return isOutline;
	}

	public boolean isPermOutline () {
		return isPermOutline;
	}

	public void setLevelNumber (int levelNumber) {
		this.levelNumber = levelNumber;
	}

	public void setFasterSpeed (int fasterSpeed) {
		this.fasterSpeed = fasterSpeed;
	}

	public void setFaster (boolean isFaster) {
		this.isFaster = isFaster;
	}

	public void setColor (boolean isColor) {
		this.isColor = isColor;
	}

	public void setAnimate (boolean isAnimate) {
		this.isAnimate = isAnimate;
	}

	public void setSound (boolean isSound) {
		this.isSound = isSound;
	}

	public void setOutline (boolean isOutline) {
		this.isOutline = isOutline;
	}

	public void setPermOutline (boolean isPermOutline) {
		this.isPermOutline = isPermOutline;
	}
}
