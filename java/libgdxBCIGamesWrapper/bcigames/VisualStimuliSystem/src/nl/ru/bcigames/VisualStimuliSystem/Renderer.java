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

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.glutils.ShapeRenderer;
import com.badlogic.gdx.math.Rectangle;
import nl.ru.bcigames.StandardizedInterface.StandardizedInterface;

/**
 * Renderer of Sprites
 */
public class Renderer {
    private ShapeRenderer shapeRenderer;
    private OrthographicCamera cam;
    private Rectangle rect;
    private Sprites sprites;

    /**
     * Constructor
     * @param cam
     * @param sprites
     */
    public Renderer(OrthographicCamera cam, Sprites sprites) {
        this.cam = cam;
        this.sprites = sprites;
        shapeRenderer = new ShapeRenderer();
        rect = new Rectangle();
    }

    /**
     * Updates visual stimuli
     */
    public void update() {
        cam.update();
        shapeRenderer.setProjectionMatrix(cam.combined);
        shapeRenderer.begin(ShapeRenderer.ShapeType.Filled);

        // Activate and Deactivate sprites according to stimuli pattern file
        try {
            for (int i = 0; i < sprites.getSprites().size(); i++) {
                if (StandardizedInterface.getInstance().StimuliSystem.getStimuliStates()[i])
                    sprites.getSprites().get(i).activate();
                else
                    sprites.getSprites().get(i).deactivate();
            }
        }
        catch (ArrayIndexOutOfBoundsException e) {
        }

        // Only render sprites when stimuli system is on
        if(StandardizedInterface.getInstance().StimuliSystem.isOn()) {
            renderSprites();
            StandardizedInterface.getInstance().StimuliSystem.sendStimUpdateToServer(StandardizedInterface.StimuliSystem.getStimuliStates());
        }

        // End shapeRenderer
        shapeRenderer.end();
    }

    /**
     * Renders Sprites
     */
    private void renderSprites() {
        for (int j = 0; j < sprites.getSprites().size(); j++) {

            // Only if sprite is activated
            if (sprites.getSprites().get(j).isActivated()) {
                // Set color to orange
                shapeRenderer.setColor(Color.ORANGE);
                // get size and position
                addSprite(j);
            } else {
                // Set color to black
                shapeRenderer.setColor(Color.BLACK);
                // get size and position
                addSprite(j);
            }
        }
    }

    /**
     * Render a single sprite with shapeRenderer
     * @param j number of sprite
     */
    public void addSprite(int j) {
        // get size and position
        rect.x = sprites.getSprites().get(j).x;
        rect.y = sprites.getSprites().get(j).y;
        rect.height = sprites.getSprites().get(j).getSPRITE_SIZE();
        rect.width = sprites.getSprites().get(j).getSPRITE_SIZE();

        // Up Sprite
        if (sprites.getSprites().get(j).getDirection() == Direction.UP) {
            shapeRenderer.triangle(rect.x, rect.y, rect.x + rect.width, rect.y, rect.x + rect.width / 2, rect.y + rect.height);
            // Down Sprite
        } else if (sprites.getSprites().get(j).getDirection() == Direction.DOWN) {
            shapeRenderer.triangle(rect.x, rect.y + rect.height, rect.x + rect.width, rect.y + rect.height, rect.x + rect.width / 2, rect.y);
            // Right Sprite
        } else if (sprites.getSprites().get(j).getDirection() == Direction.RIGHT) {
            shapeRenderer.triangle(rect.x, rect.y + rect.height, rect.x, rect.y, rect.x + rect.width, rect.y + rect.height / 2);
            // Left Sprite
        } else if (sprites.getSprites().get(j).getDirection() == Direction.LEFT) {
            shapeRenderer.triangle(rect.x + rect.width, rect.y + rect.height, rect.x + rect.width, rect.y, rect.x, rect.y + rect.height / 2);
            // Middle Sprite
        } else if (sprites.getSprites().get(j).getDirection() == Direction.MIDDLE) {
            shapeRenderer.circle(rect.x, rect.y, rect.height/2);
        }
    }
}
