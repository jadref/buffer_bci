/*
 * Copyright (c) 2019 Jeremy Constantin Börker, Anna Gansen, Marit Hagens, Codruta Lugoj, Wouter Loeve, Samarpan Rai and Alex Tichter
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package nl.ru.bcigames.VisualStimuliSystem;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.kotcrab.vis.ui.VisUI;
import com.badlogic.gdx.Screen;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

public class MainMenuScreen implements Screen {
    private final Game game;
    private final OrthographicCamera camera;
    private final Viewport viewport;

    // UI elements
    Stage stage;
    private TextButton startGameButton;
    private TextButton startCalibrationButton;
    private TextButton startSettingsScreen;
    private Table table;

    /**
     * Screen that only shows the chosen sprites and can be exited with an exit button
     * @param game
     */
    public MainMenuScreen(Game game) {
        this.game = game;
        this.camera = new OrthographicCamera();
        this.viewport = new ExtendViewport(Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), this.camera);
        this.stage = new Stage(viewport);

        // Load UI for buttons if not already loaded
        if(!VisUI.isLoaded())
            VisUI.load();

        // Create buttons with listeners
        createButtons();
    }

    @Override
    public void show() {
        // Enable Input
        Gdx.input.setInputProcessor(stage);

        // Set the layout of the screen to table with 4 rows
        createTableLayout();
    }

    @Override
    public void render(float delta) {
        // Clear Screen
        Gdx.gl.glClearColor(0.2f, 0.2f, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        // Update camera
        camera.update();

        // Render Buttons
        stage.act();
        stage.draw();
    }

    @Override
    public void resize(int width, int height) {
        stage.getViewport().update(width, height, true);
    }

    @Override
    public void pause() {

    }

    @Override
    public void resume() {

    }

    @Override
    public void hide() {

    }

    @Override
    public void dispose() {

    }

    /**
     * Adds 'StartGame', 'Calibration' and 'Settings' buttons with listeners in the center
     */
    private void createButtons() {
        // Create Buttons
        this.startGameButton = new TextButton("Start Game", VisUI.getSkin());
        this.startCalibrationButton = new TextButton("Calibration", VisUI.getSkin());
        this.startSettingsScreen = new TextButton("Settings", VisUI.getSkin());

        // Add Listener that sets the screen to the start screen of the game when button is clicked
        startGameButton.addListener(new ClickListener(){
            @Override
            public void clicked(InputEvent event, float x, float y) {
                StandardizedInterface.getInstance().StimuliSystem.readStimulusFile(
                        StandardizedInterface.getInstance().StimuliSystem.getGameStimuliFile());
                game.setScreen(new com.tumblr.oddlydrawn.stupidworm.screens.MainMenuScreen(game));
            }
        });

        // Add Listener that sets the screen to the calibration screen when button is clicked
        startCalibrationButton.addListener(new ClickListener(){
            @Override
            public void clicked(InputEvent event, float x, float y) {
                StandardizedInterface.getInstance().StimuliSystem.readStimulusFile(
                        StandardizedInterface.getInstance().StimuliSystem.getCalibrationStimuliFile());
                game.setScreen(new CalibrationScreen(game));
            }
        });

        // Add Listener that sets the screen to the SettingsScreen when button is clicked
        startSettingsScreen.addListener(new ClickListener(){
            @Override
            public void clicked(InputEvent event, float x, float y) {
                game.setScreen(new SettingsScreen(game));
            }
        });

        // Add Buttons to stage
        stage.addActor(startGameButton);
        stage.addActor(startCalibrationButton);
        stage.addActor(startSettingsScreen);
    }

    /**
     * Sets the layout of the screen to table layout with 3 rows; one for each button
     */
    private void createTableLayout() {
        stage.setViewport(viewport);

        // create table
        this.table = new Table();
        table.setFillParent(true);
        stage.addActor(table);

        // Table layout
        table.center();
        table.columnDefaults(1);

        // Row 1: Start Game button
        table.row();
        table.add(startGameButton).width(stage.getWidth()/3).padTop(stage.getHeight()/10).height(stage.getHeight()/10);

        // Row 2: Settings button
        table.row();
        table.add(startSettingsScreen).width(stage.getWidth()/3).padTop(stage.getHeight()/10).height(stage.getHeight()/10);

        // Row 3: Calibration button
        table.row();
        table.add(startCalibrationButton).width(stage.getWidth()/3).padTop(stage.getHeight()/10).height(stage.getHeight()/10);
    }
}

