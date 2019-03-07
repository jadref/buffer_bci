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

/**
 * Sprite with coordinates, direction and activation
 */
public class Sprite {
    public float x;
    public float y;
    public float offset_X;
    public float offset_Y;
    private boolean activated = true;
    private Direction direction;
    protected final float SPRITE_SIZE = Gdx.graphics.getWidth()/50;

    /**
     * Constructor
     */
    public Sprite () {
    }

    /**
     * Returns direction of sprite
     * @return Direction of this specific sprite
     */
    public Direction getDirection() {
        return direction;
    }

    /**
     * Sets direction of sprite
     * @param dir
     */
    public void setDirection(Direction dir) {
        direction = dir;
    }

    /**
     * Checks if the sprite is activated
     * @return activation
     */
    public boolean isActivated () {
        return activated;
    }

    /**
     * Activates sprites
     */
    public void activate () {
        activated = true;
    }

    /**
     * Deactivates sprite
     */
    public void deactivate () {
        activated = false;
    }

    public void set (float x, float y) {
        this.x = x + this.offset_X;
        this.y = y + this.offset_Y;
    }

    /**
     * Moves the sprite location from the center with a given amount of pixels
     * @param x: Negative indicates displacing towards the right and positive towards the left (from the center)
     * @param y: Negative indicates displacing towards the bottom and positive towards the top (from the center).
     */
    public void setOffset (float x, float y){
        this.offset_X = x;
        this.offset_Y = y;
    }

    /**
     * Returns size of one Sprite
     * @return size of one Sprite
     */
    public float getSPRITE_SIZE() {
        return SPRITE_SIZE;
    }

    public String toString() {
        return direction.toString() + " " + activated;
    }
}
