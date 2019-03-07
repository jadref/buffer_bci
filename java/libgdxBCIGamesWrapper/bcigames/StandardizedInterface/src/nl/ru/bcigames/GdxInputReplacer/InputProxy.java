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

package nl.ru.bcigames.GdxInputReplacer;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputProcessor;

/**
 * Wraps a concrete instance of {@link Input} and proxies all its methods. If
 * the proxied instance is null, the return values of most methods will indicate
 * that features are not available (by returning false or negative values if
 * only positive is expected) or simply return that nothing has happened.
 *
 * @author Lukas Böhm
 * @author Jeremy Constantin Börker
 */
abstract class InputProxy implements Input {

    /**
     * The Input.
     */
    protected Input input;

    /**
     * Instantiates a new Input proxy.
     *
     * @param proxied the proxied
     */
    public InputProxy(Input proxied) {
        this.input = proxied;
    }

    /**
     * Instantiates a new Input proxy.
     */
    InputProxy() {

    }

    /**
     * Sets proxied input.
     *
     * @param proxied the proxied
     */
    public void setProxiedInput(Input proxied) {
        this.input = proxied;
    }

    private Input getProxiedInput() {
        return input;
    }

    @Override
    public void setInputProcessor(InputProcessor processor) {
        if (input != null) {
            input.setInputProcessor(processor);
        }
    }

    @Override
    public InputProcessor getInputProcessor() {
        if (input != null) {
            return input.getInputProcessor();
        } else {
            return null;
        }
    }

    public float getGyroscopeX() {
        if (input != null) {
            return input.getGyroscopeX();
        } else {
            return 0;
        }
    }

    public float getGyroscopeY() {
        if (input != null) {
            return input.getGyroscopeY();
        } else {
            return 0;
        }
    }

    public float getGyroscopeZ() {
        if (input != null) {
            return input.getGyroscopeZ();
        } else {
            return 0;
        }
    }

    @Override
    public float getPressure() {
        if (input != null) {
            return input.getPressure();
        } else {
            return 0;
        }
    }

    @Override
    public float getPressure(int pointer) {
        if (input != null) {
            return input.getPressure(pointer);
        } else {
            return 0;
        }
    }

    @Override
    public boolean isKeyJustPressed(int key) {
        if (input != null) {
            return input.isKeyJustPressed(key);
        } else {
            return false;
        }
    }

    @Override
    public void getTextInput(TextInputListener listener, String title, String text, String hint) { }

    @Override
    public boolean isCatchBackKey() {
        if (input != null) {
            return input.isCatchBackKey();
        } else {
            return false;
        }
    }

    @Override
    public boolean isCatchMenuKey() {
        if (input != null) {
            return input.isCatchMenuKey();
        } else {
            return false;
        }
    }

    @Override
    public float getAccelerometerX() {
        if (input != null) {
            return input.getAccelerometerX();
        } else {
            return 0;
        }
    }

    @Override
    public float getAccelerometerY() {
        if (input != null) {
            return input.getAccelerometerY();
        } else {
            return 0;
        }
    }

    @Override
    public float getAccelerometerZ() {
        if (input != null) {
            return input.getAccelerometerZ();
        } else {
            return 0;
        }
    }

    @Override
    public int getX() {
        if (input != null) {
            return input.getX();
        } else {
            return -1;
        }
    }

    @Override
    public int getX(int pointer) {
        if (input != null) {
            return input.getX(pointer);
        } else {
            return -1;
        }
    }

    @Override
    public int getDeltaX() {
        if (input != null) {
            return input.getDeltaX();
        } else {
            return -1;
        }
    }

    @Override
    public int getDeltaX(int pointer) {
        if (input != null) {
            return input.getDeltaX(pointer);
        } else {
            return -1;
        }
    }

    @Override
    public int getY() {
        if (input != null) {
            return input.getY();
        } else {
            return -1;
        }
    }

    @Override
    public int getY(int pointer) {
        if (input != null) {
            return input.getY(pointer);
        } else {
            return -1;
        }
    }

    @Override
    public int getDeltaY() {
        if (input != null) {
            return input.getDeltaY();
        } else {
            return -1;
        }
    }

    @Override
    public int getDeltaY(int pointer) {
        if (input != null) {
            return input.getDeltaY(pointer);
        } else {
            return -1;
        }
    }

