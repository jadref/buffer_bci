package nl.dcc.buffer_bci;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import nl.fcdonders.fieldtrip.bufferclient.BufferClient;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.Header;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input.Keys;
import com.badlogic.gdx.Input.TextInputListener;
import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.FPSLogger;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.BitmapFont.TextBounds;
import com.badlogic.gdx.graphics.g2d.Sprite;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator;
import com.badlogic.gdx.graphics.g2d.freetype.FreeTypeFontGenerator.FreeTypeFontParameter;
import com.badlogic.gdx.utils.TimeUtils;

public class VisSpeller extends ApplicationAdapter {

	public class AdressListener implements TextInputListener {
		@Override
		public void canceled() {
			adress = "127.0.0.1";
			port = 1972;
		}

		@Override
		public void input(String text) {
			try {
				String split[] = text.split(":");
				adress = split[0];
				port = Integer.parseInt(split[1]);
				nextState();
			} catch (NumberFormatException e) {
				AdressListener listener = new AdressListener();
				Gdx.input.getTextInput(listener, "Bad buffer adress", text);
			} catch (ArrayIndexOutOfBoundsException e){
				AdressListener listener = new AdressListener();
				Gdx.input.getTextInput(listener, "Bad buffer adress", text);
			}
		}
	}

	private enum States {
		START, TRYING_TO_CONNECT, WAITING_FOR_HEADER, TRAINING_TEXT, TRAINING_CUE, TRAINING_GRID, FEEDBACK_TEXT, FEEDBACK_GRID, FEEDBACK_FEEDBACK, END, TRAINING_PAUSE, FEEDBACK_PAUSE, RETRYING_TO_CONNECT, LOST_CONNECTION, GET_ADRESS
	}

	private class Text {
		private final String text;
		private final float x;
		private final float y;

		public Text(String text_) {
			text = text_;
			TextBounds bounds = font.getBounds(text);
			x = Gdx.graphics.getWidth() / 2 - bounds.width / 2;
			y = Gdx.graphics.getHeight() / 2 - bounds.height / 2;
		}

		public Text(String text_, float x_, float y_) {
			text = text_;
			y = y_;
			x = x_;
		}

		public void draw() {
			Gdx.gl.glClearColor(0, 0, 0, 1);
			Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
			batch.begin();
			batch.enableBlending();
			font.draw(batch, text, x, y);
			batch.end();
		}

	}

	// PROGRAM STATE VARIABLES
	private States state = States.START;
	private boolean startOfState = true;
	private int nrTrainingSequences = 6;
	private int nrFeedbackSequences = 4;
	private List<Integer> trainingCues = new ArrayList<Integer>();
	private int xCue = 0;
	private int yCue = 0;

	// GRAPHICS RELATED VARIABLES
	private SpriteBatch batch;
	private BitmapFont font;
	private Sprite[][] gridWhite = new Sprite[6][5];
	private Sprite[][] gridGreen = new Sprite[6][5];
	private Sprite[][] gridRed = new Sprite[6][5];
	private Sprite[][] gridGray = new Sprite[6][5];

	// GRID FLASH RELATED VARIABLES
	private final static boolean[] ISCOLUMNFLASH = { true, true, true, true,
			true, true, false, false, false, false, false };
	private final static int[] NUMBERFLASH = { 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4 };
	private final static List<Integer> FLASHINDICES = Arrays.asList(0, 1, 2, 3,
			4, 5, 6, 7, 8, 9, 10);
	private final static int FLASHES_PER_STIMULUS = 5;
	private ArrayList<Integer> currentFlashes = new ArrayList<Integer>();
	private boolean flashOn = false;
	private int currentFlash = 0;

	// TIMING VARIABLES
	private long lastStateTime;
	private final static int TIME_FLASH = 150;
	private final static int TIME_CUE = 2000;
	private final static int TIME_FEEDBACK = 5000;
	private final static int TIME_PAUSE = 2000;
	private final static int TIME_RETRY_CLIENT = 1000;

	// TEXT VARIABLES
	private Text startText;
	private Text trainingText;
	private Text feedbackText;
	private Text endText;
	private Text tryConnectText;
	private Text headerText;
	private Text retryingText;
	private Text lostText;

	private FPSLogger fpslogger;

	// Buffer
	private final BufferClient ftc = new BufferClient();
	private int nSamples = 0;
	private float fSample = 0;
	private long lastUpdate = 0;
	private String adress = null;
	private int port = 1972;

