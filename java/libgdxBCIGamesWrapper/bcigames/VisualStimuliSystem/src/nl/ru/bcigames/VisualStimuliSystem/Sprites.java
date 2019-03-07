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

import java.util.ArrayList;

/**
 * Class to create sprites as needed
 */
public class Sprites {
    private ArrayList<Sprite> sprites;
    private int BOUND_N = 20;

    /**
     * Constructor where five sprites are added
     */
    public Sprites() {
        this.sprites = new ArrayList<>();
        // Init sprites

        // Right
        RightSprite rightSprite = new RightSprite();
        sprites.add(rightSprite);

        // Left
        LeftSprite leftSprite = new LeftSprite();
        sprites.add(leftSprite);

        // Up
        UpSprite upSprite = new UpSprite();
        sprites.add(upSprite);

        // Down
        DownSprite downSprite = new DownSprite();
        sprites.add(downSprite);

        // Middle
        CircleSprite circleSprite = new CircleSprite();
        sprites.add(circleSprite);
    }

    /**
     * Constructor where n times n matrix of sprites are added
     * if and int is given to the constructor
     */
    public Sprites(int n) {
        // Check if n exceeds the upper boundary
        if (n > BOUND_N) {
            n = BOUND_N;
        }
        sprites = new ArrayList<>();

        int screenWidth = Gdx.graphics.getWidth();
        int screenHeight = Gdx.graphics.getHeight();
        int startX = - screenWidth/2 + screenWidth/(2*n);
        int startY = - screenHeight/2 + screenHeight/(2*n);
        for(int x = 0; x < n; x++) {
            for(int y = 0; y < n; y++) {
                CircleSprite sprite = new CircleSprite(startX + screenWidth / n * x, startY + screenHeight / n * y);
                sprites.add(sprite);
            }
        }
    }

    /**
     * Returns list of sprites
     * @return sprites
     */
    public ArrayList<Sprite> getSprites () {
        return sprites;
    }

    @Override
    public String toString() {
        String s = "";
        for(Sprite sp : sprites)
            s += sp.toString() + "\n";
        return s;
    }
}
