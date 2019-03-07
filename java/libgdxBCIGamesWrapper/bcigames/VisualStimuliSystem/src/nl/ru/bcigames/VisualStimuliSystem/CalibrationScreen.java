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
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.graphics.*;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.kotcrab.vis.ui.VisUI;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

public class CalibrationScreen implements Screen {
    private final Game game;
    private final OrthographicCamera cam;
    private Renderer renderer;
    private boolean waiting = false;
    private int frameCounter = 0;

    // Button
    private TextButton backButton;
    Stage stage;

    /**
     * Screen that only shows the chosen sprites and can be exited with an exit button
     * @param game
     */
    public CalibrationScreen( Game game) {
        this.game = game;
        this.cam = new OrthographicCamera(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        if(this.game instanceof OverlayGame) {
            this.renderer = new Renderer(cam, ((OverlayGame) this.game).getSprites());
        }
        else {
            this.renderer = new Renderer(cam, new Sprites());
        }

        this.stage = new Stage();

        // Load UI for buttons if not already loaded
        if(!VisUI.isLoaded())
            VisUI.load();

        // Create back button
        createBackButton();
    }

    /**
     * Adds exit button with listener in right bottom corner
     */
    private void createBackButton() {
        // Create Button
        backButton = new TextButton("EXIT", VisUI.getSkin());

        // Set position in bottom right corner
        backButton.setX(Gdx.graphics.getWidth()-60);
        backButton.setY(0);
        backButton.setWidth(60);
        backButton.setHeight(60);
        backButton.setVisible(true);

        // Add Listener that sets the screen to the start screen of the game when button is clicked
        backButton.addListener(new ClickListener(){
            @Override
            public void clicked(InputEvent event, float x, float y) {
                StandardizedInterface.getInstance().StimuliSystem.stopStimulus();
                frameCounter = 0;
                game.setScreen(new MainMenuScreen(game));
            }
        });

        // Add Button to stage
        stage.addActor(backButton);
    }

    @Override
    public void show() {
        // Enable Input
        Gdx.input.setInputProcessor(stage);
    }

    @Override
    public void render(float delta) {
        // Clear Screen
        Gdx.gl.glClearColor(0.2f, 0.2f, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        cam.update();

        // If stimulus thread is not running
        if(!StandardizedInterface.getInstance().StimuliSystem.isRunning()) {
            // If not already marked as waiting we start the timer
            if (!waiting) {
                StandardizedInterface.getInstance().StimuliSystem.setIsOn(false);
                waiting = true;

                // Else we are already waiting and check the the timer
            } else {

                // if passed time is bigger than diff
                if (frameCounter >= StandardizedInterface.getGameStepLength()) {
                    StandardizedInterface.getInstance().StimuliSystem.setIsOn(true);
                    //start the stimulus thread
                    StandardizedInterface.getInstance().StimuliSystem.startStimulus();
                    waiting = false;
                    frameCounter = 0;
                } else {
                    frameCounter++;
                }
            }
        }

        // Render sprite pattern
        renderer.update();

        // Render Button
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
}