    @Override
    public boolean isTouched() {
        if (input != null) {
            return input.isTouched();
        } else {
            return false;
        }
    }

    @Override
    public boolean justTouched() {
        if (input != null) {
            return input.justTouched();
        } else {
            return false;
        }
    }

    @Override
    public boolean isTouched(int pointer) {
        if (input != null) {
            return input.isTouched(pointer);
        } else {
            return false;
        }
    }

    @Override
    public boolean isButtonPressed(int button) {
        if (input != null) {
            return input.isButtonPressed(button);
        } else {
            return false;
        }
    }

    @Override
    public boolean isKeyPressed(int key) {
        if (input != null) {
            return input.isKeyPressed(key);
        } else {
            return false;
        }
    }

    @Override
    public void setOnscreenKeyboardVisible(boolean visible) {
        if (input != null) {
            input.setOnscreenKeyboardVisible(visible);
        }
    }

    @Override
    public void vibrate(int milliseconds) {
        if (input != null) {
            input.vibrate(milliseconds);
        }
    }

    @Override
    public void vibrate(long[] pattern, int repeat) {
        if (input != null) {
            input.vibrate(pattern, repeat);
        }
    }

    @Override
    public void cancelVibrate() {
        if (input != null) {
            input.cancelVibrate();
        }
    }

    @Override
    public float getAzimuth() {
        if (input != null) {
            return input.getAzimuth();
        } else {
            return 0;
        }
    }

    @Override
    public float getPitch() {
        if (input != null) {
            return input.getPitch();
        } else {
            return 0;
        }
    }

    @Override
    public float getRoll() {
        return input.getRoll();
    }

    @Override
    public void getRotationMatrix(float[] matrix) {
        if (input != null) {
            input.getRotationMatrix(matrix);
        }
    }

    @Override
    public long getCurrentEventTime() {
        if (input != null) {
            return input.getCurrentEventTime();
        } else {
            return System.currentTimeMillis() * 1000;
        }
    }

    @Override
    public void setCatchBackKey(boolean catchBack) {
        if (input != null) {
            input.setCatchBackKey(catchBack);
        }
    }

    @Override
    public void setCatchMenuKey(boolean catchMenu) {
        if (input != null) {
            input.setCatchMenuKey(catchMenu);
        }
    }

    @Override
    public boolean isPeripheralAvailable(Peripheral peripheral) {
        if (input != null) {
            return input.isPeripheralAvailable(peripheral);
        } else {
            return false;
        }
    }

    @Override
    public int getRotation() {
        if (input != null) {
            return input.getRotation();
        } else {
            return 0;
        }
    }

    @Override
    public Orientation getNativeOrientation() {
        if (input != null) {
            return input.getNativeOrientation();
        } else {
            return Orientation.Landscape;
        }
    }


    @Override
    public void setCursorCatched(boolean catched) {
        if (input != null) {
            input.setCursorCatched(catched);
        }
    }

    @Override
    public boolean isCursorCatched() {
        if (input != null) {
            return input.isCursorCatched();
        } else {
            return false;
        }
    }

    @Override
    public void setCursorPosition(int x, int y) {
        if (input != null) {
            input.setCursorPosition(x, y);
        }
    }

    /**
     * Goes down the hierarchy of InputProxies, starting at Gdx.input and
     * removes the given InputProxy, if it exists. Returns if the given
     * {@link InputProxy} was found and removed.
     *
     * @param proxy the proxy to be found and removed
     * @return true if the specified proxy was removed, false otherwise
     */
    public static boolean removeProxyFromGdx(InputProxy proxy) {
        if (Gdx.input == null) {
            return false;
        }
        if (Gdx.input.equals(proxy)) {
            synchronized (Gdx.input) {
                Gdx.input = proxy.getProxiedInput();
            }
            return true;
        }
        Input current = Gdx.input;
        InputProxy asProxy;
        while (current != null && current instanceof InputProxy) {
            asProxy = (InputProxy) current;
            if (asProxy.getProxiedInput() == proxy) {
                asProxy.setProxiedInput(proxy.getProxiedInput());
                return true;
            }
            current = asProxy.getProxiedInput();
        }
        return false;
    }
}