	private void bufferHeader() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
		}
		headerText.draw();
		if (TimeUtils.millis() - lastStateTime > TIME_RETRY_CLIENT) {
			try {
				Header hdr = ftc.getHeader();
				nSamples = hdr.nSamples;
				fSample = hdr.fSample;
				lastUpdate = TimeUtils.millis();
				nextState();
			} catch (IOException e) {
				lastStateTime = TimeUtils.millis();
			}
		}
	}

	private void bufferRetry() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
		}
		retryingText.draw();
		if (TimeUtils.millis() - lastStateTime > TIME_RETRY_CLIENT) {
			try {
				 if ( !ftc.isConnected() ) {
					  ftc.connect(adress, port);
				 }
				Header hdr = ftc.getHeader();
				nSamples = hdr.nSamples;
				fSample = hdr.fSample;
				lastUpdate = TimeUtils.millis();
				nextState();
			} catch (IOException e) {
				System.out.println(e.getMessage());
				if (e.getMessage().endsWith("517")) {
					changeState(States.WAITING_FOR_HEADER);
				} else {
					lastStateTime = TimeUtils.millis();
				}
			}
		}
	}

	private void bufferTry() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
		}
		tryConnectText.draw();
		if (TimeUtils.millis() - lastStateTime > TIME_RETRY_CLIENT) {
			try {
				 if ( !ftc.isConnected() ) {
					  ftc.connect(adress, port);
				 }
				Header hdr = ftc.getHeader();
				nSamples = hdr.nSamples;
				fSample = hdr.fSample;
				lastUpdate = TimeUtils.millis();
				nextState();
			} catch (IOException e) {
				System.out.println(e.getMessage());
				if (e.getMessage().endsWith("517")) {
					changeState(States.WAITING_FOR_HEADER);
				} else {
					changeState(States.RETRYING_TO_CONNECT);
				}
			}
		}
	}

	private void changeState(States state) {
		this.state = state;
		startOfState = true;
	}

	@Override
	public void create() {
		// Grab the width and height of the screen for convenience.
		int width = Gdx.graphics.getWidth();
		int height = Gdx.graphics.getHeight();

		// Create a SpriteBatch for high-level 2d rendering
		batch = new SpriteBatch();

		// Create sprites for each column and row of the grid

		// Determine column and row sizes for the currently used screen. Defined
		// relative to the size of a 1080p screen.

		float gridWidth = height * (900f / 1080f) * (1080f / 900f);
		float gridHeight = height * (900f / 1080f);
		float rowColumnSize = height * (180f / 1080f);

		// Grabbing the grid texture.
		Texture gridTexture = new Texture("grid.png");

		// Create grid sprites
		for (int x = 0; x < 6; x++) {
			for (int y = 0; y < 5; y++) {
				TextureRegion texture = new TextureRegion(gridTexture,
						0 + x * 180, 720 - y * 180, 180, 180);
				gridWhite[x][y] = new Sprite(texture);
				gridWhite[x][y].setSize(rowColumnSize, rowColumnSize);
				gridWhite[x][y].setPosition(width / 2 - gridWidth / 2 + x
						* rowColumnSize, height / 2 - gridHeight / 2 + y
						* rowColumnSize);
				gridWhite[x][y].setColor(Color.WHITE);

				gridRed[x][y] = new Sprite(texture);
				gridRed[x][y].setSize(rowColumnSize, rowColumnSize);
				gridRed[x][y].setPosition(width / 2 - gridWidth / 2 + x
						* rowColumnSize, height / 2 - gridHeight / 2 + y
						* rowColumnSize);
				gridRed[x][y].setColor(Color.RED);

				gridGreen[x][y] = new Sprite(texture);
				gridGreen[x][y].setSize(rowColumnSize, rowColumnSize);
				gridGreen[x][y].setPosition(width / 2 - gridWidth / 2 + x
						* rowColumnSize, height / 2 - gridHeight / 2 + y
						* rowColumnSize);
				gridGreen[x][y].setColor(Color.GREEN);

				gridGray[x][y] = new Sprite(texture);
				gridGray[x][y].setSize(rowColumnSize, rowColumnSize);
				gridGray[x][y].setPosition(width / 2 - gridWidth / 2 + x
						* rowColumnSize, height / 2 - gridHeight / 2 + y
						* rowColumnSize);
				gridGray[x][y].setColor(Color.GRAY);
			}
		}

		// Generate a BitmapFont based on a freetype Ubuntu font.
		FreeTypeFontGenerator generator = new FreeTypeFontGenerator(
				Gdx.files.internal("Ubuntu-R.ttf"));
		FreeTypeFontParameter parameter = new FreeTypeFontParameter();
		parameter.size = 26;
		font = generator.generateFont(parameter);
		generator.dispose();

		// Create a fps logger
		fpslogger = new FPSLogger();

		// Generate random training cues
		for (int i = 0; i < 30; i++) {
			trainingCues.add(i);
		}
		Collections.shuffle(trainingCues);
		trainingCues = trainingCues.subList(0, nrTrainingSequences);

		// Generate Text

		startText = new Text("Visual Speller");
		trainingText = new Text("Training Phase");
		feedbackText = new Text("Feedback Phase");
		endText = new Text("End of Experiment");
		tryConnectText = new Text("Trying to connect to buffer...");
		retryingText = new Text("Failed to connect, retrying ...");
		headerText = new Text("Connected to buffer, waiting for header...");
		lostText = new Text("Lost buffer connection.");

		Gdx.input.setInputProcessor(new InputAdapter() {
			@Override
			public boolean keyUp(int keycode) {
				if (keycode == Keys.ESCAPE) {
					Gdx.app.exit();
					return true;
				}
				if (keycode == Keys.N
						|| keycode == Keys.SPACE
						&& (state == States.FEEDBACK_TEXT
								|| state == States.TRAINING_TEXT
								|| state == States.START || state == States.END)) {
					nextState();
					return true;
				}
				return false;
			}

			@Override
			public boolean touchUp(int x, int y, int pointer, int button) {
				int width = Gdx.graphics.getWidth();
				int height = Gdx.graphics.getHeight();

				if (x < width / 10 && y < height / 10) {
					Gdx.app.exit();
					return true;
				}

				if (x > width * 0.9 && y > height * 0.9
						|| state == States.FEEDBACK_TEXT
						|| state == States.TRAINING_TEXT
						|| state == States.START || state == States.END) {
					nextState();
					return true;
				}

				return true;
			}
		});
	}

	@Override
	public void dispose() {
		batch.dispose();
		font.dispose();
	}

	/**
	 * Draws the provided grid to the spritebatch
	 *
	 * @param batch
	 * @param grid
	 */
	private void drawGrid(Sprite[][] grid) {
		Gdx.gl.glClearColor(0, 0, 0, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		batch.begin();

		batch.disableBlending();
		for (int x = 0; x < 6; x++) {
			for (int y = 0; y < 5; y++) {
				grid[x][y].draw(batch);
			}
		}
		batch.end();
	}

	/**
	 * Draws the provided grid to the spritebatch, except for index column or
	 * grid, which will be drawn from gridAlt.
	 *
	 * @param batch
	 * @param grid
	 * @param column
	 * @param index
	 * @param gridAlt
	 */
	private void drawGrid(Sprite[][] grid, boolean column, int index,
			Sprite[][] gridAlt) {
		Gdx.gl.glClearColor(0, 0, 0, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		batch.begin();

		batch.disableBlending();
		for (int x = 0; x < 6; x++) {
			if (column) {
				if (x == index) {
					for (Sprite s : gridAlt[x]) {
						s.draw(batch);
					}
				} else {
					for (Sprite s : grid[x]) {
						s.draw(batch);
					}
				}
			} else {
				for (int y = 0; y < 5; y++) {
					if (y == index) {
						gridAlt[x][y].draw(batch);
					} else {
						grid[x][y].draw(batch);
					}
				}
			}
		}
		batch.end();
	}

	/**
	 * Draws the provided grid to the spritebatch, except for x,y, that one will
	 * be drawn from gridAlt.
	 *
	 * @param batch
	 * @param grid
	 * @param x
	 * @param y
	 * @param gridAlt
	 */
	private void drawGrid(Sprite[][] grid, int x, int y, Sprite[][] gridAlt) {
		Gdx.gl.glClearColor(0, 0, 0, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		batch.begin();

		batch.disableBlending();

		for (int X = 0; X < 6; X++) {
			for (int Y = 0; Y < 5; Y++) {
				if (X == x && Y == y) {
					gridAlt[X][Y].draw(batch);
				} else {
					grid[X][Y].draw(batch);
				}
			}
		}

		batch.end();
	}

	private void nextState() {
		// change of state seems as good a time as any to update the current
		// nSample
		if (ftc.isConnected()) {
			try {
				nSamples = ftc.poll().nSamples;
				lastUpdate = TimeUtils.millis();
			} catch (IOException e) {
				changeState(States.LOST_CONNECTION);
			}
		}

		switch (state) {
		case START:
			changeState(States.GET_ADRESS);
			break;
		case GET_ADRESS:
			changeState(States.TRYING_TO_CONNECT);
			break;
		case TRYING_TO_CONNECT:
			changeState(States.TRAINING_TEXT);
			break;
		case RETRYING_TO_CONNECT:
			changeState(States.TRAINING_TEXT);
			break;
		case WAITING_FOR_HEADER:
			changeState(States.TRAINING_TEXT);
			break;
		case TRAINING_TEXT:
			changeState(States.TRAINING_PAUSE);
			sendEventNOW("stimulus.training", "start");
			break;
		case TRAINING_CUE:
			changeState(States.TRAINING_GRID);
			break;
		case TRAINING_GRID:
			changeState(States.FEEDBACK_TEXT);
			sendEventNOW("stimulus.training", "end");
			break;
		case FEEDBACK_TEXT:
			changeState(States.FEEDBACK_PAUSE);
			sendEventNOW("stimulus.feedback", "start");
			break;
		case FEEDBACK_GRID:
			changeState(States.FEEDBACK_FEEDBACK);
			break;
		case FEEDBACK_FEEDBACK:
			changeState(States.END);
			sendEventNOW("stimulus.feedback", "end");
			break;
		case END:
			break;
		case FEEDBACK_PAUSE:
			changeState(States.FEEDBACK_GRID);
			break;
		case TRAINING_PAUSE:
			changeState(States.TRAINING_CUE);
			break;
		default:
			break;

		}
	}

	@Override
	public void render() {
		fpslogger.log();
		switch (state) {
		case START:
			renderStartExperiment();
			break;
		case TRYING_TO_CONNECT:
			bufferTry();
			break;
		case RETRYING_TO_CONNECT:
			bufferRetry();
			break;
		case WAITING_FOR_HEADER:
			bufferHeader();
			break;
		case TRAINING_TEXT:
			renderTrainingText();
			break;
		case TRAINING_PAUSE:
			renderFeedbackTrainingPause();
			break;
		case TRAINING_CUE:
			renderTrainingCue();
			break;
		case TRAINING_GRID:
			renderTrainingGrid();
			break;
		case FEEDBACK_TEXT:
			renderFeedbackText();
			break;
		case FEEDBACK_PAUSE:
			renderFeedbackTrainingPause();
			break;
		case FEEDBACK_GRID:
			renderFeedbackGrid();
			break;
		case FEEDBACK_FEEDBACK:
			renderFeedbackFeedback();
			break;
		case END:
			renderEndText();
			break;
		case LOST_CONNECTION:
			renderLostConnection();
			break;
		case GET_ADRESS:

			renderGetAdress();
			break;
		default:
			break;
		}
	}

	private void renderEndText() {
		endText.draw();
	}

	private void renderFeedbackFeedback() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
		}

		// TODO Get feedback at some point;
		int x = 0;
		int y = 0;

		drawGrid(gridGray, x, y, gridRed);

		if (TimeUtils.millis() - lastStateTime > TIME_FEEDBACK) {
			if (--nrFeedbackSequences == 0) {
				nextState();
			} else {
				changeState(States.FEEDBACK_PAUSE);
			}
			sendEventNOW("feedback.sequence", "end");
		}
	}

	private void renderFeedbackGrid() {
		// Setup current state
		if (startOfState) {
			for (int i = 0; i < FLASHES_PER_STIMULUS; i++) {
				Collections.shuffle(FLASHINDICES);
				currentFlashes.addAll(FLASHINDICES);
			}
			lastStateTime = TimeUtils.millis();
			startOfState = false;
			flashOn = false;
			sendEventNOW("training.sequence", "start");
		}

		// Determine if it's a flash or normal frame
		if (TimeUtils.millis() - lastStateTime >= TIME_FLASH) {
			flashOn = !flashOn;
			lastStateTime = TimeUtils.millis();

			if (flashOn) {
				currentFlash = currentFlashes.remove(0);

				if (currentFlashes.size() > 0) {

					if (ISCOLUMNFLASH[currentFlash]) {
						sendEventNOW("stimulus.columnFlash",
								NUMBERFLASH[currentFlash]);
					} else {
						sendEventNOW("stimulus.rowFlash",
								NUMBERFLASH[currentFlash]);
					}
				} else {
					if (--nrTrainingSequences > 0) {
						changeState(States.TRAINING_PAUSE);
					} else {
						nextState();
					}
					flashOn = false;
				}
			}
		}

		// Draw screen
		if (flashOn) {
			drawGrid(gridGray, ISCOLUMNFLASH[currentFlash],
					NUMBERFLASH[currentFlash], gridWhite);
		} else {
			drawGrid(gridGray);
		}
	}

	private void renderFeedbackText() {
		feedbackText.draw();
	}

	private void renderFeedbackTrainingPause() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
		}

		drawGrid(gridGray);

		if (TimeUtils.millis() - lastStateTime > TIME_PAUSE) {
			nextState();
		}
	}

	private void renderGetAdress() {
		if (startOfState) {
			startOfState = false;
			AdressListener listener = new AdressListener();
			Gdx.input.getTextInput(listener, "Enter buffer adress",
					"127.0.0.1:1972");
		}
	}

	private void renderLostConnection() {
		lostText.draw();
	}

	private void renderStartExperiment() {
		startText.draw();
	}

	private void renderTrainingCue() {
		if (startOfState) {
			lastStateTime = TimeUtils.millis();
			startOfState = false;
			sendEventNOW("training.sequence", "start");
			sendEventNOW("training.targetSymbol", trainingCues.get(0));
			yCue = trainingCues.get(0) / 6;
			xCue = trainingCues.get(0) - yCue * 6;
			trainingCues.remove(0);
		}

		drawGrid(gridGray, xCue, yCue, gridGreen);

		if (TimeUtils.millis() - lastStateTime > TIME_CUE) {
			nextState();
		}
	}

	private void renderTrainingGrid() {
		// Setup current state
		if (startOfState) {
			for (int i = 0; i < FLASHES_PER_STIMULUS; i++) {
				Collections.shuffle(FLASHINDICES);
				currentFlashes.addAll(FLASHINDICES);
			}
			lastStateTime = TimeUtils.millis();
			startOfState = false;
			flashOn = false;
		}

		// Determine if it's a flash or normal frame
		if (TimeUtils.millis() - lastStateTime >= TIME_FLASH) {
			flashOn = !flashOn;
			lastStateTime = TimeUtils.millis();

			if (flashOn) {
				currentFlash = currentFlashes.remove(0);

				if (currentFlashes.size() > 0) {

					if (ISCOLUMNFLASH[currentFlash]) {
						sendEventNOW("stimulus.columnFlash",
								NUMBERFLASH[currentFlash]);
						if (NUMBERFLASH[currentFlash] == xCue) {
							sendEventNOW("stimulus.tgtFlash", 1);
						} else {
							sendEventNOW("stimulus.tgtFlash", 0);
						}
					} else {
						sendEventNOW("stimulus.rowFlash",
								NUMBERFLASH[currentFlash]);
						if (NUMBERFLASH[currentFlash] == yCue) {
							sendEventNOW("stimulus.tgtFlash", 1);
						} else {
							sendEventNOW("stimulus.tgtFlash", 0);
						}
					}
				} else {
					if (--nrTrainingSequences > 0) {
						changeState(States.TRAINING_PAUSE);
					} else {
						nextState();
					}
					sendEventNOW("training.sequence", "end");
					flashOn = false;
				}
			}
		}

		// Draw screen
		if (flashOn) {
			drawGrid(gridGray, ISCOLUMNFLASH[currentFlash],
					NUMBERFLASH[currentFlash], gridWhite);
		} else {
			drawGrid(gridGray);
		}
	}

	private void renderTrainingText() {
		trainingText.draw();
	}

	private void sendEventNOW(BufferEvent event) {
		float estimate = nSamples + (TimeUtils.millis() - lastUpdate) / 1000.0f
				* fSample;
		event.sample = (int) estimate;
		event.offset = (int) ((estimate - (int) estimate) / fSample) * 1000;
		try {
			ftc.putEvent(event);
		} catch (IOException e) {
			changeState(States.LOST_CONNECTION);
		} catch (NullPointerException e){
			changeState(States.LOST_CONNECTION);
		}
	}

	private void sendEventNOW(String type, int value) {
		sendEventNOW(new BufferEvent(type, value, 0));
	}

	private void sendEventNOW(String type, String value) {
		sendEventNOW(new BufferEvent(type, value, 0));
	}
}
