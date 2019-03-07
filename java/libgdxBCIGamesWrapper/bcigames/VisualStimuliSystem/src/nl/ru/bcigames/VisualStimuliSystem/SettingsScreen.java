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
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.graphics.Camera;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.scenes.scene2d.*;
import com.badlogic.gdx.scenes.scene2d.ui.*;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.TextField;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.viewport.ExtendViewport;
import com.badlogic.gdx.utils.viewport.Viewport;
import com.kotcrab.vis.ui.VisUI;
import com.kotcrab.vis.ui.widget.file.FileChooser;
import com.kotcrab.vis.ui.widget.file.SingleFileChooserListener;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;


public class SettingsScreen implements Screen {
    private Game game;
    private Stage stage;
    private Camera camera;
    private Viewport viewport;
    private Table table;
    private TextButton statusButton;
    private TextButton backButton;
    private Label ipLabel;
    private Label portLabel;
    private Label statusLabel;
    private Label gamePlayModeSelectorLabel;
    private Label timeoutLabel;
    private Label stimuliLabel;
    private Label gameStepLabel;
    private Label calibrationLabel;
    private final Label keyCommandDecayLabel;
    private SelectBox<String> gamePlayModeSelector;
    private CheckBox stimuliOff;
    private CheckBox stimuliOn;
    private CheckBox synchronous;
    private CheckBox asynchronous;
    private FileChooser fileChooser;
    private FileChooser calibrationChooser;
    private TextField ipField;
    private TextField portField;
    private TextField fileField;
    private TextField calibrationField;
    private TextField timeoutField;
    private TextField gameStepField;
    private final TextField keyCommandDecayField;


    public SettingsScreen(Game game) {

        this.game = game;
        this.camera = new OrthographicCamera();
        this.viewport = new ExtendViewport(Gdx.graphics.getWidth(), Gdx.graphics.getHeight(), this.camera);
        this.stage = new Stage(viewport);

        // Buttons
        this.statusButton = new TextButton("Connect", VisUI.getSkin());
        this.backButton = new TextButton("Back", VisUI.getSkin());

        // IP
        this.ipLabel = new Label("IP Address:", VisUI.getSkin());
        this.ipField = new TextField("", VisUI.getSkin());

        // Port
        this.portLabel = new Label("Port:", VisUI.getSkin());
        this.portField = new TextField("", VisUI.getSkin());

        // Server connection status label
        this.statusLabel = new Label("No Information to see yet.", VisUI.getSkin());

        // BCI Modes

        // Stimuli ON and OFF
        this.stimuliOff = new CheckBox("Stimuli OFF", VisUI.getSkin());
        this.stimuliOn = new CheckBox("Stimuli ON", VisUI.getSkin());

        // Synchronous and asynchronous
        this.synchronous = new CheckBox("Synchronous", VisUI.getSkin());
        this.asynchronous = new CheckBox("Asynchronous", VisUI.getSkin());


        // Controls: direct/sticky keys
        this.gamePlayModeSelectorLabel = new Label("Game play mode", VisUI.getSkin());
        this.gamePlayModeSelector= new SelectBox<>(VisUI.getSkin());
        this.gamePlayModeSelector.setItems("Direct","Sticky");

        // Decay -> Not implemented
        this.keyCommandDecayField = new TextField("", VisUI.getSkin());
        keyCommandDecayField .setMessageText("default : 200 ms ");
        keyCommandDecayField .needsLayout();
        this.keyCommandDecayLabel = new Label("Key command decay (/millisecond):", VisUI.getSkin());

        // File choosers

        // Game stimuli chooser
        this.stimuliLabel = new Label("Stimuli file:", VisUI.getSkin());
        this.fileChooser = new FileChooser("Choose Stimuli File", FileChooser.Mode.OPEN);
        fileChooser.setSize(stage.getWidth(), stage.getHeight());
        this.fileField = new TextField("", VisUI.getSkin() );
        fileField.setMessageText("no file chosen");

        // Calibration stimuli chooser
        this.calibrationLabel = new Label("Calibration file:", VisUI.getSkin() );
        this.calibrationChooser = new FileChooser("Choose Calibration File", FileChooser.Mode.OPEN);
        calibrationChooser.setSize(stage.getWidth(), stage.getHeight());
        this.calibrationField = new TextField("", VisUI.getSkin() );
        calibrationField.setMessageText("no file chosen");

        // Timeout
        this.timeoutField = new TextField("", VisUI.getSkin());
        timeoutField.setMessageText("100");
        timeoutField.needsLayout();
        this.timeoutLabel = new Label("Timeout after (ms):", VisUI.getSkin());

        // Game step
        this.gameStepLabel = new Label("Game step time:", VisUI.getSkin());
        this.gameStepField = new TextField("", VisUI.getSkin());
        gameStepField.setMessageText(""+StandardizedInterface.getInstance().getGameStepLength());
    }

