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

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.tumblr.oddlydrawn.stupidworm.*;
import com.tumblr.oddlydrawn.stupidworm.screens.GameScreen;
import nl.ru.bcigames.GdxInputReplacer.ControlModeFacade;
import nl.ru.bcigames.GdxInputReplacer.InputReplacer;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

/**
 * Customized Game class that controls the rendering of all screens and the stimuli
 */
public class OverlayGame extends MyGdxGame {
    private Sprites sprites;
    private Renderer renderer;
    private OrthographicCamera cam;
    private int initPeriod = 50;
    private int initCounter = 0;
    private int frameCounter = 0;

    // True when waiting for new sprite pattern to start
    private boolean waitingForThread = false;

    public OverlayGame() {

    }

    @Override
    /**
     * Renders game and sprites
     */
    public void render () {
        // Abort if screen is null
        if (screen == null) return;

        // Render sprites if the current screen is the game screen
        if (screen instanceof GameScreen) {

            // Check if escape key is pressed
            if(Gdx.input.isKeyPressed(Input.Keys.ESCAPE) || Gdx.input.isKeyPressed(Input.Keys.BACK)) {
                // End Stimuli Thread
                StandardizedInterface.getInstance().StimuliSystem.stopStimulus();

                // Reset counters
                this.frameCounter = 0;
                this.initCounter = 0;
                
                // End game and return to main menu
                this.setScreen(new MainMenuScreen(this));
            }

            // If init period is over
            if(initCounter > initPeriod) {
                // If no pattern is being rendered
                if (!StandardizedInterface.getInstance().StimuliSystem.isRunning()) {
                    // If not already marked as waitingForThread
                    if (!waitingForThread) {
                        StandardizedInterface.getInstance().StimuliSystem.setIsOn(false);
                        waitingForThread = true;

                        // Else we are already waitingForThread and check the the counter
                    } else {
                        screen.render(Gdx.graphics.getDeltaTime());
                        // if the number of frames defined in the game step are reached
                        if (frameCounter >= StandardizedInterface.getGameStepLength()) {
                            StandardizedInterface.getInstance().StimuliSystem.setIsOn(true);
                            //start the stimulus thread
                            StandardizedInterface.getInstance().StimuliSystem.startStimulus();
                            waitingForThread = false;

                            // reset counter
                            frameCounter = 0;
                        }

                        // If in asynchronous mode, leave frameCounter to 0, such that
                        // stimThread isn't started, so no stimuli is displayed and the game
                        // doesn't freeze
                        if (StandardizedInterface.getInstance().StimuliSystem.isSynchronous()) {
                            frameCounter++;
                        }
                    }
                }

                // Update rendered sprite pattern
                renderer.update();
                cam.update();

                // else just render Game Screen and increase initCounter
            } else {
                screen.render(Gdx.graphics.getDeltaTime());
                initCounter++;
            }
        }
        // Else screen is not a game screen, we just render it
        else {
            screen.render(Gdx.graphics.getDeltaTime());
        }
    }

    @Override
    /**
     * creates OverlayGame and sets Screen
     */
    public void create () {
        // Give an int, n, to Sprites if you want an nxn matrix
        this.sprites = new Sprites();
        this.cam = new OrthographicCamera(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
        this.renderer = new Renderer(cam, sprites);

        InputReplacer ir = new InputReplacer(); // Create instance of input proxy
        ir.setProxiedInput(Gdx.input); // Give InputProxy current Gdx.input
        Gdx.input = ir; // Replace Gdx.input with input proxy

        // Connect server keys with the keys that would be normally pressed
        // Add all keys that are needed and give them a different server key:
        ControlModeFacade.commandsBuffer.addKeyCommand(1, Input.Keys.LEFT);
        ControlModeFacade.commandsBuffer.addKeyCommand(0, Input.Keys.UP);
        ControlModeFacade.commandsBuffer.addKeyCommand(2, Input.Keys.DOWN);
        ControlModeFacade.commandsBuffer.addKeyCommand(3, Input.Keys.RIGHT);

        // Set screen to ExampleUseCase Menu
        setScreen(new MainMenuScreen(this));
    }

    Sprites getSprites() {
        return sprites;
    }
}