    /**
     * Create table layout and default settings
     */
    private void componentsProperties() {

        // create table layout
        this.table = new Table();
        table.setFillParent(true);
        stage.addActor(table);
        stage.setViewport(viewport);

        ipField.setMessageText(StandardizedInterface.BufferClient.getHostname());
        portField.setMessageText(Integer.toString(StandardizedInterface.BufferClient.getPort()));
        stimuliOn.setChecked(true);
        stimuliOn.setDisabled(true);
        synchronous.setChecked(true);
        synchronous.setDisabled(true);

        //table layout
        table.defaults().pad(10);
        table.left();
        table.columnDefaults(2);

        table.row().padTop(stage.getHeight()/20);
        table.add(ipLabel).align(Align.left).width(ipLabel.getWidth()+2);
        table.add(ipField).align(Align.left);
        table.add(synchronous);
        table.add(stimuliOff).expandX();

        table.row();
        table.add(portLabel).align(Align.left).width(ipLabel.getWidth()+2);
        table.add(portField).align(Align.left);
        table.add(asynchronous);
        table.add(stimuliOn);


        table.row();
        table.add(gamePlayModeSelectorLabel).align(Align.left);
        table.add(gamePlayModeSelector);

        table.row();
        table.add(keyCommandDecayLabel).align(Align.left);
        table.add(keyCommandDecayField).align(Align.left);


        table.row();
        table.add(timeoutLabel).align(Align.left);
        table.add(timeoutField).align(Align.left);

        table.row();
        table.add(stimuliLabel).align(Align.left);
        table.add(fileField).align(Align.left);

        table.row();
        table.add(calibrationLabel).align(Align.left);
        table.add(calibrationField).align(Align.left);

        table.row();
        table.add(gameStepLabel).align(Align.left);
        table.add(gameStepField);

        table.row();
        table.add(statusButton).width(stage.getWidth()/4).colspan(4).padTop(stage.getHeight()/5);

        table.row();
        table.add(statusLabel).expandX().colspan(3).align(Align.left);

        table.row();
        table.add();
        table.add(backButton).align(Align.right).padBottom(stage.getHeight()/20).padRight(stage.getWidth()/50);
    }

    /**
     * Listeners for some components
     */
    private void listeners() {
        statusButton.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if(StandardizedInterface.getInstance().BufferClient.isConnected()) {
                    StandardizedInterface.getInstance().BufferClient.disconnect();
                } else {
                    if (!ipField.getText().equals(""))
                        StandardizedInterface.getInstance().BufferClient.setHostname(ipField.getText());
                    if (!portField.getText().equals(""))
                        StandardizedInterface.getInstance().BufferClient.setPort(Integer.parseInt(portField.getText()));
                    
                    StandardizedInterface.getInstance().BufferClient.connect();
                }
                 }
        });

        timeoutField.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (!timeoutField.getText().equals(""))
                    StandardizedInterface.getInstance().BufferClient.setTimeout(Integer.parseInt(timeoutField.getText()));
            }
        });

        gameStepField.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (!gameStepField.getText().equals(""))
                    StandardizedInterface.setGameStepLength(Integer.parseInt(gameStepField.getText()));
            }
        });

        keyCommandDecayField.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (!keyCommandDecayField.getText().equals(""))
                    StandardizedInterface.setKeyCommandDecayRate(Integer.parseInt(keyCommandDecayField.getText()));
            }
        });

        stimuliOff.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (stimuliOff.isChecked()) {
                    StandardizedInterface.getInstance().StimuliSystem.setStimuliOn(false);
                    stimuliOn.setChecked(false);
                    if (stimuliOff.isPressed()) {
                        stimuliOff.setDisabled(true);
                        stimuliOn.setDisabled(false);
                    }
                }
            }
        });

        stimuliOn.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (stimuliOn.isChecked()) {
                    StandardizedInterface.getInstance().StimuliSystem.setStimuliOn(true);
                    stimuliOff.setChecked(false);
                    if (stimuliOn.isPressed()) {
                        stimuliOn.setDisabled(true);
                        stimuliOff.setDisabled(false);
                    }
                }
            }
        });

        gamePlayModeSelector.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                String selected = gamePlayModeSelector.getSelected().toLowerCase();
                if(selected.equals("sticky")) {
                    StandardizedInterface.setCurrentGamePlayMode(StandardizedInterface.GamePlayMode.STICKY);

                }
                else {
                    StandardizedInterface.setCurrentGamePlayMode(StandardizedInterface.GamePlayMode.DIRECT);

                }
            }
        });

        synchronous.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (synchronous.isChecked()) {
                    StandardizedInterface.getInstance().StimuliSystem.setSynchronous(true);
                    asynchronous.setChecked(false);
                    if (synchronous.isPressed()) {
                        synchronous.setDisabled(true);
                        asynchronous.setDisabled(false);
                    }
                }
            }
        });

        asynchronous.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {
                if (asynchronous.isChecked()) {
                    StandardizedInterface.getInstance().StimuliSystem.setSynchronous(false);
                    synchronous.setChecked(false);
                    if (asynchronous.isPressed()) {
                        asynchronous.setDisabled(true);
                        synchronous.setDisabled(false);
                    }
                }
            }
        });

        backButton.addListener(new ChangeListener() {
            public void changed (ChangeEvent event, Actor actor) {

                game.setScreen(new MainMenuScreen(game));

            }
        });

        fileChooser.setListener(new SingleFileChooserListener() {

            @Override
            protected void selected(FileHandle file) {
                fileField.setText(file.file().getName());
                StandardizedInterface.getInstance().StimuliSystem.setGameStimuliFile(file.toString());
            }
        });

        fileField.addListener(new ClickListener() {
            @Override
            public void clicked(InputEvent event, float x, float y) {
                table.center().addActor(fileChooser);
            }
        });

        calibrationChooser.setListener(new SingleFileChooserListener() {

            @Override
            protected void selected(FileHandle file) {
                calibrationField.setText(file.file().getName());
                StandardizedInterface.getInstance().StimuliSystem.setCalibrationStimuliFile(file.toString());
            }
        });

        calibrationField.addListener(new ClickListener() {
            @Override
            public void clicked(InputEvent event, float x, float y) {
                table.center().addActor(calibrationChooser);
            }
        });

        stage.getRoot().addCaptureListener(new InputListener() {
            public boolean touchDown (InputEvent event, float x, float y, int pointer, int button) {
                if (!(event.getTarget() instanceof TextField))
                    stage.setKeyboardFocus(null);
                return false;
            }});
    }

    @Override
    public void show() {
        Gdx.input.setInputProcessor(stage);
        componentsProperties();
        listeners();
    }

    @Override
    public void render(float delta) {
        // Clear Screen
        Gdx.gl.glClearColor(0.2f, 0.2f, 0.2f, 1);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        stage.act(delta);

        if (StandardizedInterface.getInstance().BufferClient.isConnected()) {
            statusButton.setText("Disconnect");
            statusLabel.setColor(0,255,0,1);
        }
        else {
            statusButton.setText("Connect");
            statusLabel.setColor(255,0,0,1);
        }
        statusLabel.setText("Status: " + StandardizedInterface.getInstance().BufferClient.getConnectionState());

        // Draw stage
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
        stage.dispose();
    }

}
